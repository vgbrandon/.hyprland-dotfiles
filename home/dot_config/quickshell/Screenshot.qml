pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Capturas de pantalla.
//   quickshell ipc call screenshot open    -> selector (región / ventana / pantalla)
//   quickshell ipc call screenshot screen  -> monitor enfocado al instante
Singleton {
    id: root

    property bool active: false
    property string mode: "region" // region | window | screen
    property string frozen: "" // imagen congelada de todos los monitores
    property var clients: []

    readonly property string dir: `${Quickshell.env("HOME")}/Pictures/Screenshots`
    // Esquina superior izquierda del layout de monitores (origen de la imagen de grim)
    readonly property int originX: Math.min(...Quickshell.screens.map(s => s.x))
    readonly property int originY: Math.min(...Quickshell.screens.map(s => s.y))

    function newFile() {
        return `${dir}/Captura_${Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss")}.png`;
    }

    function open() {
        if (active || freezeProc.running) return;
        mode = "region";
        frozen = `/tmp/qs-screenshot-${Date.now()}.png`;
        freezeProc.command = ["grim", frozen];
        freezeProc.running = true;
        clientsProc.running = true;
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

    // Recibe el recorte (resultado de grabToImage) y lo guarda
    function save(result) {
        const file = newFile();
        result.saveToFile(file);
        active = false;
        cleanup();
        finish(file);
    }

    // Copia al portapapeles y envía una notificación (queda en el historial).
    // notify-send espera la acción: clic en la notificación abre la imagen en el visor.
    function finish(file) {
        Quickshell.execDetached(["sh", "-c", 'wl-copy --type image/png < "$1"', "sh", file]);
        Quickshell.execDetached(["sh", "-c", `
            action=$(notify-send -a "Captura de pantalla" -h string:image-path:"$1" -A default=Abrir \
                "Captura guardada" "Copiada al portapapeles")
            [ "$action" = default ] && quickshell ipc call screenshot view "$1"`, "sh", file]);
    }

    // Tamaño máximo de la ventana del visor (si la imagen es más grande se reduce)
    readonly property int viewerMaxWidth: 1280
    readonly property int viewerMaxHeight: 720

    // Abre la imagen en swayimg, flotante y centrada (regla solo para esta ventana).
    // Primero lee su tamaño con imageProbe y luego llama a launchViewer.
    function view(file) {
        imageProbe.file = file;
        imageProbe.source = "";
        imageProbe.source = "file://" + file;
    }

    function launchViewer(file, w, h) {
        const scale = Math.min(1, viewerMaxWidth / w, viewerMaxHeight / h);
        const size = `${Math.round(w * scale)},${Math.round(h * scale)}`;
        const quoted = "'" + file.replace(/'/g, "'\\''") + "'";
        const cmd = `[float; center] swayimg --size=${size} ${quoted}`;
        if (Hyprland.usingLua === false)
            Hyprland.dispatch(`exec ${cmd}`);
        else
            Hyprland.dispatch(`hl.dsp.exec_cmd(${JSON.stringify(cmd)})`);
    }

    Image {
        id: imageProbe
        property string file: ""
        visible: false
        cache: false
        onStatusChanged: {
            if (file === "" || (status !== Image.Ready && status !== Image.Error)) return;
            const f = file;
            file = "";
            // Si no se puede leer, usa el tamaño máximo
            if (status === Image.Ready) root.launchViewer(f, implicitWidth, implicitHeight);
            else root.launchViewer(f, root.viewerMaxWidth, root.viewerMaxHeight);
            source = "";
        }
    }

    function screenNow() {
        const file = newFile();
        shotProc.file = file;
        shotProc.command = ["grim", "-o", Hyprland.focusedMonitor?.name ?? "", file];
        shotProc.running = true;
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", dir])

    IpcHandler {
        target: "screenshot"

        function open(): void { root.open(); }
        function screen(): void { root.screenNow(); }
        function view(file: string): void { root.view(file); }
    }

    Process {
        id: freezeProc
        onExited: code => {
            if (code === 0) root.active = true;
            else root.cleanup();
        }
    }

    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.clients = JSON.parse(this.text).filter(c => c.mapped && !c.hidden);
                } catch (e) {
                    root.clients = [];
                }
            }
        }
    }

    Process {
        id: shotProc
        property string file
        onExited: code => { if (code === 0) root.finish(file); }
    }

    // Un selector por monitor
    Variants {
        model: Quickshell.screens

        CaptureWindow {}
    }
}
