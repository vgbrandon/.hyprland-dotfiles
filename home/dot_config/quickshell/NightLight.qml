pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Filtro de luz azul con hyprsunset. La temperatura se cambia en vivo por IPC (hyprctl hyprsunset).
// La barra solo lo activa/desactiva; la intensidad se ajusta en el panel de ajustes
// y se guarda (Config.nightLightTemp).
Singleton {
    id: root

    property bool available: false
    property bool enabled: false
    readonly property int defaultTemp: 4500
    property int temperature: Config.nightLightTemp > 0 ? Config.nightLightTemp : defaultTemp
    readonly property int minTemp: 2500
    readonly property int maxTemp: 6500
    // 0 = sin filtro, 1 = filtro máximo
    readonly property real strength: (maxTemp - temperature) / (maxTemp - minTemp)

    function toggle() {
        if (available) enabled = !enabled;
    }

    // Con el filtro apagado también se puede ajustar: se usa al encenderlo
    function setTemperature(t) {
        if (!available) return;
        temperature = Math.max(minTemp, Math.min(maxTemp, Math.round(t / 100) * 100));
        Config.setNightLightTemp(temperature);
        if (enabled) applyTimer.restart();
    }

    function reset() {
        setTemperature(defaultTemp);
    }

    // Rueda hacia arriba = más intensidad (temperatura más cálida)
    function scroll(delta) {
        setTemperature(temperature + (delta > 0 ? -100 : 100));
    }

    onEnabledChanged: proc.running = enabled

    Process {
        command: ["sh", "-c", "command -v hyprsunset"]
        running: true
        onExited: code => root.available = code === 0
    }

    // hyprsunset corre solo mientras el filtro está activado
    Process {
        id: proc
        command: ["hyprsunset", "-t", String(root.temperature)]
        // Si se cierra por su cuenta, el filtro queda desactivado
        onExited: root.enabled = false
    }

    // Cambia la temperatura en vivo (sin reiniciar hyprsunset, así no parpadea)
    Process {
        id: setProc
        property int sent: 0
        command: ["hyprctl", "hyprsunset", "temperature", String(sent)]
        // Si la rueda siguió moviéndose mientras se enviaba, manda el último valor
        onExited: if (root.enabled && sent !== root.temperature) applyTimer.restart()
    }

    Timer {
        id: applyTimer
        interval: 60
        onTriggered: {
            if (!proc.running || setProc.running) return;
            setProc.sent = root.temperature;
            setProc.running = true;
        }
    }
}
