#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$SHARED_DIR/utils.sh"

info "Verificando dependencias básicas..."

require_command git
require_command sudo
require_command pacman

success "Dependencias OK"
