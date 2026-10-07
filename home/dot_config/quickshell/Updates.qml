pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Actualizaciones pendientes de pacman (checkupdates) y del AUR (yay -Qua).
// Se revisa al iniciar, cada 30 minutos y después de actualizar.
//   quickshell ipc call updates check
Singleton {
    id: root

    // Cada paquete: { name, from, to }
    property var pacman: []
    property var aur: []
    readonly property int total: pacman.length + aur.length
    property bool checking: false
    property bool upgrading: false
    property date lastCheck: new Date(0)

    // Color según la cantidad: empieza en blanco y se va tiñendo hasta el color
    // final al llegar a "full" paquetes (pacman: amarillo, AUR: azul)
    readonly property int pacmanFull: 50
    readonly property int aurFull: 20

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    function pacmanColor() {
        return mix(Theme.text, Theme.warning, Math.min(1, pacman.length / pacmanFull));
    }

    function aurColor() {
        return mix(Theme.text, Theme.blue, Math.min(1, aur.length / aurFull));
    }

    // Líneas "nombre versión-actual -> versión-nueva"
    function parse(text) {
        return text.split("\n").map(l => l.trim().split(/\s+/)).filter(p => p.length >= 4 && p[2] === "->")
            .map(p => ({ name: p[0], from: p[1], to: p[3] }));
    }

    function check() {
        if (checking || upgrading) return;
        checking = true;
        pending = 2;
        pacmanProc.running = true;
        aurProc.running = true;
    }

    property int pending: 0
    function done() {
        if (--pending > 0) return;
        checking = false;
        lastCheck = new Date();
    }

    // Abre una terminal flotante con "yay -Syu" (actualiza pacman y AUR)
    function upgrade() {
        if (upgrading) return;
        upgrading = true;
        upgradeProc.running = true;
    }

    IpcHandler {
        target: "updates"

        function check(): void { root.check(); }
        function upgrade(): void { root.upgrade(); }
    }

    Component.onCompleted: check()

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.check()
    }

    Process {
        id: pacmanProc
        command: ["checkupdates"]
        stdout: StdioCollector {
            onStreamFinished: root.pacman = root.parse(this.text)
        }
        onExited: root.done()
    }

    Process {
        id: aurProc
        command: ["yay", "-Qua"]
        stdout: StdioCollector {
            onStreamFinished: root.aur = root.parse(this.text)
        }
        onExited: root.done()
    }

    // La regla de ventana "qs-updates" (flotante y centrada) está en hyprland.lua
    Process {
        id: upgradeProc
        command: ["kitty", "--class", "qs-updates", "--title", "Actualizar sistema", "bash", "-c",
            'yay -Syu; echo; read -n1 -rsp "Listo. Presiona una tecla para cerrar…"']
        onExited: {
            root.upgrading = false;
            root.check();
        }
    }
}
