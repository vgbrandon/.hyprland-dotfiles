pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Filtro de luz azul con hyprsunset. Se reinicia el proceso al cambiar la temperatura.
Singleton {
    id: root

    property bool available: false
    property bool enabled: false
    property int temperature: 4500
    readonly property int minTemp: 2500
    readonly property int maxTemp: 6500
    // 0 = sin filtro, 1 = filtro máximo
    readonly property real strength: (maxTemp - temperature) / (maxTemp - minTemp)

    function toggle() {
        if (available) enabled = !enabled;
    }

    function setTemperature(t) {
        if (!available) return;
        temperature = Math.max(minTemp, Math.min(maxTemp, Math.round(t / 100) * 100));
        enabled = true;
        applyTimer.restart();
    }

    onEnabledChanged: proc.running = enabled

    Process {
        command: ["sh", "-c", "command -v hyprsunset"]
        running: true
        onExited: code => root.available = code === 0
    }

    Process {
        id: proc
        command: ["hyprsunset", "-t", String(root.temperature)]
        // Al terminar (por un cambio de temperatura) vuelve a arrancar con el valor nuevo
        onExited: if (root.enabled) running = true
    }

    // Espera a que dejes de mover la rueda antes de reiniciar hyprsunset
    Timer {
        id: applyTimer
        interval: 250
        onTriggered: if (proc.running) proc.signal(15)
    }
}
