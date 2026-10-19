#!/usr/bin/env python3
"""Qué escribe cada tecla en una distribución de teclado (para el módulo de teclado).

Uso: xkb-keys.py <distribución> [variante]
Compila la distribución con xkbcli y traduce los nombres de los símbolos a caracteres
con keysymdef.h. Imprime un JSON { "AE01": ["1", "!", "¡", ""], … }: por cada tecla,
lo que escribe sola, con Mayúsculas, con AltGr y con AltGr + Mayúsculas ("" = nada).
"""
import json
import re
import subprocess
import sys

KEYSYMDEF = "/usr/include/X11/keysymdef.h"

# Teclas muertas: el acento que añaden
DEAD = {
    "grave": "`", "acute": "´", "circumflex": "^", "tilde": "~", "macron": "¯",
    "breve": "˘", "abovedot": "˙", "diaeresis": "¨", "abovering": "˚", "doubleacute": "˝",
    "caron": "ˇ", "cedilla": "¸", "ogonek": "˛", "iota": "ͺ", "belowdot": ".",
    "hook": "̉", "horn": "̛", "stroke": "/", "currency": "¤", "greek": "µ",
}


def keysym_table():
    """Nombre del símbolo -> carácter. Los alias (p. ej. masculine) toman el carácter de
    otro nombre con el mismo valor; Latin-1 y los 0x01xxxxxx son el propio código."""
    values, chars = {}, {}
    pat = re.compile(r"#define XK_(\w+)\s+0x([0-9a-fA-F]+)(?:\s*/\*\s*U\+([0-9A-Fa-f]{4,6}))?")
    try:
        with open(KEYSYMDEF, errors="replace") as f:
            for line in f:
                m = pat.search(line)
                if not m:
                    continue
                value = int(m.group(2), 16)
                values.setdefault(m.group(1), value)
                if m.group(3):
                    chars.setdefault(value, chr(int(m.group(3), 16)))
    except OSError:
        pass
    table = {}
    for name, value in values.items():
        if value in chars:
            table[name] = chars[value]
        elif 0x20 <= value < 0x100:
            table[name] = chr(value)
        elif value >= 0x1000000:
            table[name] = chr(value - 0x1000000)
    return table


def to_char(name, table):
    if name in ("NoSymbol", "VoidSymbol"):
        return ""
    if len(name) == 1:
        return name
    if re.fullmatch(r"U[0-9A-Fa-f]{4,6}", name):
        return chr(int(name[1:], 16))
    if name.startswith("dead_"):
        return DEAD.get(name[5:], "◌")
    if name in table:
        return table[name]
    return ""


def main():
    layout = sys.argv[1] if len(sys.argv) > 1 else "us"
    variant = sys.argv[2] if len(sys.argv) > 2 else ""
    cmd = ["xkbcli", "compile-keymap", "--layout", layout]
    if variant:
        cmd += ["--variant", variant]
    text = subprocess.run(cmd, capture_output=True, text=True).stdout
    table = keysym_table()

    keys = {}
    for m in re.finditer(r"key\s+<(\w+)>\s*\{(.*?)\};", text, re.S):
        code, body = m.group(1), m.group(2)
        group = re.search(r"\[([^\]]*)\]", body)
        if not group:
            continue
        syms = [s.strip() for s in group.group(1).split(",")]
        chars = [to_char(s, table) for s in syms][:4]
        keys[code] = chars + [""] * (4 - len(chars))
    print(json.dumps(keys, ensure_ascii=False))


if __name__ == "__main__":
    main()
