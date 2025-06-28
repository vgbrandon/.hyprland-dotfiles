import subprocess
import sys
import shutil
from pathlib import Path
from typing import List, Tuple, Optional
from installer.logger import logger

def run_cmd(cmd: List[str], 
            sudo: bool = False, 
            capture: bool = False,
            cwd: Optional[str] = None) -> Tuple[int, str, str]:
    """Ejecuta comandos mostrando progreso en tiempo real"""
    try:
        if sudo:
            cmd = ["sudo"] + cmd
        
        if capture:
            # Ejecutar y capturar salida para procesamiento posterior
            result = subprocess.run(
                cmd,
                check=False,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                cwd=cwd
            )
            return result.returncode, result.stdout, result.stderr
        else:
            # Mostrar salida en tiempo real
            # logger.print_info(f"Ejecutando: {' '.join(cmd)}")
            
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                cwd=cwd,
                bufsize=1,  # Buffering línea por línea
                universal_newlines=True
            )
            
            # Verificar que stdout no sea None antes de iterar
            if process.stdout is None:
                logger.print_warning("Advertencia: stdout es None, no se puede capturar salida")
                process.wait()
                return process.returncode, "", ""

            # Capturar y mostrar salida en tiempo real
            output_lines = []
            for line in process.stdout:
                sys.stdout.write(line)
                sys.stdout.flush()
                output_lines.append(line)
            
            process.wait()
            full_output = "".join(output_lines)
            return process.returncode, full_output, ""
    except Exception as e:
        logger.print_error(f"Error ejecutando comando: {' '.join(cmd)} - {str(e)}")
        return -1, "", str(e)

def read_packages(file_path: Path) -> list[str]:
    """Lee paquetes desde archivo ignorando comentarios y líneas vacías"""
    if not file_path.exists():
        logger.print_warning(f"Archivo de paquetes no encontrado: {file_path}")
        return []
    
    try:
        with open(file_path) as f:
            return [
                line.strip() 
                for line in f 
                if line.strip() and not line.startswith("#")
            ]
    except Exception as e:
        logger.print_error(f"Error leyendo paquetes: {str(e)}")
        return []

def is_installed(cmd: str) -> bool:
    """Verifica si un comando está disponible en el sistema"""
    return shutil.which(cmd) is not None

def get_home() -> Path:
    """Obtiene el directorio home del usuario"""
    return Path.home()

def confirm_action(prompt: str) -> bool:
    """Solicita confirmación al usuario"""
    logger.print_question(f"{prompt} [y/N]")
    try:
        response = input().strip().lower()
        return response in ("y", "yes")
    except KeyboardInterrupt:
        logger.print_error("Operación cancelada por el usuario")
        return False
