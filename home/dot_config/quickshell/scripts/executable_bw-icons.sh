#!/bin/sh
# Iconos de las webs de la bóveda (módulo de Bitwarden), del servicio de iconos de
# Bitwarden (el mismo que usan sus apps). Se guardan en una carpeta de caché y solo se
# piden los que faltan.
# Uso: bw-icons.sh <carpeta> <dominio>…
# Deja <dominio>.png, o <dominio>.none si la web no tiene icono (el servicio devuelve uno
# genérico, que se reconoce comparándolo con el de un dominio que no existe). Si falla la
# red (o tarda más de 10 s) deja <dominio>.fail y no se reintenta hasta el día siguiente.
# Imprime primero los dominios que ya tenían icono y luego cada uno según llega.
dir=$1
shift
mkdir -p "$dir" || exit 1

[ -s "$dir/.default" ] || curl -sf -m 10 -o "$dir/.default" "https://icons.bitwarden.net/invalid.invalid/icon.png"

# Uno por dominio, hasta 8 a la vez (cada uno en su propio sh)
export dir
fetch='
    d=$1
    case $d in *[!a-z0-9.-]* | "") exit 0 ;; esac
    { [ -e "$dir/$d.png" ] || [ -e "$dir/$d.none" ]; } && exit 0
    [ -n "$(find "$dir/$d.fail" -mtime -1 2>/dev/null)" ] && exit 0
    tmp="$dir/$d.tmp"
    if curl -sf -m 10 -o "$tmp" "https://icons.bitwarden.net/$d/icon.png"; then
        if cmp -s "$tmp" "$dir/.default"; then
            rm -f "$tmp"
            touch "$dir/$d.none"
        else
            mv "$tmp" "$dir/$d.png"
            rm -f "$dir/$d.fail"
            echo "$d"
        fi
    else
        rm -f "$tmp"
        touch "$dir/$d.fail"
    fi'

for f in "$dir"/*.png; do
    [ -e "$f" ] && basename "$f" .png
done
printf '%s\n' "$@" | xargs -r -P 8 -I{} sh -c "$fetch" sh {}
