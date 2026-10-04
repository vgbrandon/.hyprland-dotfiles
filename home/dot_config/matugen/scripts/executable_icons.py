#!/usr/bin/env python3
"""Tema de iconos "Matugen": hereda Adwaita y recolorea las carpetas con el tono
del color principal del fondo (mantiene la luz y el sombreado de cada parte).
Lo ejecuta matugen al cambiar el fondo; el color lo deja la plantilla en .color."""
import colorsys, glob, os, re

src = "/usr/share/icons/Adwaita/scalable"
dst = os.path.expanduser("~/.local/share/icons/Matugen")
icons = [f"{src}/places/folder{s}.svg" for s in ["", "-documents", "-download", "-drag-accept",
         "-music", "-pictures", "-publicshare", "-remote", "-templates", "-videos"]]
icons += [f"{src}/places/user-home.svg", f"{src}/places/user-desktop.svg",
          f"{src}/mimetypes/inode-directory.svg"]

def hls(hexcolor):
    r, g, b = (int(hexcolor[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return colorsys.rgb_to_hls(r, g, b)

primary = open(f"{dst}/.color").read().strip().lstrip("#")
target_h, _, target_s = hls(primary)

def recolor(m):
    h, l, s = hls(m.group(1))
    # Solo los tonos azules saturados de la carpeta; grises y blancos se quedan
    if s < 0.25 or not (180 / 360 <= h <= 260 / 360):
        return m.group(0)
    r, g, b = colorsys.hls_to_rgb(target_h, l, min(s, max(target_s, 0.45)))
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))

for path in icons:
    if not os.path.exists(path):
        continue
    out = path.replace(src, f"{dst}/scalable")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    svg = re.sub(r"#([0-9a-fA-F]{6})\b", recolor, open(path).read())
    open(out, "w").write(svg)

open(f"{dst}/index.theme", "w").write("""[Icon Theme]
Name=Matugen
Comment=Adwaita con carpetas del color del fondo (generado por matugen)
Inherits=Adwaita,hicolor
Directories=scalable/places,scalable/mimetypes

[scalable/places]
Context=Places
Size=128
MinSize=8
MaxSize=512
Type=Scalable

[scalable/mimetypes]
Context=MimeTypes
Size=128
MinSize=8
MaxSize=512
Type=Scalable
""")
