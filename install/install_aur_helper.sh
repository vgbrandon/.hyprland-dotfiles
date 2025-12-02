#!/bin/bash

set -e

echo "📦 Selección de AUR helper (yay o paru)"

# Detectar si alguno ya está instalado
YAY_EXISTS=$(command -v yay >/dev/null 2>&1 && echo "yes" || echo "no")
PARU_EXISTS=$(command -v paru >/dev/null 2>&1 && echo "yes" || echo "no")

echo
echo "Detectado:"
[ "$YAY_EXISTS" = "yes" ] && echo "  ✅ yay ya está instalado"
[ "$PARU_EXISTS" = "yes" ] && echo "  ✅ paru ya está instalado"
echo

# Elegir helper
read -rp "¿Qué helper de AUR quieres usar? (1) paru (2) yay [1]: " choice
choice=${choice:-1}

if [[ $choice == "1" ]]; then
    HELPER="paru"
elif [[ $choice == "2" ]]; then
    HELPER="yay"
else
    echo "❌ Opción inválida. Abortando."
    exit 1
fi

echo "Seleccionaste: $HELPER"

# Verificar si ya está instalado
if command -v "$HELPER" >/dev/null 2>&1; then
    read -rp "🔁 $HELPER ya está instalado. ¿Quieres reinstalarlo? (S/n): " reinstall
    reinstall=${reinstall:-n}

    if [[ "$reinstall" =~ ^[Ss]$ ]]; then
        echo "♻️ Reinstalando $HELPER..."
        rm -rf "/tmp/$HELPER"
    else
        echo "⏭️ Saltando reinstalación de $HELPER."
        exit 0
    fi
fi

# Instalar el helper seleccionado
echo "⬇️ Clonando $HELPER desde AUR..."
git clone "https://aur.archlinux.org/${HELPER}.git" "/tmp/${HELPER}"
cd "/tmp/${HELPER}" || exit 1
makepkg -si --noconfirm

echo "✅ $HELPER instalado correctamente."

