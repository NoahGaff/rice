#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Creating config directories"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"

echo "==> Copying configs"
cp -r "$REPO_DIR/config/hypr" "$HOME/.config/"
cp -r "$REPO_DIR/config/waybar" "$HOME/.config/"
cp -r "$REPO_DIR/config/quickshell" "$HOME/.config/"
cp -r "$REPO_DIR/config/swaync" "$HOME/.config/"

if [ -d "$REPO_DIR/local-bin" ]; then
  cp -r "$REPO_DIR/local-bin/"* "$HOME/.local/bin/" 2>/dev/null || true
  chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
fi

if [ -d "$REPO_DIR/wallpapers" ]; then
  mkdir -p "$HOME/Pictures/wallpapers"
  cp -r "$REPO_DIR/wallpapers/"* "$HOME/Pictures/wallpapers/" 2>/dev/null || true
fi

echo "==> Done copying files"
echo "You may want to log out and back in after install."
