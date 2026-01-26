#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"
NONINTERACTIVE="${NONINTERACTIVE:-0}"

# Opcional: permitir preset desde env
GIT_NAME_DEFAULT="${GIT_NAME_DEFAULT:-}"
GIT_EMAIL_DEFAULT="${GIT_EMAIL_DEFAULT:-}"

# shellcheck source=/dev/null
source "$REPO_ROOT/install/lib/log.sh"

have() { command -v "$1" >/dev/null 2>&1; }

git_get() {
  git config --global --get "$1" 2>/dev/null || true
}

main() {
  if ! have git; then
    warn "Git no está instalado. Saltando configuración."
    return 0
  fi

  local cur_name cur_email
  cur_name="$(git_get user.name)"
  cur_email="$(git_get user.email)"

  info "Configuración actual de Git:"
  echo "  user.name  = ${cur_name:-<no definido>}"
  echo "  user.email = ${cur_email:-<no definido>}"

  # Modo no interactivo
  if [[ "$NONINTERACTIVE" -eq 1 ]]; then
    if [[ -n "$GIT_NAME_DEFAULT" && -n "$GIT_EMAIL_DEFAULT" ]]; then
      info "Modo no interactivo: aplicando valores desde variables de entorno."
      git config --global user.name  "$GIT_NAME_DEFAULT"
      git config --global user.email "$GIT_EMAIL_DEFAULT"
      ok "Git configurado (noninteractive)."
    else
      warn "Modo no interactivo: sin GIT_NAME_DEFAULT / GIT_EMAIL_DEFAULT. Saltando."
    fi
    return 0
  fi

  echo
  # Preguntar si ya existe algo
  if [[ -n "$cur_name" || -n "$cur_email" ]]; then
    read -r -p "¿Deseas reemplazar la configuración actual de Git? [y/N]: " replace
    case "${replace,,}" in
      y|yes) ;;
      *)
        warn "Git no modificado."
        return 0
        ;;
    esac
  fi

  # Pedir datos
  local name email
  read -r -p "Git user.name : " name
  read -r -p "Git user.email: " email

  [[ -n "$name"  ]] || die "user.name no puede estar vacío."
  [[ -n "$email" ]] || die "user.email no puede estar vacío."

  git config --global user.name  "$name"
  git config --global user.email "$email"

  ok "Git configurado:"
  echo "  user.name  = $(git_get user.name)"
  echo "  user.email = $(git_get user.email)"
}

main "$@"
