#!/usr/bin/env bash
set -Eeuo pipefail

# requiere log.sh + pacman.sh

detect_aur_helper() {
  command -v paru >/dev/null 2>&1 && printf "paru\n" && return 0
  command -v yay  >/dev/null 2>&1 && printf "yay\n"  && return 0
  return 1
}

build_aur_helper_paru() {
  local noninteractive="$1"
  local tmpdir
  tmpdir="$(mktemp -d)"

  info "AUR: helper no encontrado. Se instalará 'paru' desde AUR." >&2
  info "AUR: clonando 'paru'..." >&2
  git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"

  info "AUR: construyendo e instalando 'paru' con makepkg (puede tardar; compila en Rust)..." >&2
  info "AUR: si aparece 'Enter a number', presiona ENTER (default)." >&2
  info "AUR: se puede pedir contraseña sudo para instalar." >&2

  pushd "$tmpdir/paru" >/dev/null
  if [[ "$noninteractive" -eq 1 ]]; then
    info "AUR: modo no interactivo: usando defaults automáticamente." >&2
    yes | makepkg -si --noconfirm --needed
  else
    makepkg -si
  fi
  popd >/dev/null

  rm -rf "$tmpdir"
  ok "AUR: 'paru' construido e instalado." >&2
}

ensure_aur_helper() {
  local noninteractive="$1"
  local helper=""

  if helper="$(detect_aur_helper)"; then
    ok "AUR helper detectado: $helper" >&2
    printf "%s\n" "$helper"
    return 0
  fi

  command -v git >/dev/null 2>&1 || die "AUR: falta 'git' (requerido para clonar AUR)."
  command -v makepkg >/dev/null 2>&1 || die "AUR: falta 'makepkg' (instala base-devel)."

  build_aur_helper_paru "$noninteractive"

  helper="$(detect_aur_helper)" || die "AUR: no se pudo instalar/detectar 'paru'."

  # Sanitiza por si acaso (CRLF / saltos)
  helper="${helper//$'\r'/}"
  helper="${helper//$'\n'/}"

  # Garantiza PATH estándar
  if ! command -v "$helper" >/dev/null 2>&1; then
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH"
    command -v "$helper" >/dev/null 2>&1 || die "AUR: helper '$helper' no está en PATH tras instalar."
  fi

  ok "AUR helper listo: $helper" >&2
  printf "%s\n" "$helper"
}

aur_install_resilient() {
  local helper="$1"
  local noninteractive="$2"
  shift 2
  local -a pkgs=("$@")
  ((${#pkgs[@]}==0)) && return 0

  # Sanitiza por seguridad
  helper="${helper//$'\r'/}"
  helper="${helper//$'\n'/}"

  if ! command -v "$helper" >/dev/null 2>&1; then
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH"
    command -v "$helper" >/dev/null 2>&1 || die "AUR: helper '$helper' no encontrado en PATH."
  fi

  local -a args=("$helper" -S --needed)
  [[ "$noninteractive" -eq 1 ]] && args+=(--noconfirm)

  info "AUR: instalando ${#pkgs[@]} paquetes con $helper..." >&2
  if "${args[@]}" "${pkgs[@]}"; then
    ok "AUR: instalación OK." >&2
    return 0
  fi

  warn "AUR: instalación falló." >&2
  return 1
}

