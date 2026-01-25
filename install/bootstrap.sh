#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_REPO="https://github.com/vgbrandon/.hyprland-dotfiles.git"
DOTFILES_DIR="$HOME/.hyprland-dotfiles"

log()  { printf "%s\n" "$*"; }
info() { log "INFO: $*"; }
ok()   { log "OK:   $*"; }
warn() { log "WARN: $*"; }
die()  { log "ERR:  $*"; exit 1; }

info "Bootstrap: iniciando instalación de dotfiles"

# 1) Verificar Arch
[[ -f /etc/arch-release ]] || die "Este script está pensado solo para Arch Linux."

# 2) Requiere sudo (usuario normal con permisos)
command -v sudo >/dev/null 2>&1 || die "Falta sudo. Instálalo y configura un usuario con permisos (wheel)."

# 3) Sincronizar repos (por si es instalación fresca)
info "Sincronizando base de paquetes..."
sudo pacman -Sy --noconfirm >/dev/null || die "No se pudo sincronizar pacman."

# 4) Asegurar git
if ! command -v git >/dev/null 2>&1; then
  info "Instalando git..."
  sudo pacman -S --noconfirm --needed git || die "No se pudo instalar git."
fi

# 5) Clonar / actualizar dotfiles
if [[ -d "$DOTFILES_DIR/.git" ]]; then
  warn "El repo ya existe en $DOTFILES_DIR. Actualizando..."
  git -C "$DOTFILES_DIR" pull --rebase || warn "No se pudo hacer pull (continuando con lo existente)."
elif [[ -d "$DOTFILES_DIR" ]]; then
  warn "Existe $DOTFILES_DIR pero no parece repo git. No lo toco."
  die "Renombra esa carpeta o bórrala y vuelve a ejecutar."
else
  info "Clonando dotfiles..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || die "No se pudo clonar el repo."
fi

# 6) Permisos
chmod +x "$DOTFILES_DIR/install/run.sh" "$DOTFILES_DIR/install/tasks/"*.sh "$DOTFILES_DIR/install/lib/"*.sh 2>/dev/null || true

# 7) Ejecutar instalador principal
info "Ejecutando instalador principal..."
cd "$DOTFILES_DIR"
./install/run.sh

ok "Bootstrap finalizado."

