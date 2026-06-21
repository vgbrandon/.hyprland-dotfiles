#!/usr/bin/env bash

get_stow_modules() {
  if [ -n "${MODULES_CSV:-}" ]; then
    echo "$MODULES_CSV" \
      | tr ',' '\n' \
      | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
      | awk 'NF'
    return
  fi

  local exclude="${STOW_EXCLUDE:-}"
  find "$STOW_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort \
    | grep -vFf <(echo "$exclude" | tr ',' '\n' | awk 'NF')
}

extract_stow_conflicts() {
  stow --dir "$STOW_DIR" --target "$HOME" --no --verbose=2 "$@" 2>&1 \
    | sed -n 's/.*over existing target \([^ ]*\) .*/\1/p' \
    | sed 's#^\./##' \
    | sort -u
}

is_real_file_or_dir() {
  local path="$1"

  [ -e "$path" ] && [ ! -L "$path" ]
}

backup_stow_conflict() {
  local abs_path="$1"
  local rel_path="${abs_path#"$HOME"/}"
  local backup_root="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
  local backup_path="$backup_root/$rel_path"

  mkdir -p "$(dirname "$backup_path")"
  mv -- "$abs_path" "$backup_path"

  success "Backup: $abs_path -> $backup_path"
}

delete_stow_conflict() {
  local abs_path="$1"

  rm -rf -- "$abs_path"

  success "Eliminado: $abs_path"
}

run_stow() {
  stow --dir "$STOW_DIR" --target "$HOME" "$@"
}

run_stow_at() {
  local target="$1"
  shift
  stow --dir "$STOW_DIR" --target "$target" "$@"
}

reload_hyprland() {
  if command -v hyprctl >/dev/null 2>&1 && hyprctl monitors >/dev/null 2>&1; then
    info "Recargando Hyprland..."
    hyprctl reload
    success "Hyprland recargado."
  fi
}
