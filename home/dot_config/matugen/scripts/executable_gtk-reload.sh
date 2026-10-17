#!/bin/sh
# Hace que las apps GTK abiertas recarguen el tema "Matugen" recién generado.
# GTK solo relee un tema cuando cambia su nombre, así que hay una copia gemela
# ("Matugen-Alt"): se copia ahí lo nuevo y se salta de uno a otro. Las dos tienen
# siempre lo último, así que nunca se ve un tema por defecto entre medias.
#   gtk-reload.sh gtk    → tema GTK3 (~/.local/share/themes)
#   gtk-reload.sh icons  → tema de iconos (~/.local/share/icons)
set -eu

case "${1:-}" in
    gtk) dir="$HOME/.local/share/themes"; key=gtk-theme ;;
    icons) dir="$HOME/.local/share/icons"; key=icon-theme ;;
    *) echo "uso: $0 gtk|icons" >&2; exit 1 ;;
esac

rm -rf "${dir:?}/Matugen-Alt"
cp -r "$dir/Matugen" "$dir/Matugen-Alt"

current=$(gsettings get org.gnome.desktop.interface "$key")
if [ "$current" = "'Matugen'" ]; then
    gsettings set org.gnome.desktop.interface "$key" Matugen-Alt
else
    gsettings set org.gnome.desktop.interface "$key" Matugen
fi
