#!/usr/bin/env bash
set -e

# ====================================================
# 🔧 CONFIGURACIÓN
# Cambia esta variable si quieres otra shell (zsh, bash, fish, etc.)
DEFAULT_SHELL="fish"
# ====================================================

# Buscar el ejecutable de la shell
SHELL_PATH="$(command -v "$DEFAULT_SHELL" || true)"

if [ -z "$SHELL_PATH" ]; then
    echo "❌ La shell '$DEFAULT_SHELL' no está instalada o no está en PATH."
    exit 1
fi

# Verificar si ya está en uso
if [ "$SHELL" = "$SHELL_PATH" ]; then
    echo "✅ Ya estás usando '$DEFAULT_SHELL' como shell por defecto."
    exit 0
fi

# Cambiar shell
echo "🔄 Cambiando shell por defecto a: $DEFAULT_SHELL ($SHELL_PATH)"
chsh -s "$SHELL_PATH"

echo "✅ Shell cambiada. Reinicie para aplicar los cambios."

