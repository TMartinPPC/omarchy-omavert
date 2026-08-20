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

err="$(mktemp)"
case "$engine" in
  magick) magick "$input" "$output" 2>"$err" ;;
  ffmpeg) ffmpeg -nostdin -y -hide_banner -loglevel error -i "$input" "$output" 2>"$err" ;;
  pandoc) pandoc "$input" --output "$output" 2>"$err" ;;
esac
rc=$?

if [[ $rc -ne 0 ]]; then
  sed 's/^/  /' "$err" >&2
  rm -f "$err"
  echo "convert.sh: $engine failed (exit $rc)" >&2
  exit $rc
fi

rm -f "$err"
echo "$output"
exit 0