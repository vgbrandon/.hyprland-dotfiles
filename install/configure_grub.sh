#!/usr/bin/env bash
set -euo pipefail

GRUB_FILE="/etc/default/grub"
BACKUP_DIR="/etc/default"
TARGET_LINE="GRUB_DISABLE_OS_PROBER=false"
REQUIRED_PKGS=(os-prober ntfs-3g)

# --------------------------------------------------------
# Función: verificar paquetes requeridos
# --------------------------------------------------------
check_packages() {
    local missing=()
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Aviso: los siguientes paquetes no están instalados: ${missing[*]}"
        echo "Instálalos manualmente o agrégalos al script de instalación de paquetes."
    fi
}

# --------------------------------------------------------
# Función: ejecutar os-prober
# --------------------------------------------------------
run_os_prober() {
    if command -v os-prober &>/dev/null; then
        echo "Ejecutando os-prober..."
        if ! sudo os-prober; then
            echo "os-prober terminó con errores. Revisa manualmente."
        fi
    else
        echo "os-prober no está instalado. No se puede detectar otros sistemas operativos."
    fi
}

# --------------------------------------------------------
# Función: hacer backup del GRUB
# --------------------------------------------------------
backup_grub() {
    local backup_file="${BACKUP_DIR}/grub.bak.$(date +%F-%T)"
    if [ ! -f "$backup_file" ]; then
        echo "Creando backup de GRUB en $backup_file"
        sudo cp "$GRUB_FILE" "$backup_file"
    fi
}

# --------------------------------------------------------
# Función: configurar GRUB
# --------------------------------------------------------
configure_grub() {
    if grep -q "^$TARGET_LINE" "$GRUB_FILE"; then
        echo "La línea GRUB_DISABLE_OS_PROBER ya está presente y descomentada."
    elif grep -q "^#GRUB_DISABLE_OS_PROBER" "$GRUB_FILE"; then
        echo "Descomentando línea de OS Prober..."
        sudo sed -i "s|^#GRUB_DISABLE_OS_PROBER.*|$TARGET_LINE|" "$GRUB_FILE"
    else
        echo "Línea GRUB_DISABLE_OS_PROBER no encontrada. Agregando al final del archivo..."
        echo "$TARGET_LINE" | sudo tee -a "$GRUB_FILE" >/dev/null
    fi
}

# --------------------------------------------------------
# Función: regenerar GRUB
# --------------------------------------------------------
regenerate_grub() {
    if command -v grub-mkconfig &>/dev/null; then
        echo "Regenerando GRUB..."
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    else
        echo "Error: grub-mkconfig no está instalado. No se puede regenerar GRUB."
    fi
}

# --------------------------------------------------------
# Script principal
# --------------------------------------------------------
check_packages
run_os_prober
backup_grub
configure_grub
regenerate_grub

echo "Configuración de GRUB completada."
