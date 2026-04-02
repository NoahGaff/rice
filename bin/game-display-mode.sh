#!/usr/bin/env bash
set -u

LOG="/tmp/game-display-mode.log"
exec >>"$LOG" 2>&1

echo
echo "==== $(date) ===="
echo "args: $*"

HYPRCTL="/usr/bin/hyprctl"
PKILL="/usr/bin/pkill"
SLEEP="/usr/bin/sleep"
WAYBAR="/usr/bin/waybar"

restart_waybar_game() {
  "$PKILL" -x waybar || true
  "$SLEEP" 0.5
  "$WAYBAR" -c "$HOME/.config/waybar/config-game.jsonc" -s "$HOME/.config/waybar/style.css" >/dev/null 2>&1 &
}

restart_waybar_normal() {
  "$PKILL" -x waybar || true
  "$SLEEP" 0.5
  "$WAYBAR" >/dev/null 2>&1 &
}

restore() {
  echo "restoring monitors"
  "$HYPRCTL" --batch "
    keyword monitor DP-1,2560x1440@143.912,-1440x-560,1,transform,1 ;
    keyword monitor DP-2,3840x2160@119.999,2560x0,1.5
  " || true
  "$SLEEP" 0.5
  restart_waybar_normal || true
}

game_mode() {
  echo "switching to game mode"
  "$HYPRCTL" --batch "
    keyword monitor DP-1,1280x720@59.94,-720x80,1,transform,1 ;
    keyword monitor DP-2,1280x720@59.94,2560x360,1
  " || true
  "$SLEEP" 0.5
  restart_waybar_game || true
}

on_exit() {
  status=$?
  echo "wrapper exiting with status $status"
  restore
  exit "$status"
}

trap on_exit EXIT INT TERM

game_mode

if [ "$#" -eq 0 ]; then
  echo "no command passed from Steam"
  exit 1
fi

echo "launching: $*"
"$@"
status=$?
echo "game exited with status $status"
exit "$status"
