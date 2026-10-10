#!/usr/bin/env bash
set -euo pipefail

# Instala la pantalla de inicio de sesión en /etc/greetd (la ejecuta chezmoi cuando
# cambia algo; también se puede correr a mano). No activa greetd: eso se hace aparte
# con "sudo systemctl disable sddm && sudo systemctl enable greetd".

greeter="$HOME/.config/quickshell-greeter"
shell="$HOME/.config/quickshell"

if ! command -v greetd >/dev/null 2>&1; then
  echo "[WARN] greetd no está instalado. Saltando la pantalla de inicio."
  exit 0
fi

# Quickshell del greeter + componentes compartidos con la pantalla de bloqueo
sudo install -d -m 755 /etc/greetd/quickshell/shaders
sudo install -m 644 "$greeter"/{shell,GreeterContent,Auth,Theme}.qml /etc/greetd/quickshell/
sudo install -m 644 "$shell"/{GlassPanel,Icon,Label}.qml /etc/greetd/quickshell/
sudo install -m 644 "$shell"/shaders/glass.frag.qsb /etc/greetd/quickshell/shaders/

# Hyprland del greeter (con los mismos monitores) y configuración de greetd
sudo install -m 755 "$greeter"/start-greeter.sh /etc/greetd/start-greeter.sh
sudo install -m 644 "$greeter"/hyprland.lua /etc/greetd/hyprland.lua
sudo install -m 644 "$HOME"/.config/hypr/monitors.lua /etc/greetd/monitors.lua
sudo install -m 644 "$greeter"/config.toml /etc/greetd/config.toml

# Carpeta donde la sesión deja fondo, colores y usuario para el greeter
sudo install -d -o "$(id -un)" -g "$(id -gn)" -m 755 /var/lib/qs-greeter

echo "[OK] Pantalla de inicio instalada en /etc/greetd."
