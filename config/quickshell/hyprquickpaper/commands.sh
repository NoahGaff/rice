#!/usr/bin/env bash
set -euo pipefail
exec >>/tmp/hyprquickpaper.log 2>&1

echo "-----"
date
echo "arg1=$1"
echo "TARGET_MONITOR=$TARGET_MONITOR"

wall="$1"
monitor="${TARGET_MONITOR:-}"
state_file="$HOME/.local/state/hypr/walls.tsv"

if [ -z "$wall" ]; then
  echo "no wallpaper arg"
  exit 1
fi

if [ ! -e "$wall" ]; then
  echo "wallpaper does not exist: $wall"
  exit 1
fi

if [ -z "$monitor" ]; then
  echo "no TARGET_MONITOR provided"
  exit 1
fi

mkdir -p "$(dirname "$state_file")"
touch "$state_file"

save_state() {
  local mon="$1"
  local type="$2"
  local path="$3"
  local tmp
  tmp="$(mktemp)"

  awk -F '\t' -v mon="$mon" '$1 != mon { print }' "$state_file" >"$tmp" || true
  printf '%s\t%s\t%s\n' "$mon" "$type" "$path" >>"$tmp"
  mv "$tmp" "$state_file"
}

case "${wall,,}" in
*.mp4 | *.webm | *.mkv | *.mov | *.avi)
  echo "setting LIVE wallpaper on $monitor: $wall"
  pkill -f "mpvpaper.*$monitor" || true
  mpvpaper -o "no-audio --loop-file=inf --hwdec=auto-safe --profile=fast --interpolation=no --vd-lavc-threads=2" "$monitor" "$wall" &
  disown || true
  save_state "$monitor" "live" "$wall"
  ;;

*.jpg | *.jpeg | *.png | *.webp | *.bmp | *.gif)
  echo "setting STATIC wallpaper on $monitor: $wall"
  pkill -f "mpvpaper.*$monitor" || true

  if ! pgrep -x awww-daemon >/dev/null; then
    awww-daemon --no-cache >/dev/null 2>&1 &
    disown || true
    sleep 1
  fi

  awww img "$wall" --outputs "$monitor" --transition-type none
  save_state "$monitor" "static" "$wall"
  ;;

*)
  echo "unsupported file type: $wall"
  exit 1
  ;;
esac
