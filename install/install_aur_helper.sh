#!/usr/bin/env bash
set -euo pipefail

echo "📦 Selección de AUR helper (yay, paru u otro)"

# ------------------------------------------------------------------------------
# 1. Detectar helpers conocidos ya instalados
# ------------------------------------------------------------------------------
declare -A helpers_installed
for h in paru yay; do
    if command -v "$h" >/dev/null 2>&1; then
        helpers_installed[$h]="yes"
    else
        helpers_installed[$h]="no"
    fi
done

echo "Detectado:"
for h in "${!helpers_installed[@]}"; do
    if [[ "${helpers_installed[$h]}" == "yes" ]]; then
        echo "  ✅ $h ya está instalado"
    fi
done
echo

# ------------------------------------------------------------------------------
# 2. Elegir helper (incluyendo opción “otro”)
# ------------------------------------------------------------------------------
while true; do
    echo "Opciones disponibles:"
    echo "  1) paru"
    echo "  2) yay"
    echo "  3) Otro"
    read -rp "Elige AUR helper [1]: " choice
    choice=${choice:-1}

    case "$choice" in
        1) HELPER="paru"; break ;;
        2) HELPER="yay"; break ;;
        3)
            read -rp "Escribe el nombre del helper que quieres instalar: " HELPER
            # Verificar si existe en AUR
            if ! curl -s "https://aur.archlinux.org/packages/$HELPER" | grep -q "<title>$HELPER"; then
                echo "❌ '$HELPER' no existe en AUR. Intenta otra vez."
            else
                break
            fi
            ;;
        *) echo "❌ Opción inválida. Intenta de nuevo." ;;
    esac
done

echo "Seleccionaste: $HELPER"

# ------------------------------------------------------------------------------
# 3. Instalar helper si no existe
# ------------------------------------------------------------------------------
if command -v "$HELPER" >/dev/null 2>&1; then
    echo "ℹ️ El helper '$HELPER' ya existe en el sistema. Se seguirá usando este helper."
else
    echo "⬇️ Instalando $HELPER desde AUR..."

    TMP_DIR="/tmp/$HELPER"
    if [[ -d "$TMP_DIR" ]]; then
        echo "🗑️ Eliminando carpeta temporal existente: $TMP_DIR"
        rm -rf "$TMP_DIR"
    fi

    git clone "https://aur.archlinux.org/${HELPER}.git" "$TMP_DIR"
    cd "$TMP_DIR" || { echo "❌ No se pudo acceder a $TMP_DIR"; exit 1; }
    makepkg -si --noconfirm
    cd - >/dev/null

    echo "✅ $HELPER instalado correctamente."

    # Limpiar carpeta temporal
    rm -rf "$TMP_DIR"
fi

# ------------------------------------------------------------------------------
# 4. Exportar variable para otros scripts
# ------------------------------------------------------------------------------
export AUR_HELPER="$HELPER"
echo "🟢 AUR_HELPER=$AUR_HELPER exportado para otros scripts."
