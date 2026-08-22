#!/usr/bin/env bash
# OmaVERT bar widget — local conversion backend.
#
# Runs one of the engines VERT itself uses under the hood:
#   ImageMagick            -> images
#   FFmpeg                 -> audio and video
#   Pandoc                 -> documents
#
# Every conversion runs inside a bubblewrap sandbox:
#   - no network namespace,
#   - an allow-list filesystem: read-only /usr plus a handful of config paths,
#     minimal /dev, PID-namespaced /proc, private /tmp — /home, /root, /run,
#     /var, /opt and the rest of /etc (including /etc/machine-id) are absent,
#   - the input file re-exposed READ-ONLY,
#   - a private empty work directory as the ONLY writable location.
# The engine writes its result into the work directory; this script then moves
# that single file into OUTPUT_DIR itself, so the engine can neither reach the
# network nor read unrelated host or user files.
#
# Converts INPUT to a collision-free path in OUTPUT_DIR and prints that
# path on stdout. Engine errors go to stderr and the script exits non-zero.
#
# Usage: convert.sh <magick|ffmpeg|pandoc> <input> <extension> [output-dir]

set -u

engine="${1:-}"
input="${2:-}"
ext="${3:-}"
outdir="${4:-$HOME/Downloads}"
workdir=""

usage() {
  echo "usage: convert.sh <magick|ffmpeg|pandoc> <input> <extension> [output-dir]" >&2
}

if [[ -z "$engine" || -z "$input" || -z "$ext" ]]; then
  usage
  exit 2
fi

# The extension becomes part of the result filename; keep it a short token so a
# stray caller cannot turn it into a path traversal or option-looking argument.
[[ "$ext" =~ ^[A-Za-z0-9]{1,8}$ ]] || {
  echo "convert.sh: invalid extension '$ext'" >&2
  exit 2
}

[[ -f "$input" ]] || { echo "convert.sh: input not found: $input" >&2; exit 2; }

case "$engine" in
  magick|ffmpeg|pandoc) : ;;
  *) echo "convert.sh: unknown engine '$engine'" >&2; usage; exit 2 ;;
esac

command -v "$engine" >/dev/null 2>&1 || {
  echo "convert.sh: '$engine' is not installed — required for this conversion." >&2
  exit 3
}

# Read-only system paths the engines need. Bind each only if present so a
# system without one optional component (e.g. ImageMagick config) still works.
ro_binds=()
for p in /etc/ld.so.cache /etc/fonts /etc/ImageMagick-7 /etc/localtime; do
  [ -e "$p" ] && ro_binds+=(--ro-bind "$p" "$p")
done

sandbox_cmd=(
  bwrap --unshare-all --die-with-parent
  --ro-bind /usr /usr
  --symlink usr/bin /bin --symlink usr/bin /sbin
  --symlink usr/lib /lib --symlink usr/lib /lib64
  "${ro_binds[@]}"
  --dev /dev --proc /proc
  --tmpfs /tmp
)

# Fail closed if the sandbox cannot be provisioned.
if ! "${sandbox_cmd[@]}" true 2>/dev/null; then
  echo "convert.sh: sandbox (bubblewrap) unavailable; refusing to convert" >&2
  exit 4
fi

mkdir -p "$outdir" || { echo "convert.sh: cannot create $outdir" >&2; exit 2; }

base="$(basename "$input")"
base="${base%.*}"
[[ -n "$base" ]] || base="converted"

output="$outdir/$base.$ext"
i=1
while [[ -e "$output" ]]; do
  output="$outdir/$base ($i).$ext"
  i=$((i + 1))
done

# Private, empty directory as the engine's ONLY writable location. The result
# is moved out by this script afterwards, so the engine never sees — or can
# read — any other file that lives in the real output directory.
workdir="$(mktemp -d)"
trap '[ -n "${workdir:-}" ] && rm -rf -- "$workdir"' EXIT

# Re-expose the input (read-only) inside the sandbox and add the work
# directory as its only writable location.
sandbox_cmd+=(--ro-bind "$input" "$input" --bind "$workdir" "$workdir")

err="$(mktemp)"

# Engine stdout is discarded so nothing an input file coaxes an engine into
# printing can masquerade as the result path this script reports.
case "$engine" in
  magick) "${sandbox_cmd[@]}" -- magick "$input" "$workdir/result.$ext" >/dev/null 2>"$err" ;;
  ffmpeg) "${sandbox_cmd[@]}" -- ffmpeg -nostdin -y -hide_banner -loglevel error -i "$input" "$workdir/result.$ext" >/dev/null 2>"$err" ;;
  pandoc) "${sandbox_cmd[@]}" -- pandoc "$input" --output "$workdir/result.$ext" >/dev/null 2>"$err" ;;
esac
rc=$?

if [[ $rc -ne 0 ]]; then
  sed 's/^/  /' "$err" >&2
  rm -f "$err"
  echo "convert.sh: $engine failed (exit $rc)" >&2
  exit $rc
fi

rm -f "$err"

# Place the result. Verify it landed rather than trusting mv's status alone
# (-n exits 0 even when it skips an existing destination).
if ! mv -n "$workdir/result.$ext" "$output" || [[ ! -f "$output" ]]; then
  echo "convert.sh: failed to place result at $output" >&2
  exit 1
fi

echo "$output"
exit 0