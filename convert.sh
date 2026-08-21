#!/usr/bin/env bash
# OmaVERT bar widget — local conversion backend.
#
# Runs one of the engines VERT itself uses under the hood:
#   ImageMagick            -> images
#   FFmpeg                 -> audio and video
#   Pandoc                 -> documents
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

usage() {
  echo "usage: convert.sh <magick|ffmpeg|pandoc> <input> <extension> [output-dir]" >&2
}

if [[ -z "$engine" || -z "$input" || -z "$ext" ]]; then
  usage
  exit 2
fi

[[ -f "$input" ]] || { echo "convert.sh: input not found: $input" >&2; exit 2; }

case "$engine" in
  magick|ffmpeg|pandoc) : ;;
  *) echo "convert.sh: unknown engine '$engine'" >&2; usage; exit 2 ;;
esac

command -v "$engine" >/dev/null 2>&1 || {
  echo "convert.sh: '$engine' is not installed — required for this conversion." >&2
  exit 3
}

# Sandbox: run each engine in a network-isolated, filesystem-restricted
# namespace (bubblewrap). The engine gets an allow-list, not the host root:
# read-only /usr (plus the usr-merge root symlinks), the dynamic-loader cache,
# and a handful of config paths that actually exist; /dev and /proc; a private
# /tmp. Everything else — the rest of /etc, /var, /opt, /home, /etc/machine-id,
# the user's data — is absent, along with the input file (read-only) and a
# private empty work directory (read-write). A crafted document can neither
# fetch remote resources nor read unrelated host files. Fail closed if the
# sandbox cannot be provisioned.
ro_binds=()
for p in /etc/ld.so.cache /etc/fonts /etc/ImageMagick-7 /etc/localtime; do
  [ -e "$p" ] && ro_binds+=(--ro-bind "$p" "$p")
done

if command -v bwrap >/dev/null 2>&1 \
    && bwrap --unshare-all --die-with-parent \
       --ro-bind /usr /usr --symlink usr/bin /bin --symlink usr/bin /sbin \
       --symlink usr/lib /lib --symlink usr/lib /lib64 \
       "${ro_binds[@]}" \
       --dev /dev --proc /proc --tmpfs /tmp \
       -- true 2>/dev/null; then
  :
else
  echo "convert.sh: sandbox (bubblewrap) unavailable; refusing to convert" >&2
  exit 4
fi

# Run a command inside the allow-list sandbox; the input file is re-exposed
# read-only and the private work directory read-write.
run_sandboxed() {
  bwrap --unshare-all --die-with-parent \
    --ro-bind /usr /usr --symlink usr/bin /bin --symlink usr/bin /sbin \
    --symlink usr/lib /lib --symlink usr/lib /lib64 \
    "${ro_binds[@]}" \
    --dev /dev --proc /proc --tmpfs /tmp \
    --ro-bind "$input" "$input" --bind "$workdir" "$workdir" \
    -- "$@"
}

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

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

err="$(mktemp)"
case "$engine" in
  magick) run_sandboxed magick "$input" "$workdir/result.$ext" 2>"$err" ;;
  ffmpeg) run_sandboxed ffmpeg -nostdin -y -hide_banner -loglevel error -i "$input" "$workdir/result.$ext" 2>"$err" ;;
  pandoc) run_sandboxed pandoc "$input" --output "$workdir/result.$ext" 2>"$err" ;;
esac
rc=$?

if [[ $rc -ne 0 ]]; then
  sed 's/^/  /' "$err" >&2
  rm -f "$err"
  echo "convert.sh: $engine failed (exit $rc)" >&2
  exit $rc
fi

rm -f "$err"
mv -n "$workdir/result.$ext" "$output" || { echo "convert.sh: failed to place result" >&2; exit 1; }
echo "$output"
exit 0