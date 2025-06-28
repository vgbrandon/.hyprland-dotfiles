import os
import tempfile
from pathlib import Path
from installer.logger import logger
from installer import helpers

HELPER_AUR = "paru"

def install_pacman_packages(file_path: Path):
    """Instala todos los paquetes de pacman en un solo comando"""
    logger.print_header("Instalando paquetes desde pacman.txt")
    
    pkgs = helpers.read_packages(file_path)
    if not pkgs:
        logger.print_warning("No se encontraron paquetes para instalar")
        return
    
    # Instalar todos los paquetes juntos (más eficiente)
    cmd = ["pacman", "-S", "--noconfirm", "--needed"] + pkgs
    returncode, _, stderr = helpers.run_cmd(cmd, sudo=True, capture=False)
    
    if returncode == 0:
        logger.print_success(f"Paquetes instalados: {len(pkgs)}")
    else:
        logger.print_error(f"Error instalando paquetes: {returncode}")
        logger.print_error(f"Detalles: {stderr}")

def ensure_aur_helper_installed(helper_name: str) -> bool:
    """Instala el helper de AUR con visualización del progreso"""
    if helpers.is_installed(helper_name):
        logger.print_info(f"Helper AUR '{helper_name}' ya instalado")
        return True
    
    logger.print_header(f"Instalando helper AUR: {helper_name}")
    url = f"https://aur.archlinux.org/{helper_name}.git"
    
    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            # Clonar repositorio mostrando progreso
            logger.print_info("Clonando repositorio...")
            returncode, _, stderr = helpers.run_cmd(
                ["git", "clone", url, helper_name],
                cwd=tmpdir,
                capture=False
            )
            if returncode != 0:
                logger.print_error(f"Error clonando repositorio: {stderr}")
                return False
            
            pkg_dir = os.path.join(tmpdir, helper_name)
            
            # Construir e instalar mostrando progreso
            logger.print_info("Construyendo e instalando...")
            returncode, _, stderr = helpers.run_cmd(
                ["makepkg", "-si", "--noconfirm"],
                cwd=pkg_dir,
                capture=False
            )
            if returncode != 0:
                logger.print_error(f"Error construyendo paquete: {stderr}")
                return False
        
        logger.print_success(f"{helper_name} instalado correctamente")
        return True
    except Exception as e:
        logger.print_error(f"Error instalando helper AUR: {str(e)}")
        return False

def install_aur_packages(file_path: Path):
    """Instala paquetes de AUR mostrando progreso"""
    logger.print_header(f"Instalando paquetes AUR desde {file_path.name}")
    
    if not ensure_aur_helper_installed(HELPER_AUR):
        logger.print_error("No se puede continuar sin helper AUR")
        return
    
    pkgs = helpers.read_packages(file_path)
    if not pkgs:
        logger.print_warning("No se encontraron paquetes AUR para instalar")
        return
    
    # Instalar todos los paquetes juntos mostrando progreso
    cmd = [HELPER_AUR, "-S", "--noconfirm", "--needed"] + pkgs
    returncode, _, stderr = helpers.run_cmd(cmd, capture=False)
    
    if returncode == 0:
        logger.print_success(f"Paquetes AUR instalados: {len(pkgs)}")
    else:
        logger.print_error(f"Error instalando paquetes AUR. Código: {returncode}")
        logger.print_error(f"Detalles: {stderr}")
