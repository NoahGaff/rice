#!/usr/bin/env bash
set -euo pipefail

# ───────────── monitors ─────────────
LEFT="DP-2"
MIDDLE="DP-3"
VERTICAL="DP-1"

# ===== PICKER VARS START =====
MODE_LEFT="video"
MODE_MIDDLE="video"
MODE_VERTICAL="video"

STATIC_LEFT="/home/noah/Pictures/wallpapers/horizontal/japan-background-digital-art.jpg"
STATIC_MIDDLE="/home/noah/Pictures/wallpapers/horizontal/japan-background-digital-art.jpg"
STATIC_VERTICAL="/home/noah/Pictures/wallpapers/vertical/portrait.jpg"

VIDEO_LEFT="/home/noah/Videos/wallpapers/horizontal/2b-midnight-bloom.3840x2160.mp4"
VIDEO_MIDDLE="/home/noah/Videos/wallpapers/horizontal/1758965895.mp4"
VIDEO_VERTICAL="/home/noah/Videos/wallpapers/vertical/247733.mp4"
# ===== PICKER VARS END =====

# ───────────── env ─────────────
unset SWWW_SOCK
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"

# ───────────── helpers ─────────────
ensure_swww() {
  # Start swww daemon if needed (quietly). If the unit doesn't exist, fall back to launching.
  systemctl --user start swww.service >/dev/null 2>&1 || true
  command -v swww >/dev/null 2>&1 || return 0
  # If daemon isn't up yet, try to start it directly.
  swww query >/dev/null 2>&1 || (swww-daemon >/dev/null 2>&1 &)
}

apply_static() {
  local out="$1" img="$2"
  [[ -n "${img:-}" && -f "$img" ]] || return 0
  ensure_swww
  swww img -o "$out" "$img" --resize crop >/dev/null 2>&1 || true
}

apply_video() {
  local out="$1" vid="$2"
  [[ -n "${vid:-}" && -f "$vid" ]] || return 0

  local mpv_opts="--loop --keep-open=yes --no-audio --hwdec=auto --no-osc --no-osd-bar --really-quiet"

  if [[ "$out" == "$VERTICAL" ]]; then
    mpv_opts="$mpv_opts --keepaspect=yes --panscan=1.0"
  fi

  mpvpaper -o "$mpv_opts" "$out" "$vid" >/dev/null 2>&1 &
}

# ───────────── reset live wallpapers once ─────────────
pkill -x mpvpaper 2>/dev/null || true

# ───────────── apply per output ─────────────
# NOTE: We intentionally do NOT set a static wallpaper on outputs using video,
# because swww can cover mpvpaper's layer.

# LEFT
if [[ "${MODE_LEFT}" == "video" ]]; then
  apply_video "$LEFT" "$VIDEO_LEFT"
else
  apply_static "$LEFT" "$STATIC_LEFT"
fi

# MIDDLE
if [[ "${MODE_MIDDLE}" == "video" ]]; then
  apply_video "$MIDDLE" "$VIDEO_MIDDLE"
else
  apply_static "$MIDDLE" "$STATIC_MIDDLE"
fi

# VERTICAL
if [[ "${MODE_VERTICAL}" == "video" ]]; then
  apply_video "$VERTICAL" "$VIDEO_VERTICAL"
else
  apply_static "$VERTICAL" "$STATIC_VERTICAL"
fi

# Keep script from exiting before background mpvpaper spawns
disown 2>/dev/null || true
