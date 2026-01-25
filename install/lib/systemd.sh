#!/usr/bin/env bash
set -Eeuo pipefail

# requiere log.sh

have_sudo() { command -v sudo >/dev/null 2>&1; }

sys_unit_exists() {
  local unit="$1"
  [[ "$unit" == *.service ]] || unit="${unit}.service"
  systemctl cat "$unit" >/dev/null 2>&1
}

user_unit_exists() {
  local unit="$1"
  [[ "$unit" == *.service ]] || unit="${unit}.service"
  systemctl --user cat "$unit" >/dev/null 2>&1
}

svc_enable_now() {
  local unit="$1"
  local u="$unit"
  [[ "$u" == *.service ]] || u="${u}.service"

  if ! sys_unit_exists "$u"; then
    warn "Service no existe (system): $u (saltando)"
    return 0
  fi

  if have_sudo; then
    sudo systemctl enable --now "$u"
  else
    systemctl enable --now "$u"
  fi
  ok "Service habilitado: $u"
}

user_daemon_reload() {
  systemctl --user daemon-reload || warn "No se pudo recargar systemd --user"
}

user_svc_enable_now() {
  local unit="$1"
  local u="$unit"
  [[ "$u" == *.service ]] || u="${u}.service"

  if ! user_unit_exists "$u"; then
    warn "User service no disponible: $u (saltando)"
    return 0
  fi

  systemctl --user enable --now "$u"
  ok "User service habilitado: $u"
}

