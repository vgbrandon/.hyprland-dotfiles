#!/usr/bin/env python3
"""Datos del panel del sistema de Quickshell (SystemPanel.qml).

Corre mientras el panel está abierto y cada INTERVAL segundos escribe una línea JSON:
temperatura y frecuencia de la CPU, gráfica (uso, VRAM, temperaturas), discos, red
(bytes acumulados; la velocidad la calcula Quickshell) y los procesos que más CPU
usan en ese momento.
"""

import glob
import json
import os
import subprocess
import sys
import time

INTERVAL = 2.0
TICKS = os.sysconf("SC_CLK_TCK")
PAGE = os.sysconf("SC_PAGE_SIZE")


def read(path, default=None):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return default


def read_int(path, default=0):
    value = read(path)
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def hwmon(name):
    """Carpeta hwmon de un sensor por su nombre (los números cambian al arrancar)."""
    for path in glob.glob("/sys/class/hwmon/hwmon*"):
        if read(f"{path}/name") == name:
            return path
    return None


def gpu_card():
    """La gráfica con más VRAM (la dedicada, si hay dos)."""
    best, best_vram = None, -1
    for card in glob.glob("/sys/class/drm/card[0-9]"):
        vram = read_int(f"{card}/device/mem_info_vram_total", -1)
        if vram > best_vram:
            best, best_vram = card, vram
    return best


def gpu_name(card):
    slot = os.path.basename(os.path.realpath(f"{card}/device"))
    try:
        out = subprocess.run(["lspci", "-mm", "-s", slot], capture_output=True, text=True).stdout
        # Campos entre comillas: clase, fabricante, dispositivo…
        fields = out.split('"')[1::2]
        name = fields[2] if len(fields) > 2 else ""
        # "Navi 44 [Radeon RX 9060 XT]" -> "Radeon RX 9060 XT"
        if "[" in name and "]" in name:
            name = name[name.index("[") + 1:name.index("]")]
        return name
    except OSError:
        return ""


def disks():
    out = []
    seen = set()
    with open("/proc/mounts") as f:
        for line in f:
            dev, mount, fstype = line.split()[:3]
            if not dev.startswith("/dev/") or dev in seen:
                continue
            if fstype in ("squashfs", "iso9660") or mount.startswith(("/snap", "/var/lib/docker")):
                continue
            seen.add(dev)
            try:
                st = os.statvfs(mount)
            except OSError:
                continue
            # Como df: usado = bloques ocupados (sin contar el espacio reservado a root)
            total = st.f_blocks * st.f_frsize
            used = (st.f_blocks - st.f_bfree) * st.f_frsize
            if total > 0:
                out.append({"mount": mount, "used": used, "total": total})
    return out


def net_bytes():
    rx = tx = 0
    with open("/proc/net/dev") as f:
        for line in f.readlines()[2:]:
            name, data = line.split(":", 1)
            if name.strip() == "lo":
                continue
            fields = data.split()
            rx += int(fields[0])
            tx += int(fields[8])
    return rx, tx


def proc_times():
    """Tiempo de CPU acumulado (en ticks), nombre y memoria de cada proceso."""
    out = {}
    for path in glob.glob("/proc/[0-9]*"):
        try:
            with open(f"{path}/stat") as f:
                data = f.read()
        except OSError:
            continue
        # El nombre va entre paréntesis y puede tener espacios
        name = data[data.index("(") + 1:data.rindex(")")]
        fields = data[data.rindex(")") + 2:].split()
        ticks = int(fields[11]) + int(fields[12])
        rss = int(fields[21]) * PAGE
        out[path] = (name, ticks, rss)
    return out


def main():
    card = gpu_card()
    gpu_hwmon = None
    if card:
        found = glob.glob(f"{card}/device/hwmon/hwmon*")
        gpu_hwmon = found[0] if found else None
    gpu = {"name": gpu_name(card) if card else ""}
    cpu_hwmon = hwmon("k10temp") or hwmon("coretemp")
    cpus = os.cpu_count() or 1

    previous = proc_times()
    last = time.monotonic()

    while True:
        time.sleep(INTERVAL)
        now = time.monotonic()
        elapsed = now - last
        last = now

        # Procesos: % de CPU en este intervalo (100 % = un hilo entero), sumando
        # los procesos con el mismo nombre (p. ej. las pestañas de Firefox)
        current = proc_times()
        usage = {}
        for path, (name, ticks, rss) in current.items():
            before = previous.get(path)
            delta = ticks - before[1] if before and before[0] == name else 0
            cpu, mem = usage.get(name, (0.0, 0))
            usage[name] = (cpu + delta / TICKS / elapsed * 100, mem + rss)
        previous = current
        top = sorted(usage.items(), key=lambda kv: kv[1][0], reverse=True)[:5]

        # Frecuencia media de los hilos
        freqs = [read_int(p) for p in glob.glob("/sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq")]

        if card:
            gpu.update({
                "busy": read_int(f"{card}/device/gpu_busy_percent"),
                "vramUsed": read_int(f"{card}/device/mem_info_vram_used"),
                "vramTotal": read_int(f"{card}/device/mem_info_vram_total"),
                "temp": read_int(f"{gpu_hwmon}/temp1_input") / 1000 if gpu_hwmon else None,
                "hotspot": read_int(f"{gpu_hwmon}/temp2_input") / 1000 if gpu_hwmon and os.path.exists(f"{gpu_hwmon}/temp2_input") else None,
            })

        rx, tx = net_bytes()
        print(json.dumps({
            "cpuTemp": read_int(f"{cpu_hwmon}/temp1_input") / 1000 if cpu_hwmon else None,
            "cpuFreq": sum(freqs) / len(freqs) / 1e6 if freqs else None,
            "cpus": cpus,
            "gpu": gpu if card else None,
            "disks": disks(),
            "netRx": rx,
            "netTx": tx,
            "uptime": float(read("/proc/uptime", "0").split()[0]),
            "procs": [{"name": n, "cpu": round(c, 1), "mem": m} for n, (c, m) in top],
        }), flush=True)


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        sys.exit(0)
