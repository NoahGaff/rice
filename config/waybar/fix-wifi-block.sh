#!/usr/bin/env bash
set -euo pipefail

cfg="$HOME/.config/waybar/config"
bak="$cfg.bak.$(date +%Y%m%d-%H%M%S)"
cp -a "$cfg" "$bak"

tmp="$(mktemp)"
cat > "$tmp" <<'AWK'
BEGIN { inwifi=0 }

# Start of wifi block
/"network#wifi"[[:space:]]*:[[:space:]]*{/ {
  inwifi=1
  print "  \"network#wifi\": {"
  print "    \"interface\": \"wlan0\","
  print "    \"interval\": 2,"
  print "    \"format\": \"\","
  print "    \"format-disconnected\": \"󰤭\","
  print "    \"format-ethernet\": \"\","
  print "    \"format-wifi\": \"󰤨 {signalStrength}%\","
  print "    \"tooltip\": true,"
  print "    \"tooltip-format-wifi\": \"{ifname}\\\\n{essid}\\\\n{signalStrength}%\\\\n{frequency} GHz\","
  print "    \"on-click\": \"~/.config/waybar/scripts/wifi-click.sh\","
  print "    \"min-length\": 2,"
  print "    \"max-length\": 18"
  print "  },"
  next
}

# Skip original wifi block until its closing brace-comma
inwifi==1 {
  if ($0 ~ /^[[:space:]]*},[[:space:]]*$/) { inwifi=0 }
  next
}

{ print }
AWK

awk -f "$tmp" "$bak" > "$cfg"
rm -f "$tmp"

echo "✅ Rewrote network#wifi block. Backup saved to: $bak"
