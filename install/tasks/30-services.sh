#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"

# libs
# shellcheck source=/dev/null
source "$REPO_ROOT/install/lib/log.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/install/lib/systemd.sh"

main() {
  info "Habilitando servicios (systemd)..."

  # ----- Servicios recomendados -----
  # Red (casi siempre)
  svc_enable_now "NetworkManager"

  # Bluetooth (si lo usas)
  svc_enable_now "bluetooth"

  # Time sync (solo uno suele usarse; Arch suele tener systemd-timesyncd)
  # svc_enable_now "systemd-timesyncd"

  # Printing (si tienes impresora)
  # svc_enable_now "cups"
  
  info "Recargando systemd --user..."
  user_daemon_reload

  # ----- User services (ejemplos) -----
  # Nota: solo aplica si tienes el service instalado y quieres que corra en tu sesión
  # Wallpaper daemon (Wayland)
  user_svc_enable_now "swww"
  # user_svc_enable_now "pipewire"
  # user_svc_enable_now "wireplumber"

  ok "Servicios: listo."
}

main "$@"

