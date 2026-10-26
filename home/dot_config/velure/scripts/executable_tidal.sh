#!/bin/sh
# tidal-hifi solo aplica su tema al cargar la página: si está abierto, se le
# manda Ctrl+R por Hyprland (aunque esté en segundo plano) para que recargue
# con los colores nuevos. Corta la canción que esté sonando.
pgrep -x tidal-hifi >/dev/null || exit 0
if hyprctl eval 'return 1' >/dev/null 2>&1; then
    hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL", key = "R", window = "class:tidal-hifi" })' >/dev/null
else
    hyprctl dispatch sendshortcut CTRL,R,class:tidal-hifi >/dev/null
fi
