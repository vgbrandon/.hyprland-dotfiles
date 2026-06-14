#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$SHARED_DIR/utils.sh"
source "$SERVICES_DIR/pacman.sh"
source "$SERVICES_DIR/aur.sh"

BASE_FILE="$PACKAGES_DIR/base.txt"
PACMAN_FILE="$PACKAGES_DIR/pacman.txt"
AUR_FILE="$PACKAGES_DIR/aur.txt"

mapfile -t base_packages < <(read_list_file "$BASE_FILE")
mapfile -t pacman_packages < <(read_list_file "$PACMAN_FILE")
mapfile -t aur_packages < <(read_list_file "$AUR_FILE")

info "Instalando paquetes base..."
install_pacman_packages "${base_packages[@]}"

info "Instalando paquetes oficiales..."
install_pacman_packages "${pacman_packages[@]}"

# AUR DESHABILITADO TEMPORALMENTE
# Motivo: prevención de seguridad tras incidente.
# Los paquetes AUR se instalarán manualmente cuando sea seguro.
# info "Instalando paquetes AUR..."
# install_aur_packages "${aur_packages[@]}"

success "Paquetes instalados correctamente."
