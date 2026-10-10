#!/bin/sh
# Arranca el Hyprland de la pantalla de inicio (lo llama greetd como usuario "greeter").
# Ese usuario no tiene carpeta personal escribible: la caché y el estado van a su
# carpeta temporal de sesión.
runtime="${XDG_RUNTIME_DIR:-/tmp/greeter-$(id -u)}"
mkdir -p "$runtime"
export XDG_CACHE_HOME="$runtime/cache"
export XDG_STATE_HOME="$runtime/state"
export XDG_DATA_HOME="$runtime/data"
exec start-hyprland -- --config /etc/greetd/hyprland.lua
