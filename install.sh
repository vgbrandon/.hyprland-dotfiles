#!/usr/bin/env bash
set -euo pipefail

REPO="vgbrandon/.hyprland-dotfiles"
SOURCE_DIR="$HOME/.hyprland-dotfiles"
BIN_DIR="$HOME/.local/bin"

echo "[INFO] Instalando dotfiles con chezmoi..."

sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BIN_DIR" init --source "$SOURCE_DIR" --apply "$REPO"

echo "[OK] Instalación completada."

if ! command -v chezmoi >/dev/null 2>&1; then
  echo "[WARN] chezmoi se instaló en $BIN_DIR, que no está en tu PATH todavía."
  echo "[WARN] Abre una terminal nueva, o agrega $BIN_DIR a tu PATH manualmente."
fi
