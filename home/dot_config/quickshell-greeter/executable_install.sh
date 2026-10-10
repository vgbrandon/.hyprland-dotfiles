#!/usr/bin/env bash
set -euo pipefail

# Instala la pantalla de inicio de sesión en /etc/greetd (la ejecuta chezmoi cuando
# cambia algo; también se puede correr a mano). No activa greetd: de eso se encarga
# el script de chezmoi run_onchange_after_greetd.sh.

greeter="$HOME/.config/quickshell-greeter"
shell="$HOME/.config/quickshell"

if ! command -v greetd >/dev/null 2>&1; then
  echo "[WARN] greetd no está instalado. Saltando la pantalla de inicio."
  exit 0
fi

# Quickshell del greeter + componentes compartidos con la sesión normal
# (se borra antes para no dejar archivos de versiones anteriores)
sudo rm -rf /etc/greetd/quickshell
sudo install -d -m 755 /etc/greetd/quickshell
sudo install -m 644 "$greeter"/{shell,GreeterContent,Auth,Theme,Config}.qml /etc/greetd/quickshell/
sudo install -m 644 "$shell"/{Pill,Icon,Label}.qml /etc/greetd/quickshell/

# Hyprland del greeter (con los mismos monitores) y configuración de greetd
sudo install -m 755 "$greeter"/start-greeter.sh /etc/greetd/start-greeter.sh
sudo install -m 644 "$greeter"/hyprland.lua /etc/greetd/hyprland.lua
sudo install -m 644 "$HOME"/.config/hypr/monitors.lua /etc/greetd/monitors.lua
sudo install -m 644 "$greeter"/config.toml /etc/greetd/config.toml

# Carpeta donde la sesión deja fondo, colores y usuario para el greeter
sudo install -d -o "$(id -un)" -g "$(id -gn)" -m 755 /var/lib/qs-greeter

echo "[OK] Pantalla de inicio instalada en /etc/greetd."
