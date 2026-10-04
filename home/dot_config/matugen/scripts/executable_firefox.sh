#!/bin/sh
# Copia el userChrome.css generado por matugen a los perfiles de Firefox en uso
# y activa la opción que permite usarlo (user.js). Los cambios de userChrome.css
# se ven al reiniciar Firefox; en vivo los colores los aplica Pywalfox.
css="$HOME/.cache/matugen/firefox-userChrome.css"
[ -f "$css" ] || exit 0
pref='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'

for base in "$HOME/.config/mozilla/firefox" "$HOME/.mozilla/firefox"; do
    [ -f "$base/installs.ini" ] || continue
    # Perfil por defecto de cada instalación de Firefox
    grep '^Default=' "$base/installs.ini" | cut -d= -f2- | sort -u | while read -r profile; do
        dir="$base/$profile"
        [ -d "$dir" ] || continue
        mkdir -p "$dir/chrome"
        target="$dir/chrome/userChrome.css"
        # No pisar un userChrome.css propio (solo el generado lleva la marca "matugen")
        if [ -f "$target" ] && ! head -n 3 "$target" | grep -q matugen; then
            echo "firefox.sh: $target no es de matugen, no se toca" >&2
            continue
        fi
        cp "$css" "$target"
        grep -qF "$pref" "$dir/user.js" 2>/dev/null || echo "$pref" >> "$dir/user.js"
    done
done
