#!/usr/bin/env bash
set -euo pipefail

# Compila e instala velure, el generador del tema (~/.local/bin/velure).
#
# Va fijado a un commit y no a main: el binario y ~/.config/velure/config.toml
# tienen que ir a la par. Para actualizarlo, cambia VELURE_REF por el commit nuevo
# del repo; al cambiar este archivo, chezmoi vuelve a ejecutar el script.
VELURE_REPO="https://github.com/vgbrandon/velure.git"
VELURE_REF="a0c04f9d17868116b0d5180906b4ecc77980de44"

if ! command -v cargo >/dev/null 2>&1; then
  echo "[ERROR] Falta cargo (paquete rust en .chezmoidata/packages.yaml)." >&2
  exit 1
fi

echo "[INFO] Compilando velure (${VELURE_REF:0:7})..."

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

git -C "$tmp_dir" init -q
git -C "$tmp_dir" fetch -q --depth 1 "$VELURE_REPO" "$VELURE_REF"
git -C "$tmp_dir" checkout -q FETCH_HEAD

# --force: reemplaza un velure instalado a mano; --locked: las versiones de Cargo.lock
cargo install --locked --force --path "$tmp_dir" --root "$HOME/.local"

echo "[OK] velure instalado en ~/.local/bin/velure ($("$HOME/.local/bin/velure" --version))."
