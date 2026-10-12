pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Menú de energía. Se abre con: quickshell ipc call power toggle
// La ventana es modules/power/PowerMenuWindow.qml.
Singleton {
    id: root

    property bool open: false
    property int selected: 0

    readonly property var actions: [
        { label: "Bloquear", key: "B", icon: Theme.iLock, run: () => Lock.lock() },
        { label: "Suspender", key: "S", icon: Theme.iSleep, run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { label: "Cerrar sesión", key: "C", icon: Theme.iLogout, run: () => Hypr.exit() },
        { label: "Reiniciar", key: "R", icon: Theme.iReboot, run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { label: "Apagar", key: "A", icon: Theme.iPower, run: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
    ]

    function toggle() {
        open = !open;
    }

    property int pending: -1

    // Cierra primero y ejecuta después, para que el compositor alcance a
    // redibujar sin el panel (si no, se ve un instante al volver de suspender)
    function run(i) {
        open = false;
        pending = i;
        runTimer.restart();
    }

    Timer {
        id: runTimer
        interval: 300
        onTriggered: {
            root.actions[root.pending].run();
            root.pending = -1;
        }
    }

    IpcHandler {
        target: "power"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }
}
