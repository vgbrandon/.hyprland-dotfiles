#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"
NONINTERACTIVE="${NONINTERACTIVE:-0}"

LISTS_DIR="$REPO_ROOT/install/lists"

# libs
# shellcheck source=/dev/null
source "$REPO_ROOT/install/lib/log.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/install/lib/lists.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/install/lib/pacman.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/install/lib/aur.sh"

main() {
  [[ -d "$LISTS_DIR" ]] || die "No existe lists dir: $LISTS_DIR"

  local pacman_base="$LISTS_DIR/pacman.base.txt"
  local pacman_gui="$LISTS_DIR/pacman.gui.txt"
  local aur_base="$LISTS_DIR/aur.base.txt"
  local aur_gui="$LISTS_DIR/aur.gui.txt"

  info "Leyendo listas desde: $LISTS_DIR"

  mapfile -t pacman_pkgs < <( { read_list "$pacman_base"; read_list "$pacman_gui"; } | sort -u )
  mapfile -t aur_pkgs    < <( { read_list "$aur_base";    read_list "$aur_gui";    } | sort -u )

  info "Pacman paquetes: ${#pacman_pkgs[@]}"
  info "AUR paquetes   : ${#aur_pkgs[@]}"

  info "Actualizando DB de pacman..."
  pacman_sync || warn "pacman -Sy falló (puede ser temporal). Continuando..."

  if ((${#pacman_pkgs[@]} > 0)); then
    pacman_install_resilient "$NONINTERACTIVE" "${pacman_pkgs[@]}" \
      || warn "Pacman: hubo fallos (paquetes mal escritos o no disponibles)."
  else
    ok "Pacman: no hay paquetes para instalar."
  fi

  if ((${#aur_pkgs[@]} > 0)); then
    info "AUR: hay paquetes en listas AUR. Se requiere un helper (paru/yay)."
    helper="$(ensure_aur_helper "$NONINTERACTIVE")"
    aur_install_resilient "$helper" "$NONINTERACTIVE" "${aur_pkgs[@]}" \
      || warn "AUR: hubo fallos (ver arriba)."
  else
    ok "AUR: no hay paquetes para instalar."
  fi

  ok "Task packages finalizado."
}

main "$@"

