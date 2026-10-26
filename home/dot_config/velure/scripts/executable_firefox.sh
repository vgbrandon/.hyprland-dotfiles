#!/bin/sh
# Lleva los colores de la paleta a los perfiles de Firefox en uso y activa la opción
# que permite usarlos (user.js):
# - Marco: copia el userChrome.css generado. Con el autoconfig de Velure (velure.cfg)
#   los colores se cargan en vivo y aquí solo queda la marca.
# - Páginas internas (nueva pestaña, ajustes…): el bloque de firefox-userContent.css al
#   principio de userContent.css, entre marcas (lo demás del archivo se respeta; el de
#   la translucidez, que pone translucent.sh al final, gana). Se ve al reiniciar Firefox.
css="$HOME/.cache/velure/firefox-userChrome.css"
pages="$HOME/.cache/velure/firefox-userContent.css"
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
        content="$dir/chrome/userContent.css"
        touch "$content"
        sed -i '/^\/\* velure-colors:start \*\//,/^\/\* velure-colors:end \*\//d' "$content"
        if [ -f "$pages" ]; then
            { echo '/* velure-colors:start */'
              cat "$pages"
              echo '/* velure-colors:end */'
              cat "$content"; } > "$content.tmp" && mv "$content.tmp" "$content"
        fi
        grep -qF "$pref" "$dir/user.js" 2>/dev/null || echo "$pref" >> "$dir/user.js"
    done
done
