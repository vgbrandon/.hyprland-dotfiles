#!/usr/bin/env bash

# AUR DESHABILITADO TEMPORALMENTE
# Motivo: prevención de seguridad tras incidente.
# No se instalará nada proveniente de AUR hasta nuevo aviso.

install_yay() {
  if command -v yay >/dev/null 2>&1; then
    return
  fi

  echo "[INFO] Instalando yay..."

  tmp_dir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"

  cd "$tmp_dir/yay"
  makepkg --noconfirm

  sudo pacman -U --noconfirm *.pkg.tar.zst

  cd -
  rm -rf "$tmp_dir"

  echo "[OK] yay instalado."
}

install_aur_packages() {
  local packages=("$@")

  if [ ${#packages[@]} -eq 0 ]; then
    return
  fi

  echo "[WARN] AUR está deshabilitado por seguridad. Saltando instalación de: ${packages[*]}"
  echo "[WARN] Motivo: prevención tras incidente de seguridad."

  # install_yay
  # sudo -v
  # yay -S --needed --noconfirm "${packages[@]}"
}
