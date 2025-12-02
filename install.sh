#!/bin/bash

DOTFILES_SETUP="$HOME/.hyprland-dotfiles/install"

cd ~
git clone https://github.com/vgbrandon/.hyprland-dotfiles.git

source $DOTFILES_SETUP/install_aur_helper.sh
source $DOTFILES_SETUP/install_pacman_packages.sh
source $DOTFILES_SETUP/install_aur_packages.sh
source $DOTFILES_SETUP/change_shell.sh

