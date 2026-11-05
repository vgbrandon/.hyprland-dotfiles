#!/usr/bin/env python3
"""Desbloquea el llavero del sistema (Secret Service, gnome-keyring) pidiendo la contraseña
con su diálogo, y espera la respuesta. Lo usa el módulo de la VPN (el cliente de Proton
guarda la sesión ahí y se queda esperando si está bloqueado).
gnome-keyring a veces se queda colgado (p. ej. si se cierra un cliente con su diálogo
abierto) y ya no muestra ninguno: si el diálogo no sale en unos segundos, se reinicia el
llavero y se vuelve a pedir una vez. Al terminar por una señal se cierra la petición
(si no, el llavero se cuelga).
Imprime «desbloqueado», «ya estaba desbloqueado», «cancelado» o «sin respuesta»."""
import signal
import subprocess
import time

from gi.repository import Gio, GLib

DEFAULT = "/org/freedesktop/secrets/aliases/default"
estado = {"prompt": None, "resultado": "sin respuesta", "reintentado": False}
loop = GLib.MainLoop()


def bus():
    return Gio.bus_get_sync(Gio.BusType.SESSION)


def bloqueado():
    try:
        v = bus().call_sync("org.freedesktop.secrets", DEFAULT, "org.freedesktop.DBus.Properties", "Get",
                            GLib.Variant("(ss)", ("org.freedesktop.Secret.Collection", "Locked")),
                            None, 0, 5000, None).unpack()[0]
        return bool(v)
    except GLib.Error:
        return True


def hay_dialogo():
    return bool(bus().call_sync("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                                "NameHasOwner", GLib.Variant("(s)", ("org.gnome.keyring.SystemPrompter",)),
                                None, 0, -1, None).unpack()[0])


def cerrar_prompt():
    p = estado["prompt"]
    estado["prompt"] = None
    if p:
        try:
            bus().call_sync("org.freedesktop.secrets", p, "org.freedesktop.Secret.Prompt", "Dismiss",
                            None, None, 0, 2000, None)
        except GLib.Error:
            pass


def hecho(conn, sender, path, iface, signal_name, params):
    if path != estado["prompt"]:
        return
    estado["prompt"] = None
    estado["resultado"] = "cancelado" if params[0] else "desbloqueado"
    loop.quit()


def pedir():
    b = bus()
    r = b.call_sync("org.freedesktop.secrets", "/org/freedesktop/secrets", "org.freedesktop.Secret.Service",
                    "Unlock", GLib.Variant("(ao)", ([DEFAULT],)), None, 0, 10000, None).unpack()
    if r[1] == "/":
        return False
    estado["prompt"] = r[1]
    b.signal_subscribe("org.freedesktop.secrets", "org.freedesktop.Secret.Prompt", "Completed",
                       r[1], None, 0, hecho)
    b.call_sync("org.freedesktop.secrets", r[1], "org.freedesktop.Secret.Prompt", "Prompt",
                GLib.Variant("(s)", ("",)), None, 0, 10000, None)
    GLib.timeout_add_seconds(4, comprobar)
    return True


def comprobar():
    # Sin diálogo a los 4 s: el llavero está colgado; se reinicia y se pide otra vez
    if estado["prompt"] and not hay_dialogo() and not estado["reintentado"]:
        estado["reintentado"] = True
        estado["prompt"] = None
        subprocess.run(["systemctl", "--user", "restart", "gnome-keyring-daemon.service"])
        for _ in range(20):
            time.sleep(0.25)
            try:
                if not pedir():
                    estado["resultado"] = "desbloqueado"
                    loop.quit()
                return False
            except GLib.Error:
                continue
        loop.quit()
    return False


def salir(*_):
    cerrar_prompt()
    loop.quit()


for s in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
    GLib.unix_signal_add(GLib.PRIORITY_HIGH, s, salir)

if not bloqueado():
    print("ya estaba desbloqueado")
    raise SystemExit
if not pedir():
    print("ya estaba desbloqueado")
    raise SystemExit
GLib.timeout_add_seconds(120, salir)
loop.run()
cerrar_prompt()
print(estado["resultado"])
