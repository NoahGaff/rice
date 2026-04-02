#!/usr/bin/env bash

DEVICE=$(pactl list cards short | grep bluez | awk '{print $2}')

if pactl list cards | grep -A20 "$DEVICE" | grep -q headset_head_unit; then
  pactl set-card-profile "$DEVICE" off
  sleep 1
  pactl set-card-profile "$DEVICE" a2dp-sink
fi
