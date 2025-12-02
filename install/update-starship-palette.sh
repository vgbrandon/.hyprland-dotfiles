#!/usr/bin/env bash

# ================================
# Actualiza la paleta pywal16 dentro de starship.toml
# ================================

WAL_PALETTE="$HOME/.cache/wal/starship-colors.toml"
STARSHIP_CONF="$HOME/.config/starship/starship.toml"
TMP_FILE="${STARSHIP_CONF}.tmp"

# --- Verificar existencia de archivos ---
if [[ ! -f "$WAL_PALETTE" ]]; then
    echo "❌ No se encontró la paleta generada por pywal16:"
    echo "   $WAL_PALETTE"
    exit 1
fi

if [[ ! -f "$STARSHIP_CONF" ]]; then
    echo "❌ No se encontró el archivo de configuración de Starship:"
    echo "   $STARSHIP_CONF"
    exit 1
fi

# --- Crear respaldo ---
cp "$STARSHIP_CONF" "${STARSHIP_CONF}.bak"

# --- Extraer contenido de la paleta nueva ---
PALETTE_CONTENT=$(awk '/\[palettes\.pywal16\]/,/^\s*$/' "$WAL_PALETTE")

if [[ -z "$PALETTE_CONTENT" ]]; then
    echo "❌ No se pudo extraer la paleta desde $WAL_PALETTE"
    exit 1
fi

# --- Comprobar si ya existe una sección [palettes.pywal16] ---
if grep -q "^\[palettes\.pywal16\]" "$STARSHIP_CONF"; then
    # Reemplazar el bloque existente (hasta la siguiente sección o fin del archivo)
    awk -v newblock="$PALETTE_CONTENT" '
        BEGIN {inblock=0}
        /^\[palettes\.pywal16\]/ {
            print newblock
            inblock=1
            next
        }
        /^\[/ && inblock {inblock=0}
        !inblock
    ' "$STARSHIP_CONF" > "$TMP_FILE"
else
    # Si no existe, lo añadimos al final
    echo "" >> "$STARSHIP_CONF"
    echo "$PALETTE_CONTENT" >> "$STARSHIP_CONF"
    cp "$STARSHIP_CONF" "$TMP_FILE"
fi

# --- Sustituir el archivo original ---
mv "$TMP_FILE" "$STARSHIP_CONF"

#  "✅ Paleta pywal16 actualizada correctamente en:"
#  "   $STARSHIP_CONF"
