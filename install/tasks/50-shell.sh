#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"

# shellcheck source=/dev/null
source "$REPO_ROOT/install/lib/log.sh"

have() { command -v "$1" >/dev/null 2>&1; }

current_shell() {
  getent passwd "$USER" | cut -d: -f7
}

main() {
  if ! have fish; then
    warn "Fish no está instalado. No puedo cambiar la shell. (Asegúralo en tus listas de paquetes)."
    return 0
  fi

  local fish_path
  fish_path="$(command -v fish)"
  local cur
  cur="$(current_shell)"

  if [[ "$cur" == "$fish_path" ]]; then
    ok "Shell actual ya es fish ($fish_path)."
    return 0
  fi

  info "Shell actual : $cur"
  info "Cambiando a  : $fish_path"

  # Asegura que fish sea shell válida
  if [[ -f /etc/shells ]]; then
    if ! grep -qx "$fish_path" /etc/shells; then
      info "Agregando fish a /etc/shells (requiere sudo)..."
      echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi
  else
    warn "/etc/shells no existe; intentando continuar igual."
  fi

  # Cambia shell del usuario actual (no requiere sudo en la mayoría de casos)
  chsh -s "$fish_path" || die "No se pudo cambiar la shell con chsh."

  ok "Shell cambiada a fish. Cierra sesión y vuelve a entrar para que se aplique."
}

main "$@"
