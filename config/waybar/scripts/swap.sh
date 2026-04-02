#!/usr/bin/env bash

read -r _ total used _ < <(free -b | awk '/^Swap:/ {print $1, $2, $3, $4}')

if [ -z "$total" ] || [ "$total" -eq 0 ] || [ "$used" -eq 0 ]; then
  printf '{"text":"","tooltip":"","class":"hidden"}\n'
  exit 0
fi

used_gib=$(awk "BEGIN {printf \"%.1f\", $used/1024/1024/1024}")
total_gib=$(awk "BEGIN {printf \"%.1f\", $total/1024/1024/1024}")
pct=$(awk "BEGIN {printf \"%.0f\", ($used/$total)*100}")

printf '{"text":"󰾆 %s%%","tooltip":"Swap: %s / %s GiB","class":"swap"}\n' "$pct" "$used_gib" "$total_gib"
