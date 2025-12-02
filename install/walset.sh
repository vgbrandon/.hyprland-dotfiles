#!/bin/bash

if [ -z "$1" ]; then
    echo "Uso: walset <imagen>"
    exit 1
fi

# Verificar que el archivo existe
if [ ! -f "$1" ]; then
    echo "Error: El archivo '$1' no existe"
    exit 1
fi

# Asegurar que swww-daemon está corriendo en el display correcto
if ! pgrep -x "swww-daemon" > /dev/null; then
    echo "Iniciando swww-daemon..."
    swww-daemon --no-cache &
    # solo esperar lo justo (no 5s fijos)
    sleep 1
fi

# Cambiar wallpaper con transición
swww img "$1" \
    --transition-type grow \
    --transition-fps 60 \
    --transition-step 120 \
    --transition-duration 2

# Generar colores con pywal16/matugen (sin setear wallpaper)
# wal -i "$1" --cols16 darken -n -q
wal -i "$1" --cols16 lighten -n -q

# Actualizar colors tmux
#./update-tmux-colors.sh
tmux source-file ~/.config/tmux/tmux.conf

# update Starship
./update-starship-palette.sh

# Limpiando la terminal
clear

# "Actualizando paleta en Neovim..."
pkill -USR1 -x nvim 2>/dev/null || true

# Mostrar el nuevo esquema de colores con fastfetch
fastfetch

