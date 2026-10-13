pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Inactividad: bloquear, apagar las pantallas y suspender tras unos minutos sin usar
// el equipo. Cada uno se activa y se ajusta en el panel de ajustes (se guarda en
// idle.json). Los vídeos y llamadas que piden mantener la pantalla encendida lo
// retrasan (respectInhibitors). Bloquear antes de suspender lo sigue haciendo hypridle.
Singleton {
    id: root

    // Minutos que se pueden elegir
    readonly property var steps: [1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120]

    readonly property bool lockEnabled: store.lockEnabled
    readonly property int lockMinutes: store.lockMinutes
    readonly property bool screenOffEnabled: store.screenOffEnabled
    readonly property int screenOffMinutes: store.screenOffMinutes
    readonly property bool suspendEnabled: store.suspendEnabled
    readonly property int suspendMinutes: store.suspendMinutes

    // what: "lock" | "screenOff" | "suspend"
    function setEnabled(what, on) {
        store[what + "Enabled"] = on;
        file.writeAdapter();
    }
    // Siguiente o anterior valor de la lista (d = 1 / -1)
    function step(what, d) {
        const key = what + "Minutes";
        const i = steps.indexOf(store[key]);
        const next = i < 0 ? steps.findIndex(s => s >= store[key]) : i + d;
        store[key] = steps[Math.max(0, Math.min(steps.length - 1, next))];
        file.writeAdapter();
    }

    function label(minutes) {
        return minutes < 60 ? `${minutes} min` : minutes % 60 === 0 ? `${minutes / 60} h` : `${Math.floor(minutes / 60)} h ${minutes % 60}`;
    }

    IdleMonitor {
        enabled: root.lockEnabled
        timeout: root.lockMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Lock.lock()
    }

    IdleMonitor {
        enabled: root.screenOffEnabled
        timeout: root.screenOffMinutes * 60
        respectInhibitors: true
        // Se encienden al mover el ratón o tocar una tecla
        onIsIdleChanged: Hypr.dpms(!isIdle)
    }

    IdleMonitor {
        enabled: root.suspendEnabled
        timeout: root.suspendMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Quickshell.execDetached(["systemctl", "suspend"])
    }

    FileView {
        id: file
        path: Quickshell.statePath("idle.json")
        blockLoading: true
        // Aún no existe hasta el primer cambio: no es un error
        printErrors: false

        JsonAdapter {
            id: store
            property bool lockEnabled: true
            property int lockMinutes: 5
            property bool screenOffEnabled: true
            property int screenOffMinutes: 10
            property bool suspendEnabled: false
            property int suspendMinutes: 30
        }
    }
}
