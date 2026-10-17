#!/usr/bin/env python3
"""Catálogo de distribuciones de teclado (para el módulo de teclado de Quickshell).

Lee /usr/share/X11/xkb/rules/evdev.xml e imprime un JSON con una lista de
{ layout, variant, name, short }: cada distribución y cada una de sus variantes
("variant" vacío = la distribución base), ordenadas por nombre.
"""
import json
import xml.etree.ElementTree as ET

RULES = "/usr/share/X11/xkb/rules/evdev.xml"
SYMBOLS = "/usr/share/X11/xkb/symbols"
_symbols = {}


def defines(layout, variant):
    """Si el archivo de símbolos de la distribución define esa variante."""
    if layout not in _symbols:
        try:
            _symbols[layout] = open(f"{SYMBOLS}/{layout}", errors="replace").read()
        except OSError:
            _symbols[layout] = ""
    return f'xkb_symbols "{variant}"' in _symbols[layout]


def text(item, tag):
    el = item.find(tag)
    return el.text.strip() if el is not None and el.text else ""


def main():
    root = ET.parse(RULES).getroot()
    out = []
    shorts = {}
    for l in root.iter("layout"):
        li = l.find("configItem")
        shorts[text(li, "name")] = text(li, "shortDescription") or text(li, "name")
    layouts = list(shorts)
    for layout in root.iter("layout"):
        item = layout.find("configItem")
        name = text(item, "name")
        short = text(item, "shortDescription") or name
        out.append({"layout": name, "variant": "", "name": text(item, "description"), "short": short})
        for variant in layout.iter("variant"):
            vitem = variant.find("configItem")
            vname = text(vitem, "name")
            # Variantes añadidas a mano (como Engrammer) a veces quedan en la lista de
            # otra distribución: se busca la que de verdad la define
            owner = name
            if not defines(name, vname):
                owner = next((l for l in layouts if defines(l, vname)), name)
            out.append({
                "layout": owner,
                "variant": vname,
                "name": text(vitem, "description"),
                "short": text(vitem, "shortDescription") or shorts.get(owner, owner),
            })
    out.sort(key=lambda e: e["name"].lower())
    print(json.dumps(out, ensure_ascii=False))


if __name__ == "__main__":
    main()
