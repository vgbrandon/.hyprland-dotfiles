pragma Singleton

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// Fondo de pantalla dibujado por Quickshell (con fundido al cambiar) y su selector.
// El tema se genera a partir del fondo actual.
//   quickshell ipc call wallpaper toggle
Singleton {
    id: root

    readonly property string dir: `${Quickshell.env("HOME")}/Pictures`
    property bool open: false
    property var files: []
    // Miniatura en caché de cada fondo (ruta -> miniatura)
    property var thumbs: ({})
    // Fondo actual (se guarda y se restaura al iniciar)
    property string current: ""

    function toggle() {
        open = !open;
    }

    function choose(path) {
        current = path;
        state.setText(JSON.stringify({ wallpaper: path }));
        open = false;
    }

    onCurrentChanged: Theme.setWallpaper(current)
    onOpenChanged: if (open) listProc.running = true
    // Prepara las miniaturas al iniciar, para que el selector abra al instante
    Component.onCompleted: listProc.running = true

    IpcHandler {
        target: "wallpaper"

        function toggle(): void { root.toggle(); }
        function set(path: string): void { root.choose(path); }
    }

    Process {
        id: listProc
        command: ["sh", Quickshell.shellPath("scripts/wallpaper-thumbs.sh"), root.dir, Quickshell.cachePath("wallpaper-thumbs")]
        stdout: StdioCollector {
            onStreamFinished: {
                const files = [];
                const thumbs = {};
                for (const line of this.text.split("\n")) {
                    const [file, thumb] = line.split("\t");
                    if (!file) continue;
                    files.push(file);
                    thumbs[file] = thumb || file;
                }
                root.thumbs = thumbs;
                root.files = files;
                if (root.current === "" && root.files.length > 0) root.choose(root.files[0]);
            }
        }
    }

    // Fondo guardado; si no hay, se toma el que tenga hyprpaper o, si no está,
    // la primera imagen de la carpeta
    FileView {
        id: state
        path: Quickshell.statePath("wallpaper.json")
        onLoaded: {
            try {
                root.current = JSON.parse(text()).wallpaper ?? "";
            } catch (e) {}
            if (root.current === "") initProc.running = true;
        }
        onLoadFailed: initProc.running = true
    }
    Process {
        id: initProc
        command: ["hyprctl", "hyprpaper", "listactive"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.split("\n").find(l => l.includes(": /")) ?? "";
                const path = line.slice(line.indexOf(": ") + 2).trim();
                if (root.current !== "") return;
                if (path !== "") root.current = path;
                else listProc.running = true;
            }
        }
    }

    // Una capa de fondo por monitor
    Variants {
        model: Quickshell.screens

        WallpaperWindow {}
    }

    PanelWindow {
        visible: root.open
        screen: Quickshell.screens.find(s => Hyprland.monitorFor(s) === Hyprland.focusedMonitor) ?? Quickshell.screens[0]
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: Qt.rgba(0, 0, 0, 0.35)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:wallpaper"

        onVisibleChanged: if (visible) grid.forceActiveFocus()

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: grid.width + 32
            height: content.implicitHeight + 32
            radius: Theme.radius
            color: Theme.panelBg
            border.color: Theme.surfaceHigh
            border.width: 1

            opacity: root.open ? 1 : 0
            scale: root.open ? 1 : 0.96
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            MouseArea {
                anchors.fill: parent // evita que el clic llegue al fondo
            }

            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.leftMargin: 4
                    spacing: 10

                    Icon {
                        text: Theme.iImage
                        font.pixelSize: 20
                    }
                    ColumnLayout {
                        spacing: 0

                        Label {
                            text: "Fondos de pantalla"
                            font.pixelSize: 16
                        }
                        Label {
                            text: root.dir.replace(Quickshell.env("HOME"), "~")
                            color: Theme.subtext
                            font.pixelSize: Theme.fontSize
                        }
                    }
                }

                GridView {
                    id: grid

                    readonly property int columns: 3

                    width: columns * cellWidth
                    implicitHeight: Math.max(1, Math.min(3, Math.ceil(count / columns))) * cellHeight
                    cellWidth: 216
                    cellHeight: 140
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationWraps: true
                    model: root.files
                    visible: count > 0
                    // La lista llega un momento después de abrir: selecciona el fondo actual
                    onCountChanged: currentIndex = Math.max(0, root.files.indexOf(Theme.wallpaper))

                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Escape) root.open = false;
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.choose(root.files[currentIndex]);
                        else return;
                        e.accepted = true;
                    }

                    delegate: Item {
                        id: cell
                        required property string modelData
                        required property int index
                        readonly property bool selected: GridView.isCurrentItem
                        readonly property bool active: modelData === Theme.wallpaper

                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: Theme.radius
                            color: cell.selected ? Theme.surfaceHigh : "transparent"
                            border.color: cell.active ? Theme.primary : "transparent"
                            border.width: 2

                            ClippingRectangle {
                                anchors.fill: parent
                                anchors.margins: 6
                                radius: Theme.radiusSmall
                                color: Theme.surface

                                Image {
                                    anchors.fill: parent
                                    source: "file://" + (root.thumbs[cell.modelData] ?? cell.modelData)
                                    sourceSize.width: 400
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }
                            }

                            // Marca del fondo actual
                            Rectangle {
                                visible: cell.active
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 12
                                width: 24
                                height: 24
                                radius: 12
                                color: Theme.primary

                                Icon {
                                    anchors.centerIn: parent
                                    text: Theme.iCheck
                                    color: Theme.primaryFg
                                    font.pixelSize: 16
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: grid.currentIndex = cell.index
                            onClicked: root.choose(cell.modelData)
                        }
                    }
                }

                Label {
                    visible: grid.count === 0
                    Layout.alignment: Qt.AlignHCenter
                    Layout.margins: 20
                    text: "No hay imágenes en " + root.dir.replace(Quickshell.env("HOME"), "~")
                    color: Theme.subtext
                }
            }
        }
    }
}
