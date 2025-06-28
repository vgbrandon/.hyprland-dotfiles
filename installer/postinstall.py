import os
import pwd
import shutil
from pathlib import Path
from installer.logger import logger
from installer.helpers import run_cmd

def change_default_shell(shell: str) -> bool:
    """Cambia el shell predeterminado del usuario"""
    shell_path = shutil.which(shell)
    if not shell_path:
        logger.print_error(f"Shell no encontrado: {shell}")
        return False
    
    # Verificar si el shell está en /etc/shells
    etc_shells = Path("/etc/shells")
    if etc_shells.exists():
        with open(etc_shells) as f:
            valid_shells = [line.strip() for line in f if line.strip()]
        
        if shell_path not in valid_shells:
            logger.print_error(f"Shell no permitido: {shell_path}")
            return False
    
    # Obtener shell actual
    current_user = pwd.getpwuid(os.getuid())
    current_shell = current_user.pw_shell
    
    if current_shell == shell_path:
        logger.print_info(f"Shell ya está configurado: {shell}")
        return True
    
    # Cambiar shell
    logger.print_info(f"Cambiando shell a {shell}...")
    returncode, _, stderr = run_cmd(["chsh", "-s", shell_path])
    
    if returncode == 0:
        logger.print_success(f"Shell cambiado a {shell} correctamente")
        return True
    else:
        logger.print_error(f"Error cambiando shell: {stderr}")
        return False
