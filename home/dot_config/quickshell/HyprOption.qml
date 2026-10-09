import QtQuick
import Quickshell
import Quickshell.Io

// Opción de configuración de Hyprland, leída y escrita en vivo.
// Con el parser de Lua, "hyprctl keyword" no funciona: los cambios se
// aplican con "hyprctl eval" (hl.config) y se leen con "hyprctl getoption -j".
Item {
    id: root

    required property string option // p. ej. "general:gaps_in"
    // Para opciones numéricas: rango del slider y valor por defecto
    property int max: 100
    property int fallback: 0

    property bool boolValue: false
    property int intValue: 0

    function refresh() {
        readProc.running = true;
    }

    function set(value) {
        if (typeof value === "number")
            value = Math.max(0, Math.min(root.max, Math.round(value)));

        // Anida la ruta de la opción en una tabla de Lua:
        // "decoration:blur:enabled" -> hl.config({decoration = {blur = {enabled = ...}}})
        const keys = root.option.split(":");
        let lua = typeof value === "boolean" ? (value ? "true" : "false") : String(value);
        for (let i = keys.length - 1; i >= 0; i--)
            lua = `{${keys[i]} = ${lua}}`;

        writeProc.command = ["hyprctl", "eval", `hl.config(${lua})`];
        writeProc.running = true;
    }

    Component.onCompleted: root.refresh()

    Process {
        id: readProc
        command: ["hyprctl", "getoption", "-j", root.option]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text);
                    if ("bool" in d) root.boolValue = !!d.bool;
                    else if ("int" in d) root.intValue = d.int;
                    else if ("css" in d) {
                        const n = parseInt(d.css);
                        if (!isNaN(n)) root.intValue = n;
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: writeProc
        command: []
        // Al terminar relee: si Hyprland rechazó el cambio, el valor vuelve
        // al real y el interruptor no se queda colgado.
        onExited: root.refresh()
    }
}
