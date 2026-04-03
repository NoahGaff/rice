#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$CONFIG_DIR/config.json"

wallpaper_path="$(jq -r '.wallpaper_path' "$CONFIG_FILE")"
cache_path="$(jq -r '.cache_path' "$CONFIG_FILE")"
cache_batch_size="$(jq -r '.cache_batch_size // 20' "$CONFIG_FILE")"

mkdir -p "$cache_path"

lockfile="$cache_path/.thumbcache.lock"
exec 9>"$lockfile"
flock -n 9 || exit 0

is_image() {
  case "${1,,}" in
  *.jpg | *.jpeg | *.png | *.webp | *.bmp | *.gif) return 0 ;;
  *) return 1 ;;
  esac
}

is_video() {
  case "${1,,}" in
  *.mp4 | *.webm | *.mkv | *.mov | *.avi) return 0 ;;
  *) return 1 ;;
  esac
}

make_thumb() {
  local input="$1"
  local base out tmp

  base="$(basename "$input")"
  out="$cache_path/${base}.jpg"
  tmp="${out}.tmp.$$"

  # Skip if cached thumbnail already exists and is newer than source
  if [[ -f "$out" && "$out" -nt "$input" ]]; then
    return 0
  fi

  if is_image "$input"; then
    echo "Generating image thumbnail for $base"
    magick "$input" -thumbnail x540 -strip -quality 90 "$tmp"
  elif is_video "$input"; then
    echo "Generating video thumbnail for $base"
    ffmpegthumbnailer -i "$input" -o "$tmp" -s 540 -q 8
  else
    echo "Skipping unsupported file: $base"
    return 0
  fi

  mv -f "$tmp" "$out"
}

export -f is_image
export -f is_video
export -f make_thumb
export cache_path

mapfile -d '' files < <(
  find "$wallpaper_path" -maxdepth 1 -type f \( \
    -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o \
    -iname '*.webp' -o -iname '*.bmp' -o -iname '*.gif' -o \
    -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o \
    -iname '*.mov' -o -iname '*.avi' \
    \) -print0 | sort -z
)

if ((${#files[@]} == 0)); then
  echo "No supported wallpaper files found in $wallpaper_path"
  exit 0
fi

# Remove stale cached thumbs for files that no longer exist
declare -A wanted=()
for file in "${files[@]}"; do
  wanted["$(basename "$file").jpg"]=1
done

while IFS= read -r -d '' cached; do
  base="$(basename "$cached")"
  [[ -n "${wanted[$base]:-}" ]] || rm -f "$cached"
done < <(find "$cache_path" -maxdepth 1 -type f -name '*.jpg' -print0)

if ((cache_batch_size <= 0)); then
  for file in "${files[@]}"; do
    make_thumb "$file" &
  done
  wait
else
  running=0
  for file in "${files[@]}"; do
    make_thumb "$file" &
    ((running += 1))
    if ((running >= cache_batch_size)); then
      wait
      running=0
    fi
  done
  wait
fi

echo "Thumbnail generation complete."
