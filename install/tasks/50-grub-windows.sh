#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"

# shellcheck source=/dev/null
source "$REPO_ROOT/install/lib/log.sh"

have() { command -v "$1" >/dev/null 2>&1; }

is_uefi() { [[ -d /sys/firmware/efi ]]; }

grub_installed() {
  # varias formas válidas según instalación
  have grub-mkconfig || have grub2-mkconfig || [[ -d /boot/grub ]] || [[ -d /boot/grub2 ]]
}

grub_cfg_path() {
  # Arch: /boot/grub/grub.cfg típico
  if [[ -d /boot/grub ]]; then
    echo "/boot/grub/grub.cfg"
    return 0
  fi
  if [[ -d /boot/grub2 ]]; then
    echo "/boot/grub2/grub.cfg"
    return 0
  fi
  # fallback
  echo "/boot/grub/grub.cfg"
}

enable_os_prober_if_possible() {
  local default_file="/etc/default/grub"
  [[ -f "$default_file" ]] || return 0

  # GRUB_DISABLE_OS_PROBER=false (si no existe, lo agrega)
  if grep -Eq '^\s*GRUB_DISABLE_OS_PROBER=' "$default_file"; then
    if grep -Eq '^\s*GRUB_DISABLE_OS_PROBER\s*=\s*true' "$default_file"; then
      sudo sed -i 's/^\s*GRUB_DISABLE_OS_PROBER\s*=\s*true/GRUB_DISABLE_OS_PROBER=false/' "$default_file"
      ok "GRUB: habilitado os-prober en /etc/default/grub"
    fi
  else
    echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a "$default_file" >/dev/null
    ok "GRUB: agregado GRUB_DISABLE_OS_PROBER=false en /etc/default/grub"
  fi
}

detect_windows_hint() {
  # 1) os-prober si existe
  if have os-prober; then
    if sudo os-prober | grep -qi 'Windows'; then
      return 0
    fi
  fi

  # 2) UEFI: buscar ejecutable típico
  if is_uefi; then
    # montajes comunes del ESP
    local esp=""
    for d in /boot/efi /efi /boot; do
      if mountpoint -q "$d" && [[ -d "$d/EFI" ]]; then
        esp="$d"
        break
      fi
    done

    if [[ -n "$esp" ]]; then
      if find "$esp/EFI" -maxdepth 3 -type f \( -iname 'bootmgfw.efi' -o -iname 'bootmgr.efi' \) 2>/dev/null | grep -q .; then
        return 0
      fi
    fi

    # 3) efibootmgr como último indicio
    if have efibootmgr; then
      if sudo efibootmgr 2>/dev/null | grep -qi 'Windows'; then
        return 0
      fi
    fi
  fi

  return 1
}

regen_grub_cfg() {
  local out
  out="$(grub_cfg_path)"

  if have grub-mkconfig; then
    info "GRUB: generando config -> $out"
    sudo grub-mkconfig -o "$out"
    return 0
  fi

  if have grub2-mkconfig; then
    info "GRUB: generando config -> $out"
    sudo grub2-mkconfig -o "$out"
    return 0
  fi

  die "GRUB: no encuentro grub-mkconfig ni grub2-mkconfig."
}

main() {
  info "GRUB: detección de GRUB + Windows..."

  if ! grub_installed; then
    warn "GRUB: no está instalado. Saltando (quizá usas systemd-boot/refind)."
    return 0
  fi

  # os-prober es el método estándar para detectar otros SO en GRUB
  if ! have os-prober; then
    warn "GRUB: 'os-prober' no está instalado. Sin él, GRUB puede no detectar Windows automáticamente."
    warn "GRUB: recomendado: sudo pacman -S os-prober"
  else
    enable_os_prober_if_possible
  fi

  if detect_windows_hint; then
    ok "GRUB: Windows parece estar presente. Regenerando grub.cfg..."
  else
    warn "GRUB: No pude confirmar Windows (puede estar, pero no detectado). Igual regeneraré grub.cfg."
    warn "GRUB: Revisa que tu partición EFI (ESP) esté montada (ej: /boot o /boot/efi) y que os-prober esté instalado."
  fi

  regen_grub_cfg
  ok "GRUB: listo."
}

main "$@"

