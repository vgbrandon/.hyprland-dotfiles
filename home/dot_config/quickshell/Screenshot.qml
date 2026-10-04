pragma Singleton

import QtQuick
import QtQuick.Layouts
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
    property string lastFile: ""

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

    function finish(file) {
        Quickshell.execDetached(["sh", "-c", 'wl-copy --type image/png < "$1"', "sh", file]);
        lastFile = file;
        toast.show();
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

    // Aviso con miniatura al guardar
    PanelWindow {
        id: toast

        function show() {
            visible = true;
            toastTimer.restart();
        }

        visible: false
        screen: Quickshell.screens.find(s => Hyprland.monitorFor(s) === Hyprland.focusedMonitor) ?? Quickshell.screens[0]
        anchors {
            bottom: true
            right: true
        }
        margins {
            bottom: 16
            right: 16
        }
        implicitWidth: 320
        implicitHeight: card.implicitHeight
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:screenshot-toast"

        Timer {
            id: toastTimer
            interval: 4000
            onTriggered: toast.visible = false
        }

        Rectangle {
            id: card
            anchors.fill: parent
            implicitHeight: col.implicitHeight + 24
            radius: 20
            color: Theme.surface
            border.color: Theme.surfaceHigh
            border.width: 1

            ColumnLayout {
                id: col
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Image {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(160, implicitHeight)
                    source: toast.visible && root.lastFile !== "" ? "file://" + root.lastFile : ""
                    sourceSize.width: 296
                    fillMode: Image.PreserveAspectFit
                    cache: false
                }

                RowLayout {
                    spacing: 10

                    Icon {
                        text: Theme.iCamera
                        font.pixelSize: 20
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Label {
                            text: "Captura guardada"
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "Copiada al portapapeles · clic para abrir"
                            color: Theme.subtext
                            font.pixelSize: Theme.fontSize
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(["xdg-open", root.lastFile]);
                    toast.visible = false;
                }
            }
        }
    }
}
