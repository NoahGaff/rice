#!/usr/bin/env bash
set -euo pipefail

# Terminal + menu
TERM_CMD=(kitty)                        # swap to (foot) or (alacritty) if you want
MENU_CMD=(wofi --dmenu --prompt "SSH → VM")

# Default SSH user (override per entry below if needed)
DEFAULT_USER="noah"

# Format: "Label|user|host|term"
# term is optional. Use it when a remote doesn't know xterm-kitty (ex: Ubuntu w/out kitty-terminfo).
VMS=(
  "pve|root|pve.note-snapper.ts.net|"                                  # 100.123.196.34
  "minecraft|${DEFAULT_USER}|minecraft.note-snapper.ts.net|"            # 100.120.19.67
  "nas|${DEFAULT_USER}|nas.note-snapper.ts.net|xterm-256color"          # 100.90.188.24
  "pihole|${DEFAULT_USER}|pihole.note-snapper.ts.net|"                  # 100.69.117.81
  "portfolio-site|${DEFAULT_USER}|portfolio-site.note-snapper.ts.net|"  # 100.100.152.114
  "obsidian-notes|${DEFAULT_USER}|obsidian-notes.note-snapper.ts.net|"  # 100.74.86.38
  "vaultwarden|${DEFAULT_USER}|vaultwarden.note-snapper.ts.net|"        # 100.74.194.30
)

choice="$(
  for e in "${VMS[@]}"; do
    label="${e%%|*}"
    echo "$label"
  done | "${MENU_CMD[@]}"
)"

[[ -z "${choice:-}" ]] && exit 0

selected=""
for e in "${VMS[@]}"; do
  label="${e%%|*}"
  if [[ "$label" == "$choice" ]]; then
    selected="$e"
    break
  fi
done

[[ -z "$selected" ]] && exit 1

# Parse fields
IFS='|' read -r label user host term_override <<<"$selected"

# Build ssh command (optionally override TERM only for that host)
if [[ -n "${term_override:-}" ]]; then
  "${TERM_CMD[@]}" -e env TERM="$term_override" ssh "${user}@${host}"
else
  "${TERM_CMD[@]}" -e ssh "${user}@${host}"
fi
