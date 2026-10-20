#!/usr/bin/env python3
"""Genera la fuente de iconos propia de la shell (Prisma Icons).

Los iconos que no trae la fuente de iconos (Material Design Icons de la Nerd Font),
como el logo de Bitwarden, se dibujan como letras de una fuente propia: así se ven
igual de nítidos que el resto (el sistema los ajusta a los píxeles como el texto).

Entrada: assets/icons/<nombre>.svg (trazados en una caja de 24×24) y
assets/icons/iconos.json ({ "nombre": "código en hex" }, en el área privada U+100000…,
que la Nerd Font no usa). Salida: assets/fonts/PrismaIcons.otf.
Cada icono se escala para tener el mismo tamaño y la misma altura que los de la Nerd
Font (su lado más largo mide unos 900 en una fuente de 1000, centrado en y = 360).

Uso (necesita fonttools; sin instalarlo en el sistema):
  python -m venv ~/.cache/prisma-icons-venv && ~/.cache/prisma-icons-venv/bin/pip install fonttools
  ~/.cache/prisma-icons-venv/bin/python scripts/build-icons.py
Después, reiniciar Quickshell. En QML: Theme.i<Nombre>, p. ej. Theme.iBitwarden.
"""
import json
import os
import sys

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.recordingPen import RecordingPen
from fontTools.pens.t2CharStringPen import T2CharStringPen
from fontTools.pens.transformPen import TransformPen
from fontTools.svgLib.path import SVGPath

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONS = os.path.join(ROOT, "assets", "icons")
OUT = os.path.join(ROOT, "assets", "fonts", "PrismaIcons.otf")

UPEM = 1000
ASCENT, DESCENT = 1020, -300   # como la Nerd Font, para que la línea mida lo mismo
HEIGHT = 900                   # alto de un icono
CENTER_Y = 360                 # centro vertical de los iconos de la Nerd Font
FAMILY = "Prisma Icons"


def draw_icon(path):
    """Trazado del SVG, ya escalado y colocado. Devuelve (grabación, ancho)."""
    svg = SVGPath(path)
    rec = RecordingPen()
    svg.draw(rec)
    bounds = BoundsPen(None)
    rec.replay(bounds)
    x0, y0, x1, y1 = bounds.bounds
    # El lado más largo mide HEIGHT (los anchos, como dos interruptores, no se salen)
    s = HEIGHT / max(x1 - x0, y1 - y0)
    # SVG tiene la y hacia abajo: se invierte y se centra en CENTER_Y
    cy = (y0 + y1) / 2
    out = RecordingPen()
    rec.replay(TransformPen(out, (s, 0, 0, -s, -x0 * s, CENTER_Y + cy * s)))
    return out, round((x1 - x0) * s)


def main():
    with open(os.path.join(ICONS, "iconos.json")) as f:
        codes = {name: int(code, 16) for name, code in json.load(f).items()}

    order = [".notdef"] + sorted(codes)
    charstrings, metrics = {}, {}

    pen = T2CharStringPen(500, None)
    charstrings[".notdef"] = pen.getCharString()
    metrics[".notdef"] = (500, 0)

    for name in sorted(codes):
        svg = os.path.join(ICONS, name + ".svg")
        if not os.path.exists(svg):
            sys.exit(f"Falta {svg}")
        rec, width = draw_icon(svg)
        pen = T2CharStringPen(width, None)
        rec.replay(pen)
        charstrings[name] = pen.getCharString()
        metrics[name] = (width, 0)

    fb = FontBuilder(UPEM, isTTF=False)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap({code: name for name, code in codes.items()})
    fb.setupCFF(FAMILY.replace(" ", ""), {"FullName": FAMILY}, charstrings, {})
    fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=ASCENT, descent=DESCENT)
    fb.setupNameTable({"familyName": FAMILY, "styleName": "Regular"})
    fb.setupOS2(sTypoAscender=ASCENT, sTypoDescender=DESCENT, sTypoLineGap=0,
                usWinAscent=ASCENT, usWinDescent=-DESCENT)
    fb.setupPost()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    fb.save(OUT)
    print(f"{OUT}: {', '.join(f'{n} U+{c:X}' for n, c in sorted(codes.items()))}")


if __name__ == "__main__":
    main()
