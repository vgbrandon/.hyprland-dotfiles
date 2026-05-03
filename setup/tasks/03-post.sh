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
    elif [ "$(id -u)" -eq 0 ] && command -v usermod >/dev/null 2>&1; then
      if usermod -s "$fish_bin" "$target_user"; then
        success "Fish configurado como shell por defecto para $target_user."
      else
        warning "No se pudo cambiar el shell automáticamente para $target_user."
      fi
    else
      warning "Se requieren privilegios de root para cambiar el shell automáticamente."
    fi
  else
    warning "Fish no está en /etc/shells. Agrega '$fish_bin' para poder usarlo como shell por defecto."
  fi
else
  warning "fish no encontrado. Saltando configuración de Fish."
fi

success "Post-instalación completada."
