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
  mkdir -p "$HOME/.config/fish/functions"

  if [ "${SHELL:-}" = "$fish_bin" ]; then
    success "Fish ya está configurado como shell por defecto."
  elif grep -qx "$fish_bin" /etc/shells 2>/dev/null; then
    if [ -t 0 ] && [ -t 1 ]; then
      read_user_input "¿Quieres cambiar tu shell por defecto a Fish ahora? [Y/n]: " change_shell
      choice="${change_shell,,}"

      case "$choice" in
        ""|y|yes|s|si)
          if chsh -s "$fish_bin" "$USER"; then
            success "Fish configurado como shell por defecto."
          else
            warning "No se pudo cambiar el shell automáticamente. Ejecuta: chsh -s $fish_bin"
          fi
          ;;
        n|no)
          warning "Cambio de shell omitido. Puedes hacerlo luego con: chsh -s $fish_bin"
          ;;
        *)
          warning "Respuesta no válida. Usa y/yes/s/si o n/no."
          warning "Cambio de shell omitido. Puedes hacerlo luego con: chsh -s $fish_bin"
          ;;
      esac
    else
      warning "Sin terminal interactiva. Ejecuta manualmente: chsh -s $fish_bin"
    fi
  else
    warning "Fish no está en /etc/shells. Agrega '$fish_bin' para poder usarlo como shell por defecto."
  fi
else
  warning "fish no encontrado. Saltando configuración de Fish."
fi

success "Post-instalación completada."
