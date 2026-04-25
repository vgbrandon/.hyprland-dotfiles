#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/vgbrandon/.hyprland-dotfiles.git"
INSTALL_DIR="$HOME/.hyprland-dotfiles"

echo "[INFO] Instalando dotfiles..."

if [ -d "$INSTALL_DIR/.git" ]; then
  echo "[INFO] Repositorio existente. Actualizando..."
  git -C "$INSTALL_DIR" pull
else
  echo "[INFO] Clonando repositorio..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

bash ./setup/run.sh
