#!/usr/bin/env bash
# Crea un sticker de WhatsApp (WebP de 512 × 512) con lo que se ve en el editor de
# stickers (modules/stickers): la imagen, GIF o video escalado y colocado en el cuadrado
# (fuera del cuadrado se recorta; lo que no cubre queda transparente) y encima la capa de
# textos (un PNG de 512 × 512 con transparencia que guarda el editor).
# Baja la calidad (y en los animados los fotogramas por segundo) hasta que el archivo
# cumple los límites de WhatsApp: 100 KB los estáticos y 500 KB los animados.
#
#   sticker-export.sh static|anim ORIGEN ANCHO ALTO X Y CAPA.png SALIDA.webp [INICIO DURACION]
#
# ANCHO y ALTO: tamaño de la imagen en el lienzo; X e Y: su esquina (pueden ser negativos).
# Escribe en la salida estándar «ok TAMAÑO CALIDAD FPS» o «error MENSAJE».
set -u

kind=$1 src=$2 w=$3 h=$4 x=$5 y=$6 overlay=$7 out=$8
start=${9:-0} dur=${10:-0}
[ -f "$src" ] || { echo "error no existe el origen"; exit 1; }
[ -f "$overlay" ] || { echo "error falta la capa de textos"; exit 1; }
mkdir -p "$(dirname "$out")"
tmp="${TMPDIR:-/tmp}/sticker-$$.webp"

# El cuadrado transparente, la imagen encima en su sitio y los textos encima de todo
grafo() { # $1 = fps (vacío en los estáticos)
    local f=""
    [ -n "$1" ] && f="fps=$1,"
    echo "color=c=0x00000000:s=512x512${1:+:r=$1},format=rgba[fondo];[0:v]${f}scale=$w:$h:flags=lanczos,format=rgba[img];[fondo][img]overlay=$x:$y:shortest=1:format=auto[base];[base][1:v]overlay=0:0:shortest=1:format=auto"
}

if [ "$kind" = static ]; then
    limite=$((100 * 1024))
    for q in 90 80 70 60 50 40 30 20; do
        ffmpeg -v error -y -i "$src" -i "$overlay" -filter_complex "$(grafo "")" \
            -frames:v 1 -c:v libwebp -quality "$q" -compression_level 6 "$tmp" || { echo "error ffmpeg no pudo crear el sticker"; rm -f "$tmp"; exit 1; }
        size=$(stat -c %s "$tmp")
        if [ "$size" -le "$limite" ]; then
            mv -f "$tmp" "$out"
            echo "ok $size $q -"
            exit 0
        fi
    done
else
    limite=$((500 * 1024))
    for fps in 15 12 10; do
        for q in 70 60 50 40 30; do
            ffmpeg -v error -y -ss "$start" -t "$dur" -i "$src" -loop 1 -i "$overlay" \
                -filter_complex "$(grafo "$fps")" -an -c:v libwebp_anim -loop 0 \
                -quality "$q" -compression_level 4 "$tmp" || { echo "error ffmpeg no pudo crear el sticker"; rm -f "$tmp"; exit 1; }
            size=$(stat -c %s "$tmp")
            if [ "$size" -le "$limite" ]; then
                mv -f "$tmp" "$out"
                echo "ok $size $q $fps"
                exit 0
            fi
        done
    done
fi
rm -f "$tmp"
echo "error pesa demasiado aun con la calidad mínima: prueba con menos duración"
exit 1
