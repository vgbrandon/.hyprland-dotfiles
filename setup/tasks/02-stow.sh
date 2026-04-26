#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$SHARED_DIR/utils.sh"
source "$SERVICES_DIR/stow.sh"

NONINTERACTIVE="${NONINTERACTIVE:-0}"

info "Aplicando dotfiles con stow..."

[ -d "$STOW_DIR" ] || {
  error "No existe: $STOW_DIR"
  exit 1
}

require_command stow

mapfile -t modules < <(get_stow_modules)

if [ "${#modules[@]}" -eq 0 ]; then
  warning "No hay módulos en $STOW_DIR. Saltando stow."
  exit 0
fi

info "Stow dir: $STOW_DIR"
info "Target: $HOME"
info "Modules: ${modules[*]}"

mapfile -t conflicts_rel < <(extract_stow_conflicts "${modules[@]}")

if [ "${#conflicts_rel[@]}" -eq 0 ]; then
  success "Sin conflictos. Ejecutando stow..."
  run_stow "${modules[@]}"
  success "Stow completado."
  reload_hyprland
  exit 0
fi

real_conflicts=()

for rel_path in "${conflicts_rel[@]}"; do
  rel_path="${rel_path#./}"
  abs_path="$HOME/$rel_path"

  if is_real_file_or_dir "$abs_path"; then
    real_conflicts+=("$abs_path")
  fi
done

if [ "${#real_conflicts[@]}" -eq 0 ]; then
  warning "Stow reportó conflictos, pero ninguno es archivo/directorio real. Continuando..."
  run_stow "${modules[@]}"
  success "Stow completado."
  reload_hyprland
  exit 0
fi

warning "Conflictos detectados:"
for abs_path in "${real_conflicts[@]}"; do
  echo "  - $abs_path"
done

echo

action=""

if [ "$NONINTERACTIVE" -eq 1 ]; then
  action="backup"
  info "Modo no interactivo: usando backup."
else
  while true; do
    echo "Elige una opción:"
    echo "  1) backup  mover a ~/.dotfiles-backup/<timestamp>/..."
    echo "  2) delete  eliminar definitivamente"
    echo "  3) manual  abortar para resolver manualmente"
    read -r -p "Selecciona [1/2/3]: " choice

    case "${choice:-}" in
      1) action="backup"; break ;;
      2) action="delete"; break ;;
      3) action="manual"; break ;;
      *) warning "Esa opción no existe. Intenta de nuevo."; echo ;;
    esac
  done
fi

case "$action" in
  manual)
    error "Abortado. Resuelve los conflictos y vuelve a ejecutar."
    exit 1
    ;;
  backup)
    for abs_path in "${real_conflicts[@]}"; do
      backup_stow_conflict "$abs_path"
    done
    ;;
  delete)
    for abs_path in "${real_conflicts[@]}"; do
      delete_stow_conflict "$abs_path"
    done
    ;;
esac

info "Ejecutando stow..."
run_stow "${modules[@]}"
success "Stow completado."

reload_hyprland
