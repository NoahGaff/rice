#!/usr/bin/env bash

for i in {1..10}; do
  MON_COUNT=$(hyprctl monitors | grep -c "Monitor")
  if [ "$MON_COUNT" -ge 3 ]; then
    exit 0
  fi
  sleep 0.5
done

exit 0
