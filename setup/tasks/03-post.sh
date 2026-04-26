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

success "Post-instalación completada."
