import pathlib
from typing import Tuple, List, Dict, Optional
from installer.logger import logger
from installer.helpers import get_home, confirm_action, run_cmd

# Configuración
EXCLUDED_ITEMS = {'.git', '.gitignore', '.stow-local-ignore', 'installer', 'install.py'}
BACKUP_SUFFIX = ".bak"
MAX_BACKUP_ATTEMPTS = 100

def validate_paths(dotfiles_root: pathlib.Path, target_dir: pathlib.Path) -> bool:
    """Valida las rutas esenciales"""
    if not dotfiles_root.exists():
        logger.print_error(f"Directorio de dotfiles no encontrado: {dotfiles_root}")
        return False
    if not dotfiles_root.is_dir():
        logger.print_error(f"No es un directorio: {dotfiles_root}")
        return False
    if not target_dir.exists():
        logger.print_error(f"Directorio destino no encontrado: {target_dir}")
        return False
    return True

def scan_conflicts(source: pathlib.Path, target: pathlib.Path) -> Tuple[List[Dict], List[Dict]]:
    """Escanea conflictos en la estructura de archivos"""
    file_conflicts = []
    symlink_conflicts = []

    for item in source.iterdir():
        if item.name in EXCLUDED_ITEMS:
            continue

        target_item = target / item.name
        if not target_item.exists():
            continue

        if target_item.is_symlink():
            try:
                if target_item.resolve() != item.resolve():
                    symlink_conflicts.append({
                        'target': target_item,
                        'source': item,
                        'current_target': target_item.resolve()
                    })
            except Exception as e:
                logger.print_warning(f"Error resolviendo symlink {target_item}: {str(e)}")
        elif target_item.is_dir():
            # Procesar directorios recursivamente
            sub_files, sub_symlinks = scan_conflicts(item, target_item)
            file_conflicts.extend(sub_files)
            symlink_conflicts.extend(sub_symlinks)
        else:
            file_conflicts.append({
                'target': target_item,
                'source': item
            })

    return file_conflicts, symlink_conflicts

def create_unique_backup(target: pathlib.Path) -> Optional[pathlib.Path]:
    """Crea un nombre de backup único"""
    base_backup = target.with_name(f"{target.name}{BACKUP_SUFFIX}")
    if not base_backup.exists():
        return base_backup

    for i in range(1, MAX_BACKUP_ATTEMPTS):
        unique_backup = target.with_name(f"{target.name}{BACKUP_SUFFIX}.{i}")
        if not unique_backup.exists():
            return unique_backup
    
    logger.print_error(f"No se pudo crear backup único para {target}")
    return None

def resolve_conflicts(conflicts: List[Dict], conflict_type: str):
    """Resuelve conflictos de archivos o symlinks"""
    if not conflicts:
        return True
    
    logger.print_warning(f"\nSe encontraron {len(conflicts)} conflictos de {conflict_type}:")
    for conflict in conflicts:
        logger.print_info(f"  - {conflict['target']}")
    
    if not confirm_action("¿Desea resolver estos conflictos automáticamente?"):
        return False
    
    for conflict in conflicts:
        target = conflict['target']
        try:
            backup_path = create_unique_backup(target)
            if backup_path:
                target.rename(backup_path)
                logger.print_success(f"Backup creado: {target} -> {backup_path}")
            else:
                logger.print_warning(f"No se pudo crear backup para {target}")
        except Exception as e:
            logger.print_error(f"Error procesando {target}: {str(e)}")
            return False
    
    return True

def prepare_for_stow(dotfiles_root: str, target_dir: str) -> Tuple[bool, str]:
    """Prepara el sistema para la implementación con stow"""
    try:
        dotfiles = pathlib.Path(dotfiles_root)
        target = pathlib.Path(target_dir)
        
        if not validate_paths(dotfiles, target):
            return False, "Error de validación en rutas"
        
        logger.print_info("Buscando conflictos...")
        file_conflicts, symlink_conflicts = scan_conflicts(dotfiles, target)
        
        if not file_conflicts and not symlink_conflicts:
            return True, "✅ Sistema listo para stow - Sin conflictos"
        
        # Resolver conflictos de archivos
        if file_conflicts:
            if not resolve_conflicts(file_conflicts, "archivos"):
                return False, "Resolución de conflictos cancelada"
        
        # Resolver conflictos de symlinks
        if symlink_conflicts:
            if not resolve_conflicts(symlink_conflicts, "symlinks"):
                return False, "Resolución de conflictos cancelada"
        
        return True, "✅ Sistema preparado - Conflictos resueltos"
    except Exception as e:
        logger.print_error(f"Error inesperado: {str(e)}")
        return False, f"Error: {str(e)}"

