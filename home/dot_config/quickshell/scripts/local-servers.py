#!/usr/bin/env python3
"""Servidores locales: lo que escucha en puertos TCP (para el panel de Quickshell).

Imprime un JSON con una lista: [{ port, address, pid, name, cwd, project, command,
http }]. Solo procesos del usuario (ss solo muestra el proceso de los propios).
"http" dice si responde como servidor web (para ofrecer abrirlo en el navegador).
"""
import json
import os
import re
import subprocess
import urllib.request


def project_of(cwd):
    """Raíz del repositorio de git que contiene cwd (o cwd, si no hay)."""
    d = cwd
    while d and d != "/":
        if os.path.isdir(os.path.join(d, ".git")):
            return d
        d = os.path.dirname(d)
    return cwd


def is_http(port):
    try:
        req = urllib.request.Request(f"http://127.0.0.1:{port}/", method="HEAD")
        urllib.request.urlopen(req, timeout=0.4)
        return True
    except urllib.error.HTTPError:
        # Respondió con un error HTTP (404, 401…): es un servidor web
        return True
    except Exception:
        return False


def main():
    out = subprocess.run(["ss", "-ltnpH"], capture_output=True, text=True).stdout
    servers = {}
    for line in out.splitlines():
        cols = line.split()
        if len(cols) < 6:
            continue
        local = cols[3]
        m = re.search(r'\(\("([^"]+)",pid=(\d+)', line)
        if not m:
            continue
        address, _, port = local.rpartition(":")
        port = int(port)
        if port in servers:
            continue
        name, pid = m.group(1), int(m.group(2))
        try:
            cwd = os.readlink(f"/proc/{pid}/cwd")
            with open(f"/proc/{pid}/cmdline", "rb") as f:
                command = f.read().replace(b"\0", b" ").decode(errors="replace").strip()
        except OSError:
            cwd, command = "", name
        servers[port] = {
            "port": port,
            "address": address.strip("[]"),
            "pid": pid,
            "name": name,
            "cwd": cwd,
            "project": project_of(cwd) if cwd else "",
            "command": command,
            "http": is_http(port),
        }
    print(json.dumps(sorted(servers.values(), key=lambda s: s["port"])))


if __name__ == "__main__":
    main()
