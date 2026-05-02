#!/usr/bin/env bash

info() { echo "[INFO] $1"; }
success() { echo "[OK] $1"; }
warning() { echo "[WARN] $1"; }
error() { echo "[ERROR] $1"; }

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    error "$command_name no está instalado."
    exit 1
  fi
}

read_list_file() {
  local file="$1"

  if [ ! -f "$file" ]; then
    error "No existe el archivo: $file"
    exit 1
  fi

  sed 's/#.*//' "$file" | xargs -n1
}

read_user_input() {
  local prompt="$1"
  local __var_name="$2"
  local value=""

  if [ -r /dev/tty ]; then
    read -r -p "$prompt" value < /dev/tty
  else
    read -r -p "$prompt" value
  fi

  printf -v "$__var_name" '%s' "$value"
}
