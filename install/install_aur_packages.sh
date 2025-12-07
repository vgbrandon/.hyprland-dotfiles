#!/bin/bash

AUR_PACKAGES_FILE="$HOME/.hyprland-dotfiles/install/aur_packages.txt"

# ------------------------------------------------------------------------------
# 1. Validar archivo
# ------------------------------------------------------------------------------
if [ ! -f "$AUR_PACKAGES_FILE" ]; then
    echo "Error: No se encontró el archivo $AUR_PACKAGES_FILE"
    exit 1
fi

echo "=== Instalando paquetes del sistema ==="
echo "Leyendo paquetes desde: $AUR_PACKAGES_FILE"

# Filtrar comentarios y líneas vacías
aur_packages=$(grep -vE '^\s*#' "$AUR_PACKAGES_FILE" | grep -vE '^\s*$')
if [ -z "$aur_packages" ]; then
    echo "No hay paquetes para instalar."
    exit 0
fi

aur_packages=$(echo "$aur_packages" | tr '\n' ' ')
echo "Paquetes a instalar: $(echo $aur_packages | wc -w)"
echo ""

# ------------------------------------------------------------------------------
# 2. Detectar dinámicamente manejadores de paquetes (AUR helpers)
# ------------------------------------------------------------------------------

detect_dynamic_helpers() {
    local helpers=()

    # Buscar ejecutables en PATH que soporten la opción -S
    while IFS= read -r cmd; do
        if "$cmd" -S --help >/dev/null 2>&1 || "$cmd" --help 2>&1 | grep -q "\-S"; then
            # Excluir pacman (solo queremos AUR helpers)
            if [[ "$cmd" != *"pacman"* ]]; then
                helpers+=("$cmd")
            fi
        fi
    done < <(compgen -c | sort -u)

    # Retornar helpers encontrados
    if [ ${#helpers[@]} -gt 0 ]; then
        printf '%s\n' "${helpers[@]}"
        return 0
    fi

    return 1
}

# Obtener helpers dinámicos
mapfile -t dynamic_helpers < <(detect_dynamic_helpers)

# Si no hay helpers, mostrar mensaje y salir
if [ ${#dynamic_helpers[@]} -eq 0 ]; then
    echo "No se encontró ningún AUR helper instalado. Por favor instala uno primero (paru, yay, trizen, etc.)."
    exit 1
fi

# Elegir el primero disponible
helper="${dynamic_helpers[0]}"
echo "Helper detectado: $helper"
echo ""

# ------------------------------------------------------------------------------
# 3. Instalar paquetes usando el helper detectado
# ------------------------------------------------------------------------------

"$helper" -S --needed --noconfirm $aur_packages

echo ""
echo "=== Instalación completada ==="
