#!/usr/bin/env python3
"""Qué colores de la paleta usa cada plantilla de Velure (~/.config/velure/config.toml),
juntando las de una misma app (gtk3 y gtk4, las de Firefox). Lo usa la guía de estilo.
Imprime JSON: {"apps": [{"app": "kitty", "files": [...], "roles": {"p_accent": 3, ...}}]}"""
import json
import os
import re
import tomllib

CONFIG = os.path.expanduser("~/.config/velure/config.toml")
# Nombre de la plantilla en config.toml -> app
APPS = {"gtk3": "GTK", "gtk3-colors": "GTK", "gtk4": "GTK", "icons": "Iconos", "zed": "Zed",
        "kitty": "kitty", "fish": "fish", "starship": "Starship", "fastfetch": "fastfetch",
        "eza": "eza", "tidal": "Tidal"}

with open(CONFIG, "rb") as f:
    templates = tomllib.load(f).get("templates", {})

apps = {}
for name, t in templates.items():
    app = APPS.get(name) or ("Firefox" if name.startswith("firefox") else name)
    path = os.path.expanduser(t.get("input_path", ""))
    try:
        text = open(path, encoding="utf-8").read()
    except OSError:
        continue
    a = apps.setdefault(app, {"app": app, "files": [], "roles": {}})
    if os.path.basename(path) not in a["files"]:
        a["files"].append(os.path.basename(path))
        for role in re.findall(r"colors\.([A-Za-z0-9_]+)", text):
            a["roles"][role] = a["roles"].get(role, 0) + 1

print(json.dumps({"apps": list(apps.values())}))
