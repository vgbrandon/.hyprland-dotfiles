#!/bin/sh
# Starship no permite "include": se une tu starship.toml con la paleta que genera
# matugen en starship-matugen.toml (fish usa ese archivo si existe).
# Con --notify (lo usa matugen) además avisa a las terminales fish abiertas para
# que repinten el prompt con los colores nuevos.
dir="$HOME/.config/starship"
[ -f "$dir/palette-matugen.toml" ] || exit 0
{
    sed 's/^palette = .*/palette = "matugen"/' "$dir/starship.toml"
    echo
    cat "$dir/palette-matugen.toml"
} > "$dir/starship-matugen.toml.tmp" && mv "$dir/starship-matugen.toml.tmp" "$dir/starship-matugen.toml"

[ "$1" = "--notify" ] || exit 0
# Cada fish interactivo registra su PID aquí (ver config.fish)
for f in "${XDG_RUNTIME_DIR:-/tmp}"/matugen-fish/*; do
    [ -e "$f" ] || continue
    pid=$(basename "$f")
    if [ "$(cat /proc/"$pid"/comm 2>/dev/null)" = fish ]; then
        kill -USR1 "$pid"
    else
        rm -f "$f" # terminal ya cerrada
    fi
done
