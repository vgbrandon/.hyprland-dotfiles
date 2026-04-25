#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"
source "$SHARED_DIR/utils.sh"

info "Iniciando instalación..."

for task in "$TASKS_DIR"/*.sh; do
  [ -e "$task" ] || continue

  info "→ $(basename "$task")"
  bash "$task"
done

success "Instalación completada."
