#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"
MODULES_CSV="${MODULES_CSV:-}"

STOW_DIR="$REPO_ROOT/stow"

log()  { printf "%s\n" "$*"; }
info() { log "INFO: $*"; }
ok()   { log "OK:   $*"; }
warn() { log "WARN: $*"; }

get_modules() {
  if [[ -n "$MODULES_CSV" ]]; then
    echo "$MODULES_CSV" \
      | tr ',' '\n' \
      | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
      | awk 'NF'
    return 0
  fi
  find "$STOW_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

is_hypr_running() {
  # Señales típicas de sesión Hyprland
  [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && return 0
  [[ "${XDG_CURRENT_DESKTOP:-}" == *Hyprland* ]] && return 0
  [[ "${XDG_SESSION_DESKTOP:-}" == *Hyprland* ]] && return 0

  # Fallback: proceso (no siempre confiable, pero útil)
  pgrep -x Hyprland >/dev/null 2>&1 && return 0
  return 1
}

main() {
  [[ -d "$STOW_DIR" ]] || { warn "No existe stow dir: $STOW_DIR (saltando post)"; return 0; }

  mapfile -t modules < <(get_modules)

  # Solo hacemos cosas de hypr si el módulo hypr está incluido
  if ! printf '%s\n' "${modules[@]}" | grep -qx "hypr"; then
    ok "Post: nada que hacer (módulo hypr no incluido)."
    return 0
  fi

  if ! command -v hyprctl >/dev/null 2>&1; then
    warn "Post: hyprctl no encontrado. No puedo recargar Hyprland."
    return 0
  fi

  if ! is_hypr_running; then
    ok "Post: Hyprland no está corriendo. No recargo."
    return 0
  fi

  # Opcional: asegurar que el archivo existe (stow ya debió linkearlo)
  if [[ ! -e "$HOME/.config/hypr/hyprland.conf" ]]; then
    warn "Post: no existe ~/.config/hypr/hyprland.conf. ¿El módulo hypr está correcto?"
    return 0
  fi

  info "Post: recargando Hyprland (hyprctl reload)..."
  if hyprctl reload >/dev/null 2>&1; then
    ok "Post: Hyprland recargado."
  else
    warn "Post: falló 'hyprctl reload'."
  fi
}

main "$@"

