#!/usr/bin/env bash
set -euo pipefail

# Se comprueba en cada "chezmoi apply" (no solo cuando cambia algo): si greetd no
# está activado, lo activa en lugar del gestor de inicio que hubiera.
# greetd en lugar del gestor que hubiera antes. Sin --now: el cambio se aplica al
# reiniciar, para no cortar la sesión en curso.
if command -v greetd >/dev/null 2>&1 && ! systemctl is-enabled --quiet greetd; then
  current="$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" .service)"
  if [ -n "$current" ] && [ "$current" != "display-manager" ] && [ "$current" != "greetd" ]; then
    sudo systemctl disable "$current"
  fi
  sudo systemctl enable greetd
  echo "[OK] greetd activado; se usará al reiniciar."
fi
