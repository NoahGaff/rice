#!/usr/bin/env bash

DEVICE_MAC="B8:7B:D4:1E:84:23"

bluetoothctl disconnect "$DEVICE_MAC" >/dev/null 2>&1
sleep 0.5
bluetoothctl connect "$DEVICE_MAC" >/dev/null 2>&1
