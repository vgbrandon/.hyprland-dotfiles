#!/usr/bin/env bash
set -Eeuo pipefail

# requires log.sh loaded

have_sudo() { command -v sudo >/dev/null 2>&1; }

pacman_sync() {
  if have_sudo; then
    sudo pacman -Sy --noconfirm
  else
    pacman -Sy --noconfirm
  fi
}

pacman_install_bulk() {
  local noninteractive="$1"; shift
  local -a pkgs=("$@")
  ((${#pkgs[@]}==0)) && return 0

  local -a args=(pacman -S --needed)
  if [[ "$noninteractive" -eq 1 ]]; then
    args+=(--noconfirm)
  fi

  if have_sudo; then
    sudo "${args[@]}" "${pkgs[@]}"
  else
    "${args[@]}" "${pkgs[@]}"
  fi
}

pacman_install_resilient() {
  local noninteractive="$1"; shift
  local -a pkgs=("$@")
  ((${#pkgs[@]}==0)) && return 0

  info "Pacman: intentando instalar ${#pkgs[@]} paquetes (bulk)..."
  if pacman_install_bulk "$noninteractive" "${pkgs[@]}"; then
    ok "Pacman: bulk OK."
    return 0
  fi

  warn "Pacman: bulk falló. Reintentando paquete por paquete..."
  local -a failed=()
  for p in "${pkgs[@]}"; do
    if pacman_install_bulk "$noninteractive" "$p"; then
      ok "Pacman: instalado $p"
    else
      warn "Pacman: falló $p"
      failed+=("$p")
    fi
  done

  if ((${#failed[@]} > 0)); then
    warn "Pacman: fallaron ${#failed[@]} paquetes:"
    printf "  - %s\n" "${failed[@]}"
    return 1
  fi
  return 0
}

pacman_exists_in_repos() {
  local pkg="$1"
  pacman -Si "$pkg" >/dev/null 2>&1
}

