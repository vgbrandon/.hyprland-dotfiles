#!/bin/sh
# Arranca el Hyprland de la pantalla de inicio (lo llama greetd como usuario "greeter").
# Ese usuario no tiene carpeta personal escribible: la caché y el estado van a su
# carpeta temporal de sesión.
runtime="${XDG_RUNTIME_DIR:-/tmp/greeter-$(id -u)}"
mkdir -p "$runtime"
export XDG_CACHE_HOME="$runtime/cache"
export XDG_STATE_HOME="$runtime/state"
export XDG_DATA_HOME="$runtime/data"
# Su salida (el logo en texto y el registro) va a un archivo: si no, se ve un
# instante en la consola antes de que aparezca la pantalla de inicio
exec start-hyprland -- --config /etc/greetd/hyprland.lua > "$runtime/hyprland.log" 2>&1
