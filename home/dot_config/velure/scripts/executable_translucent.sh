#!/bin/sh
# Fondo translúcido en las apps que lo permiten (kitty, Zed, las apps GTK3 como Thunar
# y Firefox), con el texto nítido y el desenfoque de Hyprland detrás: la
# parte de las apps de "Barra y paneles translúcidos" de Quickshell (Ajustes →
# Apariencia).
#   translucent.sh on|off   lo guarda y lo aplica (lo llama Quickshell)
#   translucent.sh          vuelve a aplicar lo guardado (lo llama paleta al
#                           regenerar los temas de Zed y Firefox)
state="${XDG_STATE_HOME:-$HOME/.local/state}/velure/translucent"
# Opacidad del fondo de las apps: la misma que la barra de Quickshell (Mica, 88 %)
opacity=0.88
# La misma en hexadecimal, para los CSS de Firefox (paleta los genera con "e0")
alpha=$(awk "BEGIN { printf \"%02x\", $opacity * 255 + 0.5 }")

case "$1" in
    on|off) mkdir -p "$(dirname "$state")" && echo "$1" > "$state" ;;
esac
mode=$(cat "$state" 2>/dev/null || echo off)

# kitty: kitty.conf incluye translucent.conf; con SIGUSR1 las ventanas abiertas
# recargan la config (background_opacity necesita dynamic_background_opacity)
if [ "$mode" = on ]; then
    echo "background_opacity $opacity" > ~/.config/kitty/translucent.conf
else
    echo "background_opacity 1" > ~/.config/kitty/translucent.conf
fi
pkill -USR1 -x kitty 2>/dev/null

# GTK3 (Thunar y las demás apps con el tema "Velure"): el tema importa
# translucent.css. La ventana, transparente, y cada zona con su propio color del tema
# translúcido (barras, barra lateral, lista), para que se vea como siempre pero con el
# desenfoque detrás. gtk-reload.sh hace que las apps abiertas lo recarguen.
gtk="$HOME/.local/share/themes/Velure/gtk-3.0"
if [ -d "$gtk" ]; then
    if [ "$mode" = on ]; then
        cat > "$gtk/translucent.css" <<CSS
window.background, window.background:backdrop {
  background-color: transparent;
}
menubar, toolbar, .toolbar, statusbar, headerbar,
headerbar:backdrop {
  background-color: alpha(@window_bg_color, $opacity);
}
.sidebar, placessidebar, placessidebar list, .thunar .sidebar {
  background-color: alpha(@sidebar_bg_color, $opacity);
}
.view, iconview, treeview.view, .thunar .standard-view {
  background-color: alpha(@view_bg_color, $opacity);
}
scrolledwindow, viewport, notebook, notebook > stack:not(:only-child), paned {
  background-color: transparent;
}
/* El separador de la barra lateral asoma bajo la lista (si no, queda un hueco) */
paned > separator {
  background-color: alpha(@window_bg_color, $opacity);
}
CSS
    else
        : > "$gtk/translucent.css"
    fi
    sh ~/.config/velure/scripts/gtk-reload.sh gtk 2>/dev/null
fi

# Firefox: el marco (pestañas, barras y barra lateral) y la nueva pestaña, con los CSS
# que genera paleta con la paleta (templates/firefox-translucent*.css).
# - Marco: se copia a ~/.local/state/velure/firefox-translucent.css (vacío si está
#   apagado) y el autoconfig de Velure (velure.cfg) lo carga en vivo.
# - Nueva pestaña: al final de userContent.css entre marcas (ahí @import no se aplica);
#   se ve al reiniciar Firefox. allow_transparent_browser deja ver detrás de la página
#   y native-theme hace que use el tema GTK (sin él, Firefox pinta su propio tema
#   oscuro debajo de todo y no se ve lo de detrás). Se leen al arrancar Firefox.
mkdir -p "$(dirname "$state")"
if [ "$mode" = on ]; then
    sed "s/e0 !important/$alpha !important/g" "$HOME/.cache/velure/firefox-translucent.css" \
        > "$(dirname "$state")/firefox-translucent.css" 2>/dev/null
else
    : > "$(dirname "$state")/firefox-translucent.css"
