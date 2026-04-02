#!/usr/bin/env bash
set -euo pipefail

# ---------- editor ----------
EDITOR_BIN="${EDITOR:-}"
if [[ -z "$EDITOR_BIN" ]]; then
  if command -v nvim >/dev/null 2>&1; then
    EDITOR_BIN="nvim"
  elif command -v vim >/dev/null 2>&1; then
    EDITOR_BIN="vim"
  elif command -v micro >/dev/null 2>&1; then
    EDITOR_BIN="micro"
  else
    EDITOR_BIN="nano"
  fi
fi

# If you want GUI editor under Wayland, you could set:
# EDITOR_BIN="kitty -e nvim"

# ---------- paths ----------
HYPR="$HOME/.config/hypr/hyprland.conf"
WAYBAR_CFG="$HOME/.config/waybar/config.jsonc"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"
ROFI_CFG="$HOME/.config/rofi/config.rasi"
ROFI_THEME="$HOME/.config/rofi/themes/sakura.rasi"
WALL_SET="$HOME/.local/bin/set-wallpapers.sh"
WALL_PICK="$HOME/.local/bin/wallpaper-picker.sh"
BASHRC="$HOME/.bashrc"
BASH_PROFILE="$HOME/.bash_profile"
ZSHRC="$HOME/.zshrc"
ZPROFILE="$HOME/.zprofile"

# Added quick-access entries
CONF_MENU="$HOME/.local/bin/conf-menu.sh"
SSH_MENU="$HOME/.local/bin/ssh-menu.sh"
LAUNCHER="$HOME/.local/bin/launcher.sh"
OPEN_PROXMOX="$HOME/.local/bin/open-proxmox.sh"
SMARTFETCH="$HOME/.local/bin/smartfetch"
KB_DIAG="$HOME/.local/bin/kb-diag"
KB_DIAG_QUICK="$HOME/.local/bin/kb-diag-quick"
KB_DIAG_TILES="$HOME/.local/bin/kb-diag-tiles"
KB_DIAG_WINDOWS="$HOME/.local/bin/kb-diag-windows"

# ---------- helpers ----------
pick() {
  rofi -dmenu -i -p "Config menu"
}

edit_file() {
  local f="$1"
  [[ -e "$f" ]] || {
    rofi -e "Missing: $f"
    return 0
  }

  if [[ "$EDITOR_BIN" == "code"* || "$EDITOR_BIN" == "gedit"* ]]; then
    nohup "$EDITOR_BIN" "$f" >/dev/null 2>&1 &
  else
    if command -v kitty >/dev/null 2>&1 && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
      nohup kitty -e "$EDITOR_BIN" "$f" >/dev/null 2>&1 &
    else
      nohup "$EDITOR_BIN" "$f" >/dev/null 2>&1 &
    fi
  fi
  exit 0
}

action_menu() {
  printf "%s\n" \
    "Reload Hyprland (hyprctl reload)" \
    "Restart Waybar" \
    "Reapply wallpapers" \
    "Restart swww" \
    "Kill mpvpaper" \
    "Back"
}

main_menu() {
  printf "%s\n" \
    "Edit: Hyprland config" \
    "Edit: Waybar config" \
    "Edit: Waybar style.css" \
    "Edit: Rofi config.rasi" \
    "Edit: Rofi theme (sakura.rasi)" \
    "Edit: Wallpaper setter (set-wallpapers.sh)" \
    "Edit: Wallpaper picker (wallpaper-picker.sh)" \
    "Edit: Config menu (conf-menu.sh)" \
    "Edit: SSH menu (ssh-menu.sh)" \
    "Edit: Launcher (launcher.sh)" \
    "Edit: Open Proxmox (open-proxmox.sh)" \
    "Edit: smartfetch" \
    "Edit: kb-diag" \
    "Edit: kb-diag-quick" \
    "Edit: kb-diag-tiles" \
    "Edit: kb-diag-windows" \
    "Edit: .zshrc" \
    "Edit: .zprofile" \
    "Edit: .bashrc" \
    "Edit: .bash_profile" \
    "Actions…" \
    "Quit"
}

# ---------- loop ----------
while true; do
  choice="$(main_menu | pick)" || exit 0
  case "$choice" in
  "Edit: Hyprland config") edit_file "$HYPR" ;;
  "Edit: Waybar config") edit_file "$WAYBAR_CFG" ;;
  "Edit: Waybar style.css") edit_file "$WAYBAR_STYLE" ;;
  "Edit: Rofi config.rasi") edit_file "$ROFI_CFG" ;;
  "Edit: Rofi theme (sakura.rasi)") edit_file "$ROFI_THEME" ;;
  "Edit: Wallpaper setter (set-wallpapers.sh)") edit_file "$WALL_SET" ;;
  "Edit: Wallpaper picker (wallpaper-picker.sh)") edit_file "$WALL_PICK" ;;

  "Edit: Config menu (conf-menu.sh)") edit_file "$CONF_MENU" ;;
  "Edit: SSH menu (ssh-menu.sh)") edit_file "$SSH_MENU" ;;
  "Edit: Launcher (launcher.sh)") edit_file "$LAUNCHER" ;;
  "Edit: Open Proxmox (open-proxmox.sh)") edit_file "$OPEN_PROXMOX" ;;
  "Edit: smartfetch") edit_file "$SMARTFETCH" ;;
  "Edit: kb-diag") edit_file "$KB_DIAG" ;;
  "Edit: kb-diag-quick") edit_file "$KB_DIAG_QUICK" ;;
  "Edit: kb-diag-tiles") edit_file "$KB_DIAG_TILES" ;;
  "Edit: kb-diag-windows") edit_file "$KB_DIAG_WINDOWS" ;;

  "Edit: .bashrc") edit_file "$BASHRC" ;;
  "Edit: .bash_profile") edit_file "$BASH_PROFILE" ;;
  "Edit: .zshrc") edit_file "$ZSHRC" ;;
  "Edit: .zprofile") edit_file "$ZPROFILE" ;;
  "Actions…")
    act="$(action_menu | rofi -dmenu -i -p "Actions")" || continue
    case "$act" in
    "Reload Hyprland (hyprctl reload)") hyprctl reload ;;
    "Restart Waybar")
      pkill -x waybar 2>/dev/null || true
      waybar >/dev/null 2>&1 &
      disown
      ;;
    "Reapply wallpapers") "$WALL_SET" ;;
    "Restart swww") systemctl --user restart swww.service || true ;;
    "Kill mpvpaper") pkill -x mpvpaper 2>/dev/null || true ;;
    *) : ;;
    esac
    ;;
  "Quit" | "") exit 0 ;;
  esac
done
