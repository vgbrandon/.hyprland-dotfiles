#!/usr/bin/env python3
"""Genera la fuente de iconos propia de la shell (Velure Icons).

Los iconos que no trae la fuente de iconos (Material Design Icons de la Nerd Font),
como el logo de Bitwarden, se dibujan como letras de una fuente propia: así se ven
igual de nítidos que el resto. Como la Nerd Font, es TrueType con instrucciones de
ajuste a los píxeles (ttfautohint), así que se dibuja igual que ella.

Entrada: assets/icons/<nombre>.svg (en una caja de 24×24) y assets/icons/iconos.json:
  { "nombre": "código en hex" }
  o  { "nombre": { "code": "…", "px": 16 } }  /  { …, "grid": true }  /  { …, "scale": … }
Los códigos van en el área privada U+100000…, que la Nerd Font no usa.
  - px: 16 → dibujado píxel a píxel (lo mejor): viewBox 0 0 16 16, cada unidad es un
    píxel a 16 px, bordes rectos en números enteros, el dibujo con medidas pares y
    centrado en (8, 8). Ocupa la caja entera (1 em) y queda centrado y nítido en la barra.
  - grid: true → dibujado como los de Material Design Icons (rejilla de 24, trazo de 2),
    con su misma escala: 24 unidades = 1 em.
  - si no, el lado más largo mide 900 (de 1000) por "scale" (1 por defecto).
La línea de la fuente mide 1 em (875 / −125) y el centro de cada icono va en su centro
(375): a 16 px la línea mide 16 px justos, sin redondeos al centrarlo.
Salida: assets/fonts/VelureIcons.ttf (o la ruta que se pase; --sin-ajuste para no
añadir las instrucciones de ajuste a los píxeles).

Uso (sin instalar nada en el sistema):
  python -m venv ~/.cache/velure-icons-venv
  ~/.cache/velure-icons-venv/bin/pip install fonttools ttfautohint-py
  ~/.cache/velure-icons-venv/bin/python scripts/build-icons.py
Después, reiniciar Quickshell. En QML: Theme.i<Nombre>, p. ej. Theme.iBitwarden.
"""
import io
import json
import math
import os
import sys

import ttfautohint
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.recordingPen import RecordingPen
from fontTools.pens.reverseContourPen import ReverseContourPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import SVGPath

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONS = os.path.join(ROOT, "assets", "icons")
OUT = os.path.join(ROOT, "assets", "fonts", "VelureIcons.ttf")

UPEM = 1000
# La línea mide 1 em (875 arriba y 125 abajo): a 16 px, 16 px justos, así que Icon
# centra el icono en su caja sin redondeos en vertical
ASCENT, DESCENT = 875, -125
HEIGHT = 900                   # lado más largo de un icono (sin "grid" ni "px")
CENTER_Y = 375                 # centro de la línea, donde va el centro de cada icono
FAMILY = "Velure Icons"


def draw_icon(path, grid=False, scale=1.0, px=0):
    """Trazado del SVG, ya escalado y colocado. Devuelve (grabación, ancho)."""
    rec = RecordingPen()
    SVGPath(path).draw(rec)
    if px:
        # Dibujado píxel a píxel en una caja de px × px (viewBox 0 0 px px): la caja
        # entera es 1 em de ancho y su centro va en el centro de la línea. A ese tamaño
        # cada unidad es un píxel, así que los bordes enteros caen en píxeles enteros.
        s = UPEM / px
        out = RecordingPen()
        rec.replay(TransformPen(out, (s, 0, 0, -s, 0, CENTER_Y + px / 2 * s)))
        return out, UPEM
    bounds = BoundsPen(None)
    rec.replay(bounds)
    x0, y0, x1, y1 = bounds.bounds
    if grid:
        # Como Material Design Icons: 24 unidades de la rejilla = 1 em, centro en y = 12
        s = UPEM / 24 * scale
        cy = 12
    else:
        s = HEIGHT * scale / max(x1 - x0, y1 - y0)
        cy = (y0 + y1) / 2
    # Ancho entero que contiene todo el dibujo, con el dibujo centrado (si el trazo se
    # saliera aunque sea una fracción, Qt redondea el ancho y el icono queda desplazado)
    ink = (x1 - x0) * s
    width = math.ceil(ink)
    out = RecordingPen()
    # SVG tiene la y hacia abajo: se invierte y se centra en CENTER_Y
    rec.replay(TransformPen(out, (s, 0, 0, -s, -x0 * s + (width - ink) / 2, CENTER_Y + cy * s)))
    return out, width


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    out_path = args[0] if args else OUT
    hint = "--sin-ajuste" not in sys.argv
    with open(os.path.join(ICONS, "iconos.json")) as f:
        entries = json.load(f)
    opts = {n: e if isinstance(e, dict) else {"code": e} for n, e in entries.items()}
    codes = {n: int(o["code"], 16) for n, o in opts.items()}

    order = [".notdef"] + sorted(codes)
    glyphs = {".notdef": TTGlyphPen(None).glyph()}
    widths = {".notdef": 500}

    for name in sorted(codes):
        svg = os.path.join(ICONS, name + ".svg")
        if not os.path.exists(svg):
            sys.exit(f"Falta {svg}")
        rec, width = draw_icon(svg, opts[name].get("grid", False), opts[name].get("scale", 1.0), opts[name].get("px", 0))
        # TrueType: curvas cuadráticas y los contornos en el sentido contrario al de CFF
        pen = TTGlyphPen(None)
        rec.replay(ReverseContourPen(Cu2QuPen(pen, max_err=1)))
        glyphs[name] = pen.glyph()
        widths[name] = width

    fb = FontBuilder(UPEM, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap({code: name for name, code in codes.items()})
    fb.setupGlyf(glyphs)
    glyf = fb.font["glyf"]
    fb.setupHorizontalMetrics({n: (w, getattr(glyf[n], "xMin", 0)) for n, w in widths.items()})
    fb.setupHorizontalHeader(ascent=ASCENT, descent=DESCENT)
    fb.setupNameTable({"familyName": FAMILY, "styleName": "Regular"})
    fb.setupOS2(sTypoAscender=ASCENT, sTypoDescender=DESCENT, sTypoLineGap=0,
                usWinAscent=ASCENT, usWinDescent=-DESCENT)
    fb.setupPost()

    # Instrucciones de ajuste a los píxeles (como la Nerd Font)
    raw = io.BytesIO()
    fb.save(raw)
    data = raw.getvalue()
    if hint:
        data = ttfautohint.ttfautohint(in_buffer=data, symbol=True, no_info=True)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "wb") as f:
        f.write(data)
    print(f"{out_path}{'' if hint else ' (sin ajuste)'}: {', '.join(f'{n} U+{c:X}' for n, c in sorted(codes.items()))}")


if __name__ == "__main__":
    main()
