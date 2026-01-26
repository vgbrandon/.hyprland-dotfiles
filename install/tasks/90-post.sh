#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"
NONINTERACTIVE="${NONINTERACTIVE:-0}"

# shellcheck source=/dev/null
source "$REPO_ROOT/install/lib/log.sh"

have() { command -v "$1" >/dev/null 2>&1; }

hypr_running() {
  have hyprctl && hyprctl monitors >/dev/null 2>&1
}

main() {
  info "Post: instalación completada."

  # Si no estamos en Hyprland, no tiene sentido preguntar
  if ! hypr_running; then
    warn "Post: no se detecta una sesión Hyprland activa."
    warn "Post: reinicia sesión o sistema para aplicar completamente la configuración."
    return 0
  fi

  # En modo no interactivo nunca forzamos nada
  if [[ "$NONINTERACTIVE" -eq 1 ]]; then
    warn "Post: para aplicar completamente la configuración (monitores/Hyprland), reinicia la sesión."
    return 0
  fi

  echo
  echo "⚠️  Para aplicar completamente la configuración (especialmente monitores)"
  echo "   es recomendable reiniciar la sesión de Hyprland."
  echo
  read -r -p "¿Deseas reiniciar la sesión ahora? [y/N]: " ans

  case "${ans,,}" in
    y|yes)
      info "Post: reiniciando sesión Hyprland..."
      # Forma más limpia: salir del compositor (display manager vuelve a entrar)
      hyprctl dispatch exit || warn "Post: no se pudo cerrar la sesión automáticamente."
      ;;
    *)
      warn "Post: cambios pendientes. Reinicia sesión cuando te sea conveniente."
      ;;
  esac
}

main "$@"

