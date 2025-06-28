import logging
import sys
import re
from unicodedata import east_asian_width

# Configuración básica de logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

# Colores y formato
COLORS = {
    'RED': '\033[0;31m',
    'GREEN': '\033[0;32m',
    'YELLOW': '\033[1;33m',
    'BLUE': '\033[0;34m',
    'MAGENTA': '\033[0;35m',
    'CYAN': '\033[0;36m',
    'WHITE': '\033[1;37m',
    'GRAY': '\033[0;37m',
    'NC': '\033[0m',
    'BOLD': '\033[1m'
}

# Iconos
ICONS = {
    'INFO': "ℹ",
    'SUCCESS': "✓",
    'WARNING': "⚠",
    'ERROR': "✗",
    'QUESTION': "?",
    'CONFIG': "⚙",
    'INSTALL': "↓",
    'UPDATE': "↻",
    'CLEAN': "♺"
}

class EnhancedLogger:
    def print_info(self, msg):
        print(f"{COLORS['BLUE']}{ICONS['INFO']} {msg}{COLORS['NC']}")
    
    def print_success(self, msg):
        print(f"{COLORS['GREEN']}{ICONS['SUCCESS']} {msg}{COLORS['NC']}")
    
    def print_warning(self, msg):
        print(f"{COLORS['YELLOW']}{ICONS['WARNING']} {msg}{COLORS['NC']}")
    
    def print_error(self, msg, exit=False):
        print(f"{COLORS['RED']}{ICONS['ERROR']} {msg}{COLORS['NC']}")
        if exit:
            sys.exit(1)

# Añadimos los métodos que faltaban
    def print_question(self, msg):
        """Imprime una pregunta para el usuario"""
        print(f"{COLORS['MAGENTA']}{ICONS['QUESTION']} {msg}{COLORS['NC']}")
    
    def print_config(self, msg):
        """Imprime un mensaje de configuración"""
        print(f"{COLORS['CYAN']}{ICONS['CONFIG']} {msg}{COLORS['NC']}")
    
    def print_install(self, msg):
        """Imprime un mensaje de instalación"""
        print(f"{COLORS['GREEN']}{ICONS['INSTALL']} {msg}{COLORS['NC']}")
    
    def print_update(self, msg):
        """Imprime un mensaje de actualización"""
        print(f"{COLORS['BLUE']}{ICONS['UPDATE']} {msg}{COLORS['NC']}")
    
    def print_clean(self, msg):
        """Imprime un mensaje de limpieza"""
        print(f"{COLORS['GRAY']}{ICONS['CLEAN']} {msg}{COLORS['NC']}")

    def print_header(self, title, color='BLUE'):
        # Calcular el ancho visual real del título
        visible_width = self._get_visible_width(title)
        
        # Ajustar el ancho del banner
        box_width = visible_width + 4  # 2 espacios a cada lado
        
        # Crear las partes del banner
        top = f"{COLORS['BOLD']}{COLORS[color]}╔{'═' * box_width}╗{COLORS['NC']}"
        middle = f"{COLORS['BOLD']}{COLORS[color]}║{COLORS['NC']}  {title}  {COLORS['BOLD']}{COLORS[color]}║{COLORS['NC']}"
        bottom = f"{COLORS['BOLD']}{COLORS[color]}╚{'═' * box_width}╝{COLORS['NC']}"
        
        print(top)
        print(middle)
        print(bottom)
    
    def _get_visible_width(self, text):
        """Calcula el ancho visual real del texto, considerando caracteres de ancho completo"""
        # Remover códigos de color ANSI
        clean_text = re.sub(r'\033\[[0-9;]*m', '', text)
        
        width = 0
        for char in clean_text:
            # Determinar el ancho del carácter
            char_width = 2 if east_asian_width(char) in ('F', 'W') else 1
            width += char_width
        
        return width

# Instancia global para fácil acceso
logger = EnhancedLogger()
