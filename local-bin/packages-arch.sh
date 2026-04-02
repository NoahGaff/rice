#!/usr/bin/env bash
set -euo pipefail

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required"
  exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script is for Arch-based systems"
  exit 1
fi

PKGS=(
  hyprland
  waybar
  fish
  kitty
  blueman
  network-manager-applet
  pavucontrol
  swaync
  wl-clipboard
  cliphist
  grim
  slurp
  jq
  playerctl
  brightnessctl
  foot
  fastfetch
  ttf-jetbrains-mono-nerd
  noto-fonts
  noto-fonts-emoji
)

echo "==> Installing official repo packages"
sudo pacman -Syu --needed "${PKGS[@]}"

if command -v yay >/dev/null 2>&1; then
  AUR_PKGS=(
    quickshell
    hyprpicker
  )

  echo "==> Installing AUR packages"
  yay -S --needed "${AUR_PKGS[@]}"
else
  echo "==> yay not found"
  echo "Install yay first if you need AUR packages like quickshell"
fi
