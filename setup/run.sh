#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"
source "$SHARED_DIR/utils.sh"

init_sudo_session() {
  if sudo -n true 2>/dev/null; then
    info "Sesion sudo activa."
  else
    info "La instalación requiere permisos de sudo. Ingresa tu contraseña una sola vez..."
    sudo -v
  fi

  while true; do
    sudo -n true || true
    sleep 50
  done 2>/dev/null &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1 || true' EXIT
}

info "Iniciando instalación..."

init_sudo_session

for task in "$TASKS_DIR"/*.sh; do
  [ -e "$task" ] || continue

  info "→ $(basename "$task")"
  bash "$task"
done

success "Instalación completada."
