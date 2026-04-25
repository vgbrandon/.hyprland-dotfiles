#!/usr/bin/env bash

install_pacman_packages() {
  local packages=("$@")

  if [ ${#packages[@]} -eq 0 ]; then
    return
  fi

  sudo pacman -S --needed --noconfirm "${packages[@]}"
}
