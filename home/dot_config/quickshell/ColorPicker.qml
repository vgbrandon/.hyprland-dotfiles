pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Selector de color: congela la pantalla (sin cursor), muestra una lupa y copia
// el color al hacer clic.
//   quickshell ipc call colorpicker pick     (cancel para cerrarlo)
Singleton {
    id: root

    property bool active: false
    property string frozen: ""
    // Color bajo el cursor (lo actualiza la ventana del monitor donde está el ratón)
    property color current: "black"

    function hex(c) {
        const h = v => Math.round(v * 255).toString(16).padStart(2, "0");
        return `#${h(c.r)}${h(c.g)}${h(c.b)}`;
    }

    function rgb(c) {
        return `rgb(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)})`;
    }

    function pick() {
        if (active || freezeProc.running) return;
        // PPM sin comprimir: grim tarda ~13 ms en vez de ~200 ms con PNG
        frozen = `/tmp/qs-colorpicker-${Date.now()}.ppm`;
        freezeProc.command = ["grim", "-t", "ppm", frozen];
        // Reutiliza la captura de Screenshot, que oculta el cursor mientras captura
        Screenshot.capture(freezeProc);
    }

    function cancel() {
        active = false;
        cleanup();
    }

    function cleanup() {
        const file = frozen;
        frozen = ""; // primero se suelta la imagen, luego se borra
        if (file !== "") Quickshell.execDetached(["rm", "-f", file]);
    }

    // Copia el color y avisa con una notificación (con una muestra del color)
    function accept(text, swatchFile) {
        active = false;
        cleanup();
        Quickshell.execDetached(["wl-copy", text]);
        Quickshell.execDetached(["notify-send", "-a", "Selector de color", "-h", `string:image-path:${swatchFile}`,
            "Color copiado", text]);
    }

    IpcHandler {
        target: "colorpicker"

        function pick(): void { root.pick(); }
        function cancel(): void { root.cancel(); }
    }

    Process {
        id: freezeProc
        onExited: code => {
            Screenshot.captureDone();
            if (code === 0) root.active = true;
            else root.cleanup();
        }
    }

    // Una ventana por monitor
    Variants {
        model: Quickshell.screens

        PickerWindow {}
    }
}
