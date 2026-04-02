#!/usr/bin/env bash
set -euo pipefail

theme="$HOME/.config/rofi/themes/wifi-menu.rasi"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "WiFi" "$1"
}

if [[ "$(nmcli -t -f WIFI g)" != "enabled" ]]; then
  nmcli radio wifi on
fi

nmcli dev wifi rescan >/dev/null 2>&1 || true

current="$(nmcli -t -f ACTIVE,SSID dev wifi | awk -F: '$1=="yes" && $2!="" {print $2; exit}')"

mapfile -t networks < <(
  nmcli -t -f SSID,SECURITY,SIGNAL dev wifi list |
    awk -F: '
    $1 != "" {
      ssid=$1
      sec=$2
      sig=$3+0
      key=ssid "|" sec
      if (!(key in best) || sig > bestsig[key]) {
        best[key]=ssid "  [" sec "]  " sig "%"
        bestsig[key]=sig
      }
    }
    END {
      for (k in best) print best[k]
    }
  ' | sort
)

choices=()
[[ -n "$current" ]] && choices+=("Disconnect from: $current")
choices+=("Open Network Settings")
choices+=("${networks[@]}")

selected="$(
  printf '%s\n' "${choices[@]}" |
    rofi -no-config -dmenu -i -p "Networks" -theme "$theme"
)" || exit 0

[[ -z "$selected" ]] && exit 0

if [[ "$selected" == "Open Network Settings" ]]; then
  nohup nm-connection-editor >/dev/null 2>&1 &
  exit 0
fi

if [[ "$selected" == "Disconnect from: $current" ]]; then
  nmcli con down id "$current" && notify "Disconnected from $current"
  exit 0
fi

ssid="$(printf '%s' "$selected" | sed 's/  \[.*$//')"

if nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then
  nmcli con up id "$ssid" && notify "Connected to $ssid"
  exit 0
fi

password="$(
  rofi -no-config -dmenu -password -p "Password for $ssid" -theme "$theme"
)" || exit 0

[[ -z "$password" ]] && exit 0

nmcli dev wifi connect "$ssid" password "$password" && notify "Connected to $ssid"
