#!/bin/sh
# Lista los fondos de una carpeta y genera (una sola vez) una miniatura de cada
# uno en la caché, para que el selector no tenga que leer las imágenes originales.
# Uso: wallpaper-thumbs.sh <carpeta> <carpeta-de-caché>
# Salida: una línea por fondo: "<ruta>\t<miniatura>"
dir="$1"
cache="$2"
mkdir -p "$cache"

find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort |
while IFS= read -r f; do
    # La clave incluye la fecha de modificación: si la imagen cambia, se regenera
    key=$(printf '%s:%s' "$f" "$(stat -c %Y "$f")" | md5sum | cut -c1-32)
    thumb="$cache/$key.jpg"
    if [ ! -f "$thumb" ]; then
        vipsthumbnail "$f" --size 400x -o "$thumb[Q=85]" 2>/dev/null || thumb="$f"
    fi
    printf '%s\t%s\n' "$f" "$thumb"
done
