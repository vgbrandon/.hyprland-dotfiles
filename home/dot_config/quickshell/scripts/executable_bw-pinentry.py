#!/usr/bin/env python3
"""Pinentry de rbw que pregunta en la shell (módulo de Bitwarden).

rbw-agent lo lanza cuando necesita la contraseña maestra (o un código 2FA, la clave de
la API…) y le habla con el protocolo de pinentry (Assuan). En cada GETPIN se crea un
FIFO privado y se avisa a Quickshell (quickshell ipc call bitwarden askPin …), que
muestra la pregunta y escribe la respuesta en el FIFO: "1<texto>" o "0" (cancelar).
Si Quickshell no responde, se usa el pinentry normal del sistema.
"""
import os
import select
import subprocess
import sys
import tempfile
import time
import urllib.parse

TIMEOUT = 600  # segundos para responder


def ipc(*args):
    try:
        return subprocess.run(["quickshell", "ipc", "call", "bitwarden", *args],
                              capture_output=True, timeout=5).returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        return False


def reply(line):
    sys.stdout.write(line + "\n")
    sys.stdout.flush()


def escape(text):
    return text.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def ask(info):
    folder = tempfile.mkdtemp(prefix="bw-pin-", dir=os.environ.get("XDG_RUNTIME_DIR"))
    fifo = os.path.join(folder, "pin")
    os.mkfifo(fifo, 0o600)
    try:
        if not ipc("askPin", fifo, info.get("SETTITLE", ""), info.get("SETPROMPT", ""),
                   info.get("SETDESC", ""), info.get("SETERROR", "")):
            return None
        # Abrir sin bloquear para poder esperar con límite de tiempo
        fd = os.open(fifo, os.O_RDONLY | os.O_NONBLOCK)
        data = b""
        deadline = time.monotonic() + TIMEOUT
        try:
            while True:
                left = deadline - time.monotonic()
                if left <= 0:
                    ipc("cancelPin")
                    return None
                # Sin nadie escribiendo, el FIFO da "fin" al momento: se reintenta
                ready, _, _ = select.select([fd], [], [], left)
                chunk = os.read(fd, 4096) if ready else b""
                if chunk:
                    data += chunk
                elif data:
                    break
                else:
                    time.sleep(0.05)
        finally:
            os.close(fd)
        text = data.decode()
        return text[1:] if text.startswith("1") else None
    finally:
        try:
            os.unlink(fifo)
        except OSError:
            pass
        os.rmdir(folder)


def main():
    if not ipc("ping"):
        os.execvp("pinentry", ["pinentry", *sys.argv[1:]])

    reply("OK Pleased to meet you")
    info = {}
    for line in sys.stdin:
        cmd, _, arg = line.rstrip("\n").partition(" ")
        cmd = cmd.upper()
        if cmd in ("SETTITLE", "SETPROMPT", "SETDESC", "SETERROR"):
            info[cmd] = urllib.parse.unquote(arg)
            reply("OK")
        elif cmd == "GETPIN":
            pin = ask(info)
            info.pop("SETERROR", None)
            if pin is None:
                reply("ERR 83886179 Operation cancelled <Pinentry>")
            else:
                if pin:
                    reply("D " + escape(pin))
                reply("OK")
        elif cmd == "BYE":
            reply("OK closing connection")
            return
        else:
            reply("OK")


if __name__ == "__main__":
    main()
