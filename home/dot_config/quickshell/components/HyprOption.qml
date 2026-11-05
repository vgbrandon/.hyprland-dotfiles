import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Opción de configuración de Hyprland, leída y escrita en vivo.
// Con el parser de Lua, "hyprctl keyword" no funciona: los cambios se
// aplican con "hyprctl eval" (hl.config) y se leen con "hyprctl getoption -j".
// Con persist, el valor se guarda en los ajustes de Quickshell (Config.hyprSet) y se
// vuelve a aplicar al arrancar (Hyprland, al recargar, vuelve a los de hyprland.lua).
Item {
    id: root

    // No es visual: oculto, un layout no le reserva sitio (si no, deja huecos)
    visible: false

    required property string option // p. ej. "general:gaps_in"
    // Para opciones numéricas: rango del deslizador y valor por defecto
    property real min: 0
    property real max: 100
    property real fallback: 0
    // Con decimales (p. ej. decoration:blur:brightness); si no, se redondea
    property bool decimal: false
    property bool persist: false

    property bool boolValue: false
    property int intValue: 0
    property real realValue: 0

    function refresh() {
        readProc.running = true;
    }

    function set(value) {
        if (typeof value === "number") {
            value = Math.max(root.min, Math.min(root.max, value));
            value = root.decimal ? Math.round(value * 10000) / 10000 : Math.round(value);
        }
        if (root.persist) Config.hyprSet(root.option, value);

        // Anida la ruta de la opción en una tabla de Lua:
        // "decoration:blur:enabled" -> hl.config({decoration = {blur = {enabled = ...}}})
        writeProc.command = ["hyprctl", "eval", `hl.config(${Config.hyprLua(root.option, value)})`];
        writeProc.running = true;
    }
    // Volver al valor por defecto (y olvidar el guardado)
    function reset() {
        set(root.fallback);
        if (root.persist) Config.hyprForget(root.option);
    }

    Component.onCompleted: root.refresh()
    // Al aplicar Config los valores guardados (al arrancar), se relee
    Connections {
        target: Config
        function onHyprApplied() {
            root.refresh();
        }
    }

    Process {
        id: readProc
        command: ["hyprctl", "getoption", "-j", root.option]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text);
                    if ("bool" in d) root.boolValue = !!d.bool;
                    else if ("int" in d) {
                        root.intValue = d.int;
                        root.realValue = d.int;
                    } else if ("float" in d) {
                        root.realValue = d.float;
                        root.intValue = Math.round(d.float);
                    } else if ("css" in d) {
                        const n = parseInt(d.css);
                        if (!isNaN(n)) {
                            root.intValue = n;
                            root.realValue = n;
                        }
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
