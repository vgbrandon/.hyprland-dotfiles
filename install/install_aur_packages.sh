#!/bin/bash

AUR_PACKAGES_FILE="aur_packages.txt"

if [ ! -f "$AUR_PACKAGES_FILE" ]; then
    echo "Error: No se encontró el archivo $AUR_PACKAGES_FILE"
    exit 1
fi

echo "=== Instalando paquetes del sistema ==="
echo "Leyendo paquetes desde: $AUR_PACKAGES_FILE"

# Filtrar comentarios y líneas vacías, crear lista de paquetes
aur_packages=$(grep -v '^#' "$AUR_PACKAGES_FILE" | grep -v '^$' | tr '\n' ' ')

echo "Paquetes a instalar: $(echo $aur_packages | wc -w)"
echo ""

sudo paru -S --noconfirm --needed $aur_packages

echo "=== Instalación completada ==="
