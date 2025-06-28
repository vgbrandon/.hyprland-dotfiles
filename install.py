#!/usr/bin/env python3
import sys
import pathlib
from pathlib import Path
from installer.symlinks import prepare_for_stow, deploy_with_stow
from installer.packages import install_pacman_packages, install_aur_packages
from installer.postinstall import change_default_shell
from installer.logger import logger

def main():
    logger.print_header("⚡ Instalación de Dotfiles")
    
    try:
        # 1. Instalación de paquetes
        logger.print_header("📦 Instalando paquetes")
        pacman_file = Path("installer/data/pacman.txt")
        aur_file = Path("installer/data/aur.txt")
        
        install_pacman_packages(pacman_file)
        install_aur_packages(aur_file)
        
        # 2. Configuración de dotfiles
        logger.print_header("🔗 Configurando dotfiles")
        home = pathlib.Path.home()
        dotfiles = home / ".hyprland-dotfiles"
        
        # Preparar sistema para stow
        ready, message = prepare_for_stow(str(dotfiles), str(home))
        logger.print_info(message)
        
        if not ready:
            logger.print_error("No se puede continuar con la instalación")
            return
        
        # Implementar con stow
        success, output = deploy_with_stow(str(dotfiles))
        logger.print_info(output)
        
        if not success:
            logger.print_warning("Recomendación: Resuelva los conflictos manualmente")
            return
        
        # 3. Configuración post-instalación
        logger.print_header("🔧 Configuración post-instalación")
        if change_default_shell("zsh"):
            logger.print_success("Shell cambiado a zsh correctamente")
        else:
            logger.print_warning("No se pudo cambiar el shell predeterminado")
        
        logger.print_header("🎉 Instalación completada con éxito")
        
    except Exception as e:
        logger.print_error(f"Error crítico durante la instalación: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
