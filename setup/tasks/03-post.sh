#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$SHARED_DIR/utils.sh"

info "Ejecutando configuración post-instalación..."

# Thunar (xfconf)

if command -v xfconf-query >/dev/null 2>&1; then
  info "Configurando Thunar..."

  xfconf-query -c thunar -p /last-show-hidden -n -t bool -s true

  success "Thunar configurado."
else
  warning "xfconf-query no encontrado. Saltando configuración de Thunar."
fi

# Fish

if command -v fish >/dev/null 2>&1; then
  info "Configurando Fish..."

  fish_bin="$(command -v fish)"
  target_user="${SUDO_USER:-${USER:-}}"
  current_shell="$(getent passwd "$target_user" 2>/dev/null | cut -d: -f7 || true)"
  mkdir -p "$HOME/.config/fish/functions"

  if [ "$current_shell" = "$fish_bin" ] || [ "${SHELL:-}" = "$fish_bin" ]; then
    success "Fish ya está configurado como shell por defecto."
  elif grep -qx "$fish_bin" /etc/shells 2>/dev/null; then
    if [ -z "$target_user" ]; then
      warning "No se pudo detectar el usuario objetivo para configurar Fish."
    elif command -v usermod >/dev/null 2>&1; then
      if sudo usermod -s "$fish_bin" "$target_user"; then
        success "Fish configurado como shell por defecto para $target_user."
      else
        warning "No se pudo cambiar el shell automáticamente para $target_user."
      fi
    else
      warning "usermod no encontrado. No se pudo configurar Fish como shell por defecto."
    fi
  else
    warning "Fish no está en /etc/shells. Agrega '$fish_bin' para poder usarlo como shell por defecto."
  fi
else
  warning "fish no encontrado. Saltando configuración de Fish."
fi

# Git

if command -v git >/dev/null 2>&1; then
  info "Configurando Git..."

  current_name="$(git config --global user.name || true)"
  current_email="$(git config --global user.email || true)"

  if [ "$current_name" != "vgbrandon" ]; then
    git config --global user.name "vgbrandon"
    info "  user.name → vgbrandon"
  fi

  if [ "$current_email" != "vgbrandon.dev@gmail.com" ]; then
    git config --global user.email "vgbrandon.dev@gmail.com"
    info "  user.email → vgbrandon.dev@gmail.com"
  fi

  if [ "$current_name" = "vgbrandon" ] && [ "$current_email" = "vgbrandon.dev@gmail.com" ]; then
    success "Git ya estaba configurado correctamente."
  else
    success "Git configurado."
  fi
else
  warning "git no encontrado. Saltando configuración de Git."
fi

# opencode

if command -v opencode >/dev/null 2>&1; then
  success "opencode ya está instalado."
else
  info "Instalando opencode..."

  if curl -fsSL https://opencode.ai/install | bash; then
    success "opencode instalado correctamente."
  else
    warning "No se pudo instalar opencode. Puedes intentarlo manualmente desde https://opencode.ai"
  fi
fi

# rEFInd theme

THEME_SRC="$ROOT_DIR/stow/refind/boot/EFI/refind/refind-theme"
THEME_DST="/boot/EFI/refind/refind-theme"

if [ -d "/boot/EFI/refind" ]; then
  info "Configurando tema rEFInd..."

  if [ -L "$THEME_DST" ] && [ -e "$THEME_DST" ]; then
    success "Symlink del tema rEFInd ya existe."
  elif [ -d "$THEME_DST" ]; then
    warning "El directorio $THEME_DST ya existe y no es un symlink. Omitiendo."
  elif sudo ln -sf "$THEME_SRC" "$THEME_DST" 2>/dev/null; then
    success "Symlink del tema rEFInd creado."
  else
    warning "No se pudo crear symlink (ESP sin soporte). Copiando archivos..."
    sudo cp -r "$THEME_SRC" "$THEME_DST"
  fi

  if ! grep -q "refind-theme/theme.conf" /boot/EFI/refind/refind.conf 2>/dev/null; then
    echo "include refind-theme/theme.conf" | sudo tee -a /boot/EFI/refind/refind.conf >/dev/null
    success "Tema rEFInd configurado en refind.conf."
  else
    success "Tema rEFInd ya estaba configurado en refind.conf."
  fi
else
  warning "No se encontró /boot/EFI/refind. Ejecutá refind-install primero."
fi

success "Post-instalación completada."
