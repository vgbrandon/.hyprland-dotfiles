#!/bin/bash

PACKAGES_FILE="packages.txt"

if [ ! -f "$PACKAGES_FILE" ]; then
    echo "Error: No se encontró el archivo $PACKAGES_FILE"
    exit 1
fi

echo "=== Instalando paquetes del sistema ==="
echo "Leyendo paquetes desde: $PACKAGES_FILE"

# Filtrar comentarios y líneas vacías, crear lista de paquetes
packages=$(grep -v '^#' "$PACKAGES_FILE" | grep -v '^$' | tr '\n' ' ')

echo "Paquetes a instalar: $(echo $packages | wc -w)"
echo ""

sudo pacman -S --noconfirm --needed $packages

echo "=== Instalación completada ==="