def get_stow_links(home_dir: pathlib.Path, dotfiles_dir: pathlib.Path) -> List[str]:
    """Obtiene los symlinks creados por stow, mostrando carpetas completas si son symlinks y archivos individuales si no"""
    links = []
    
    def format_path(path: pathlib.Path) -> str:
        """Formatea la ruta para mostrar ~ en lugar de la ruta completa del home"""
        try:
            # Para rutas dentro del home
            return "~/" + str(path.relative_to(home_dir))
        except ValueError:
            # Para rutas fuera del home
            return str(path)
    
    def is_stow_link(path: pathlib.Path, target: pathlib.Path) -> bool:
        """Determina si un path es un symlink que apunta al target específico"""
        if not path.is_symlink():
            return False
        try:
            return path.resolve() == target
        except:
            return False

    def process_dotfiles_item(dot_item: pathlib.Path):
        """Procesa un ítem en los dotfiles y verifica su equivalente en home"""
        # Saltar elementos excluidos
        if dot_item.name in EXCLUDED_ITEMS:
            return
            
        # Determinar la ruta equivalente en home
        home_path = home_dir / dot_item.relative_to(dotfiles_dir)
        
        # Si no existe en home, no es un symlink creado por stow
        if not home_path.exists():
            return
            
        # Si es un archivo en dotfiles
        if dot_item.is_file():
            # Verificar si el archivo en home es un symlink que apunta al archivo en dotfiles
            if is_stow_link(home_path, dot_item):
                links.append(f"{format_path(home_path)} -> {format_path(dot_item)}")
                
        # Si es un directorio en dotfiles
        elif dot_item.is_dir():
            # Verificar si el directorio completo en home es un symlink que apunta al directorio en dotfiles
            if is_stow_link(home_path, dot_item):
                # Mostrar solo el directorio padre
                links.append(f"{format_path(home_path)} -> {format_path(dot_item)}")
            else:
                # Si no es un symlink de directorio completo, procesar su contenido
                for child in dot_item.iterdir():
                    process_dotfiles_item(child)

    # Procesar todos los elementos en la raíz de los dotfiles
    for item in dotfiles_dir.iterdir():
        process_dotfiles_item(item)
    
    return sorted(links)

def deploy_with_stow(dotfiles_path: str) -> Tuple[bool, str]:
    """Ejecuta stow y muestra los symlinks con formato mejorado"""
    try:
        dotfiles_dir = pathlib.Path(dotfiles_path).resolve()
        home_dir = get_home()
        
        if not dotfiles_dir.exists():
            return False, f"Error: Directorio no encontrado {dotfiles_dir}"
        
        logger.print_header(f"Implementando dotfiles con stow")
        
        # Ejecutar stow
        returncode, _, stderr = run_cmd(
            ["stow", "--dotfiles", "-v2", "."],
            cwd=str(dotfiles_dir),
            capture=True
        )
        
        if returncode != 0:
            return False, f"❌ Error en stow:\n{stderr}"
        
        # Obtener los symlinks de primer nivel
        all_links = get_stow_links(home_dir, dotfiles_dir)
        
        # Preparar salida
        if all_links:
            output = "🔗 Symlinks configurados:\n"
            for link in all_links:
                output += f"  - {link}\n"
            output += f"\nℹ Total: {len(all_links)} symlinks"
        else:
            output = "ℹ No se encontraron symlinks configurados"
        
        return True, output
    except Exception as e:
        return False, f"❌ Error inesperado:\n{str(e)}"
