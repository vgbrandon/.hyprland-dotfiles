#!/bin/sh
# Copia el userChrome.css generado por paleta a los perfiles de Firefox en uso
# y activa la opción que permite usarlo (user.js). Los cambios de userChrome.css
# se ven al reiniciar Firefox. Con el autoconfig de Velure (velure.cfg) los colores
# se cargan en vivo y aquí solo queda la marca.
css="$HOME/.cache/velure/firefox-userChrome.css"
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
        # No pisar un userChrome.css propio (solo el generado lleva la marca "velure")
        if [ -f "$target" ] && ! head -n 3 "$target" | grep -q -E 'velure|matugen'; then
            echo "firefox.sh: $target no es de Velure, no se toca" >&2
            continue
        fi
        if [ -f /usr/lib/firefox/velure.cfg ]; then
            # Con el autoconfig de Velure los colores se cargan en vivo desde la caché
            # (velure.cfg): aquí solo la marca, para no competir con ellos
            printf '/*\n * velure: los colores los carga en vivo /usr/lib/firefox/velure.cfg\n */\n' > "$target"
        else
            cp "$css" "$target"
        fi
        grep -qF "$pref" "$dir/user.js" 2>/dev/null || echo "$pref" >> "$dir/user.js"
    done
done
