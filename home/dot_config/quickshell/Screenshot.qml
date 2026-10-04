pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

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

    // Con cursor por software, Hyprland dibuja el cursor dentro de la captura.
    // Para evitarlo se muestra un instante una capa transparente con cursor
    // invisible sobre todos los monitores, se captura y se quita.
    property bool hidingCursor: false
    property var pending: null

    function capture(proc) {
        pending = proc;
        hidingCursor = true;
        hideDelay.restart();
    }

    function captureDone() {
        hidingCursor = false;
        nudgeProc.running = true; // devuelve el cursor normal
    }

    // El cursor invisible solo se aplica cuando el ratón se mueve: se mueve
    // 1 px y se regresa, y después se captura
    Timer {
        id: hideDelay
        interval: 60
        onTriggered: {
            nudgeProc.then = root.pending;
            nudgeProc.running = true;
        }
    }
    Process {
        id: nudgeProc
        property var then: null
        command: ["sh", "-c", Hyprland.usingLua === false
            ? 'p=$(hyprctl cursorpos | tr -d " "); x=${p%,*}; y=${p#*,}; hyprctl dispatch movecursor $((x+1)) $y; hyprctl dispatch movecursor $x $y'
            : 'p=$(hyprctl cursorpos | tr -d " "); x=${p%,*}; y=${p#*,}; hyprctl dispatch "hl.dsp.cursor.move({ x = $((x+1)), y = $y })"; hyprctl dispatch "hl.dsp.cursor.move({ x = $x, y = $y })"']
        onExited: {
            if (!then) return;
            const p = then;
            then = null;
            captureTimer.proc = p;
            captureTimer.restart();
        }
    }
    Timer {
        id: captureTimer
        property var proc: null
        interval: 60
        onTriggered: proc.running = true
    }

    function newFile() {
        return `${dir}/Captura_${Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss")}.png`;
    }

    function open() {
        if (active || freezeProc.running) return;
        mode = "region";
        frozen = `/tmp/qs-screenshot-${Date.now()}.png`;
        freezeProc.command = ["grim", frozen];
        capture(freezeProc);
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
        capture(shotProc);
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
            root.captureDone();
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
        onExited: code => {
            root.captureDone();
            if (code === 0) root.finish(file);
        }
    }

    // Capa transparente que oculta el cursor durante la captura
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData
            screen: modelData
            visible: root.hidingCursor
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:screenshot-cursor"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.BlankCursor
            }
        }
    }

    // Un selector por monitor
    Variants {
        model: Quickshell.screens

        CaptureWindow {}
    }
}