fi
fxprefs='user_pref("browser.tabs.allow_transparent_browser", true);
user_pref("browser.theme.native-theme", true);'
for base in "$HOME/.config/mozilla/firefox" "$HOME/.mozilla/firefox"; do
    [ -f "$base/installs.ini" ] || continue
    grep '^Default=' "$base/installs.ini" | cut -d= -f2- | sort -u | while read -r profile; do
        dir="$base/$profile"
        [ -d "$dir" ] || continue
        mkdir -p "$dir/chrome"
        content="$dir/chrome/userContent.css"
        touch "$content"
        # Fuera el bloque anterior y lo de versiones viejas (@import y sus archivos)
        sed -i -e '/^\/\* velure-translucent:start \*\//,/^\/\* velure-translucent:end \*\//d' \
            -e '/^\/\* prisma-translucent:start \*\//,/^\/\* prisma-translucent:end \*\//d' \
            -e '/translucent-content.css/d' "$content"
        rm -f "${dir:?}/chrome/translucent-content.css" "${dir:?}/chrome/translucent.css"
        # (una versión anterior sacaba las pestañas de la barra de título; ya no hace falta)
        [ -f "$dir/user.js" ] && sed -i "/browser.tabs.inTitlebar/d" "$dir/user.js"
        if [ "$mode" = on ]; then
            if [ -f "$HOME/.cache/velure/firefox-translucent-content.css" ]; then
                { echo '/* velure-translucent:start */'
                  sed "s/e0 !important/$alpha !important/g" "$HOME/.cache/velure/firefox-translucent-content.css"
                  echo '/* velure-translucent:end */'; } >> "$content"
            fi
            echo "$fxprefs" | while read -r line; do
                grep -qF "$line" "$dir/user.js" 2>/dev/null || echo "$line" >> "$dir/user.js"
            done
        else
            [ -f "$dir/user.js" ] && sed -i -e "/browser.tabs.allow_transparent_browser/d" \
                -e "/browser.theme.native-theme/d" "$dir/user.js"
        fi
    done
done

# Zed: el tema Velure con la ventana transparente y desenfocada, y cada zona
# (editor, paneles, pestañas, barras) con su propio color translúcido, para que se vea
# como siempre. Zed recarga el tema al cambiar el archivo.
python3 - "$mode" "$opacity" "$(dirname "$state")/zed-opaque.json" <<'PY'
import json, os, sys
mode, opacity, saved = sys.argv[1], float(sys.argv[2]), sys.argv[3]
path = os.path.expanduser("~/.config/zed/themes/velure.json")
try:
    with open(path) as f:
        data = json.load(f)
except (OSError, ValueError):
    sys.exit(0)
layers = ["surface.background", "panel.background", "editor.background",
          "editor.gutter.background", "editor.subheader.background", "terminal.background",
          "title_bar.background", "title_bar.inactive_background", "toolbar.background",
          "tab_bar.background", "tab.active_background", "tab.inactive_background",
          "status_bar.background", "scrollbar.track.background"]
changed = False
for i, theme in enumerate(data.get("themes", [])):
    st = theme.setdefault("style", {})
    blurred = st.get("background.appearance") == "blurred"
    # Ya translúcido: se parte de los colores opacos guardados (por si cambió la opacidad)
    if mode == "on" and blurred:
        try:
            with open(saved) as f:
                st.update(json.load(f))
            blurred = False
        except (OSError, ValueError):
            pass
    if mode == "on" and not blurred:
        # Los colores opacos (recién generados por paleta) se guardan para volver
        orig = {k: st[k] for k in ["background"] + layers if k in st}
        os.makedirs(os.path.dirname(saved), exist_ok=True)
        with open(saved, "w") as f:
            json.dump(orig, f)
        alpha = "%02x" % round(opacity * 255)
        st["background"] = "#00000000"
        for key in layers:
            if key in st:
                st[key] = st[key][:7] + alpha
        st["background.appearance"] = "blurred"
        changed = True
    elif mode == "off" and blurred:
        try:
            with open(saved) as f:
                st.update(json.load(f))
        except (OSError, ValueError):
            pass
        st["background.appearance"] = "opaque"
        changed = True
if changed:
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
PY
