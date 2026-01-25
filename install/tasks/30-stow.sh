#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"
NONINTERACTIVE="${NONINTERACTIVE:-0}"
MODULES_CSV="${MODULES_CSV:-}"

STOW_DIR="$REPO_ROOT/stow"
TARGET="$HOME"

# ---------- logging ----------
log()  { printf "%s\n" "$*"; }
info() { log "INFO: $*"; }
ok()   { log "OK:   $*"; }
warn() { log "WARN: $*"; }
die()  { log "ERR:  $*"; exit 1; }

ts() { date +%Y%m%d-%H%M%S; }

# ---------- modules ----------
get_modules() {
  if [[ -n "$MODULES_CSV" ]]; then
    # "a,b,c" -> lines
    echo "$MODULES_CSV" \
      | tr ',' '\n' \
      | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
      | awk 'NF'
    return 0
  fi
  find "$STOW_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

# ---------- conflict detection ----------
# Extract conflict targets from stow dry-run output:
# "... over existing target .config/xxx ..."
extract_conflicts() {
  # IMPORTANT: do not use "$@" unquoted here because we want stow to see each module as argument.
  # shellcheck disable=SC2068
  stow --dir "$STOW_DIR" --target "$TARGET" --no --verbose=2 $@ 2>&1 \
    | sed -n 's/.*over existing target \([^ ]*\) .*/\1/p' \
    | sed 's#^\./##' \
    | sort -u
}

is_real() {
  local p="$1"
  [[ -e "$p" && ! -L "$p" ]]
}

backup_one() {
  local abs="$1"
  local rel="${abs#${HOME}/}"
  local backup_root="$HOME/.dotfiles-backup/$(ts)"
  local dst="$backup_root/$rel"
  mkdir -p "$(dirname "$dst")"
  mv -- "$abs" "$dst"
  ok "Backup: $abs -> $dst"
}

delete_one() {
  local abs="$1"
  rm -rf -- "$abs"
  ok "Deleted: $abs"
}

main() {
  [[ -d "$STOW_DIR" ]] || die "No existe: $STOW_DIR"
  command -v stow >/dev/null 2>&1 || die "Falta stow: sudo pacman -S stow"

  mapfile -t modules < <(get_modules)
  ((${#modules[@]} > 0)) || die "No hay módulos en $STOW_DIR"

  info "Stow dir: $STOW_DIR"
  info "Target  : $TARGET"
  info "Modules : ${modules[*]}"

  # Dry-run -> conflicts (relative paths like ".config/...")
  mapfile -t conflicts_rel < <(extract_conflicts "${modules[@]}")

  if ((${#conflicts_rel[@]} == 0)); then
    ok "Sin conflictos. Ejecutando stow..."
    stow --dir "$STOW_DIR" --target "$TARGET" "${modules[@]}"
    ok "Stow completado."
    return 0
  fi

  # Filtra solo los que existen y no son symlink
  real_conflicts=()
  for rel in "${conflicts_rel[@]}"; do
    rel="${rel#./}"
    abs="$HOME/$rel"
    if is_real "$abs"; then
      real_conflicts+=("$abs")
    fi
  done

  # Si stow reportó conflictos pero ninguno es real (edge case), seguimos.
  if ((${#real_conflicts[@]} == 0)); then
    warn "Stow reportó conflictos, pero ninguno es archivo/dir real no-symlink. Continuando..."
    stow --dir "$STOW_DIR" --target "$TARGET" "${modules[@]}"
    ok "Stow completado."
    return 0
  fi

  # ---- Print conflicts (no duplicado) ----
  if ((${#real_conflicts[@]} == ${#conflicts_rel[@]})); then
    warn "Conflictos detectados (archivos reales):"
    for abs in "${real_conflicts[@]}"; do
      echo "  - $abs"
    done
  else
    warn "Conflictos detectados (stow):"
    for rel in "${conflicts_rel[@]}"; do
      echo "  - $HOME/$rel"
    done

    echo
    warn "Bloquean stow (archivos/dirs reales):"
    for abs in "${real_conflicts[@]}"; do
      echo "  - $abs"
    done
  fi
  echo

  # ---- Ask action ----
  action=""
  if [[ "$NONINTERACTIVE" -eq 1 ]]; then
    action="backup"
    info "Modo no interactivo: usando BACKUP."
  else
    echo "Elige una opción:"
    echo "  1) backup  (mover a ~/.dotfiles-backup/<timestamp>/...)"
    echo "  2) delete  (eliminar definitivamente)"
    echo "  3) manual  (abortar para resolver tú)"
    read -r -p "Selecciona [1/2/3]: " choice
    case "${choice:-}" in
      1) action="backup" ;;
      2) action="delete" ;;
      3) action="manual" ;;
      *) die "Opción inválida." ;;
    esac
  fi

  case "$action" in
    manual)
      die "Abortado. Resuelve los conflictos y vuelve a ejecutar."
      ;;
    backup)
      for abs in "${real_conflicts[@]}"; do backup_one "$abs"; done
      ;;
    delete)
      for abs in "${real_conflicts[@]}"; do delete_one "$abs"; done
      ;;
  esac

  info "Ejecutando stow..."
  stow --dir "$STOW_DIR" --target "$TARGET" "${modules[@]}"
  ok "Stow completado."
}

main "$@"

