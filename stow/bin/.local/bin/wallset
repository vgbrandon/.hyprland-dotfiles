#!/usr/bin/env bash
set -Eeuo pipefail

# ----------------------------
# Config (ajusta a tu gusto)
# ----------------------------
WALL_DIR_DEFAULT="${WALL_DIR_DEFAULT:-$HOME/Pictures/wallpapers}"
TRANSITION_DEFAULT="${TRANSITION_DEFAULT:-grow}"   # any | fade | grow | wipe | outer | wave | simple
DURATION_DEFAULT="${DURATION_DEFAULT:-0.8}"        # segundos
FPS_DEFAULT="${FPS_DEFAULT:-60}"
BEZIER_DEFAULT="${BEZIER_DEFAULT:-0.1,0.9,0.2,1.0}"

# Algunos transitions usan "pos"; grow/wipe/wave se ven mejor con cursor
POS_DEFAULT="${POS_DEFAULT:-cursor}"

# ----------------------------
# Logging
# ----------------------------
log()  { printf "%s\n" "$*"; }
info() { log "INFO: $*"; }
ok()   { log "OK:   $*"; }
warn() { log "WARN: $*"; }
die()  { log "ERR:  $*"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# ----------------------------
# Helpers
# ----------------------------
ensure_swww() {
  have swww || die "Falta 'swww'. Instálalo (pacman/AUR según tu lista)."

  # Si ya responde, ok
  if swww query >/dev/null 2>&1; then
    return 0
  fi

  # Intentar levantar daemon (sin systemd)
  info "swww no está activo. Iniciando daemon..."
  (swww-daemon >/dev/null 2>&1 & disown) || true

  # esperar breve
  for _ in {1..20}; do
    swww query >/dev/null 2>&1 && return 0
    sleep 0.1
  done

  die "No pude iniciar swww-daemon."
}

pick_wallpaper() {
  local arg="${1:-}"
  local dir="${2:-$WALL_DIR_DEFAULT}"

  if [[ -n "$arg" ]]; then
    [[ -f "$arg" ]] || die "No existe el archivo: $arg"
    echo "$arg"
    return 0
  fi

  [[ -d "$dir" ]] || die "No existe el directorio de wallpapers: $dir"

  # Soporta espacios y extensiones comunes
  mapfile -t files < <(find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)
  ((${#files[@]} > 0)) || die "No encontré imágenes en: $dir"

  # random seguro
  local idx=$((RANDOM % ${#files[@]}))
  echo "${files[$idx]}"
}

apply_swww() {
  local img="$1"
  local transition="${2:-$TRANSITION_DEFAULT}"
  local duration="${3:-$DURATION_DEFAULT}"
  local fps="${4:-$FPS_DEFAULT}"
  local bezier="${5:-$BEZIER_DEFAULT}"
  local pos="${6:-$POS_DEFAULT}"

  ensure_swww

  info "Aplicando wallpaper con swww..."
  info "  img: $img"
  info "  transition: $transition  duration: $duration  fps: $fps"

  # Pos aplica para algunos transitions; no hace daño si no se usa
  swww img "$img" \
    --transition-type "$transition" \
    --transition-duration "$duration" \
    --transition-fps "$fps" \
    --transition-bezier "$bezier" \
    --transition-pos "$pos"

  ok "Wallpaper aplicado."
}

apply_wal() {
  local img="$1"

  if ! have wal; then
    warn "pywal (wal) no está instalado; saltando colores."
    return 0
  fi

  info "Generando paleta con pywal..."
  # -n: no set wallpaper (ya lo hace swww)
  # -q: menos ruido
  # -i: imagen
  wal -n -q -i "$img"
  ok "pywal aplicado (~/.cache/wal/* actualizado)."
}

reload_targets() {
  # Hyprland: si tienes en tu hyprland.conf algo como:
  #   source = ~/.cache/wal/colors-hyprland.conf
  # entonces un reload aplica colores. Pero reload completo puede mover cosas.
  # Preferimos: recargar solo decoraciones si usas "keyword" (opcional).
  if have hyprctl && hyprctl monitors >/dev/null 2>&1; then
    # Si quieres evitar el “desaparece”, NO hacemos hyprctl reload aquí.
    # Solo avisamos.
    info "Hyprland está activo. (No hago hyprctl reload automáticamente para evitar glitches de monitores.)"
    info "Si tus colores de wal se aplican vía 'source', reinicia sesión o ejecuta hyprctl reload manualmente."
  fi

  # Kitty: si usas include wal (p.ej. include ~/.cache/wal/colors-kitty.conf)
  if have pkill; then
    pkill -USR1 kitty >/dev/null 2>&1 || true
  fi

  # Waybar: recargar (si existe)
  if have waybar && have pkill; then
    pkill -SIGUSR2 waybar >/dev/null 2>&1 || true
  fi

  # Rofi no necesita reload; toma tema al abrir.
  ok "Recargas enviadas (kitty/waybar si aplicaba)."
}

usage() {
  cat <<EOF
Uso:
  wall.sh [IMAGEN] [--dir DIR] [--transition TYPE] [--duration SEC]

Ejemplos:
  wall.sh                              # random de $WALL_DIR_DEFAULT
  wall.sh --dir ~/Pictures/Walls       # random de otro dir
  wall.sh ~/Pictures/wall.png          # imagen específica
  wall.sh --transition fade --duration 1.2

Notas:
  - Requiere swww + swww-daemon.
  - Si tienes pywal (wal), generará paleta en ~/.cache/wal/
EOF
}

main() {
  local img_arg=""
  local dir="$WALL_DIR_DEFAULT"
  local transition="$TRANSITION_DEFAULT"
  local duration="$DURATION_DEFAULT"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      --dir) dir="${2:-}"; shift 2 ;;
      --transition) transition="${2:-}"; shift 2 ;;
      --duration) duration="${2:-}"; shift 2 ;;
      --) shift; break ;;
      -*)
        die "Opción desconocida: $1"
        ;;
      *)
        # primer positional = imagen
        if [[ -z "$img_arg" ]]; then
          img_arg="$1"
          shift
        else
          die "Argumento extra inesperado: $1"
        fi
        ;;
    esac
  done

  local img
  img="$(pick_wallpaper "$img_arg" "$dir")"

  apply_swww "$img" "$transition" "$duration"
  apply_wal "$img"
  reload_targets

  ok "Listo."
}

main "$@"

