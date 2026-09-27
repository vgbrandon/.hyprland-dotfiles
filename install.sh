#!/usr/bin/env bash
set -euo pipefail

REPO="vgbrandon/.hyprland-dotfiles"

echo "[INFO] Instalando dotfiles con chezmoi..."

sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply "$REPO"

echo "[OK] Instalación completada."
