#!/usr/bin/env bash
set -euo pipefail

# Change this to your Proxmox URL (include https:// and :8006 if needed)
URL="https://pve.note-snapper.ts.net:8006"

# Launch in a NEW Firefox window
chromium --new-window "$URL" >/dev/null 2>&1 &
