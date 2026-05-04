#!/usr/bin/env bash

install_yay() {
  if command -v yay >/dev/null 2>&1; then
    return
  fi

  echo "[INFO] Instalando yay..."

  sudo pacman -S --needed git base-devel

  tmp_dir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"

  cd "$tmp_dir/yay"
  makepkg -s --noconfirm

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

  install_yay

  sudo -v

  yay -S --needed --noconfirm "${packages[@]}"
}
