#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_REPO="https://github.com/vgbrandon/.hyprland-dotfiles.git"
DOTFILES_DIR="$HOME/.hyprland-dotfiles"

log()  { printf "%s\n" "$*"; }
info() { log "INFO: $*"; }
ok()   { log "OK:   $*"; }
die()  { log "ERR:  $*"; exit 1; }

info "Bootstrap: iniciando instalación de dotfiles"

# 1) Verificar que estamos en Arch
[[ -f /etc/arch-release ]] || die "Este script está pensado solo para Arch Linux."

# 2) Verificar sudo
command -v sudo >/dev/null 2>&1 || die "sudo no está instalado. Instálalo y configura un usuario."

# 3) Asegurar git
if ! command -v git >/dev/null 2>&1; then
  info "Instalando git..."
  sudo pacman -Sy --noconfirm git
fi

# 4) Clonar dotfiles
if [[ -d "$DOTFILES_DIR" ]]; then
  warn "El repo ya existe en $DOTFILES_DIR. Usando el existente."
else
  info "Clonando dotfiles..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# 5) Permisos
chmod +x "$DOTFILES_DIR/install/run.sh"

# 6) Ejecutar instalador principal
info "Ejecutando instalador principal..."
cd "$DOTFILES_DIR"
./install/run.sh

ok "Bootstrap finalizado."

