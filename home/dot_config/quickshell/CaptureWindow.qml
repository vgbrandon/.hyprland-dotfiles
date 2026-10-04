import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Selector de captura en un monitor: muestra la pantalla congelada y deja elegir el área
PanelWindow {
    id: win

    required property ShellScreen modelData
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
    readonly property bool focusedScreen: monitor === Hyprland.focusedMonitor
    // Posición de este monitor dentro de la imagen congelada
    readonly property int offX: modelData.x - Screenshot.originX
    readonly property int offY: modelData.y - Screenshot.originY
    readonly property color dim: Qt.rgba(0, 0, 0, 0.45)

    // Selección (coordenadas locales)
    property real ax: 0
    property real ay: 0
    property bool dragging: false
    property var selection: null
    property var hovered: null

    // Rectángulo resaltado según el modo
    readonly property var rect: Screenshot.mode === "region" ? selection
        : Screenshot.mode === "screen" ? (mouse.containsMouse ? Qt.rect(0, 0, width, height) : null)
        : hovered

    // Ventanas visibles en este monitor, de la más alta a la más baja
    readonly property var windows: Screenshot.clients
        .filter(c => c.workspace.id === monitor?.activeWorkspace?.id || (c.pinned && c.monitor === monitor?.id))
        .sort((a, b) => (b.floating - a.floating) || (a.focusHistoryID - b.focusHistoryID))
        .map(c => Qt.rect(c.at[0] - modelData.x, c.at[1] - modelData.y, c.size[0], c.size[1]))

    function windowAt(x, y) {
        return windows.find(r => x >= r.x && x < r.x + r.width && y >= r.y && y < r.y + r.height) ?? null;
    }

    function capture(r) {
        if (!r || r.width < 2 || r.height < 2) return;
        // Recorta dentro de los límites del monitor
        const x = Math.max(0, Math.round(r.x)), y = Math.max(0, Math.round(r.y));
        const w = Math.min(width, Math.round(r.x + r.width)) - x;
        const h = Math.min(height, Math.round(r.y + r.height)) - y;
        cropper.width = w;
        cropper.height = h;
        cropper.sourceClipRect = Qt.rect(x + offX, y + offY, w, h);
        cropper.pending = true;
        cropper.source = "";
        cropper.source = "file://" + Screenshot.frozen;
    }

    screen: modelData
    visible: Screenshot.active
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: focusedScreen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:screenshot"

    onVisibleChanged: {
        selection = null;
        hovered = null;
        dragging = false;
        if (visible && focusedScreen) keys.forceActiveFocus();
    }

    // Recorte que se guarda (queda tapado por la imagen de fondo)
    Image {
        id: cropper
        property bool pending: false
        cache: false
        onStatusChanged: {
            if (status === Image.Ready && pending) {
                pending = false;
                grabToImage(result => Screenshot.save(result));
            }
        }
    }

    // Pantalla congelada
    Image {
        x: -win.offX
        y: -win.offY
        source: Screenshot.active && Screenshot.frozen !== "" ? "file://" + Screenshot.frozen : ""
        cache: false
    }

    // Oscurecido alrededor del área resaltada
    Rectangle {
        color: win.dim
        width: parent.width
        height: win.rect ? win.rect.y : parent.height
    }
    Rectangle {
        visible: !!win.rect
        color: win.dim
        y: win.rect ? win.rect.y + win.rect.height : 0
        width: parent.width
        height: parent.height - y
    }
    Rectangle {
        visible: !!win.rect
        color: win.dim
        y: win.rect?.y ?? 0
        width: win.rect?.x ?? 0
        height: win.rect?.height ?? 0
    }
    Rectangle {
        visible: !!win.rect
        color: win.dim
        x: win.rect ? win.rect.x + win.rect.width : 0
        y: win.rect?.y ?? 0
        width: parent.width - x
        height: win.rect?.height ?? 0
    }

    // Borde y tamaño
    Rectangle {
        visible: !!win.rect
        x: (win.rect?.x ?? 0) - 1
        y: (win.rect?.y ?? 0) - 1
        width: (win.rect?.width ?? 0) + 2
        height: (win.rect?.height ?? 0) + 2
        color: "transparent"
        border.color: Theme.primary
        border.width: 2
        radius: 4
    }
    Rectangle {
        visible: !!win.rect && Screenshot.mode === "region"
        x: win.rect?.x ?? 0
        y: win.rect ? (win.rect.y + win.rect.height + 32 < win.height ? win.rect.y + win.rect.height + 6 : win.rect.y - height - 6) : 0
        width: sizeLabel.implicitWidth + 16
        height: 24
        radius: 12
        color: Theme.surface

        Label {
            id: sizeLabel
            anchors.centerIn: parent
            text: win.rect ? `${Math.round(win.rect.width)} × ${Math.round(win.rect.height)}` : ""
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Screenshot.mode === "region" ? Qt.CrossCursor : Qt.PointingHandCursor

        onPressed: e => {
            if (Screenshot.mode !== "region") return;
            win.ax = e.x;
            win.ay = e.y;
            win.dragging = true;
            win.selection = null;
        }
        onPositionChanged: e => {
            if (Screenshot.mode === "region" && win.dragging)
                win.selection = Qt.rect(Math.min(win.ax, e.x), Math.min(win.ay, e.y), Math.abs(e.x - win.ax), Math.abs(e.y - win.ay));
            else if (Screenshot.mode === "window")
                win.hovered = win.windowAt(e.x, e.y);
        }
        onReleased: {
            if (Screenshot.mode !== "region") return;
            win.dragging = false;
            win.capture(win.selection);
        }
        onClicked: if (Screenshot.mode !== "region") win.capture(win.rect)
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) Screenshot.cancel();
            else if (e.key === Qt.Key_1) Screenshot.mode = "region";
            else if (e.key === Qt.Key_2) Screenshot.mode = "window";
            else if (e.key === Qt.Key_3) Screenshot.mode = "screen";
            else if (e.key === Qt.Key_Tab) {
                const modes = ["region", "window", "screen"];
                Screenshot.mode = modes[(modes.indexOf(Screenshot.mode) + 1) % 3];
            } else return;
            e.accepted = true;
        }
    }

    // Barra de modos (solo en el monitor enfocado)
    Rectangle {
        visible: win.focusedScreen && !win.dragging
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24
        width: toolbar.implicitWidth + 12
        height: 48
        radius: height / 2
        color: Theme.surface
        border.color: Theme.surfaceHigh
        border.width: 1

        RowLayout {
            id: toolbar
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: [
                    { mode: "region", label: "Región", icon: Theme.iRegion },
                    { mode: "window", label: "Ventana", icon: Theme.iWindow },
                    { mode: "screen", label: "Pantalla", icon: Theme.iMonitor }
                ]

                Rectangle {
                    id: btn
                    required property var modelData
                    required property int index
                    readonly property bool current: Screenshot.mode === modelData.mode

                    implicitWidth: btnRow.implicitWidth + 28
                    implicitHeight: 36
                    radius: height / 2
                    color: current ? Theme.primary : btnMouse.containsMouse ? Theme.surfaceHigh : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        id: btnRow
                        anchors.centerIn: parent
                        spacing: 8

                        Icon {
                            text: btn.modelData.icon
                            color: btn.current ? Theme.primaryFg : Theme.text
                            font.pixelSize: 18
                        }
                        Label {
                            text: btn.modelData.label
                            color: btn.current ? Theme.primaryFg : Theme.text
                        }
                        Label {
                            text: btn.index + 1
                            color: btn.current ? Theme.primaryFg : Theme.subtext
                            font.pixelSize: Theme.fontSize - 1
                        }
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Screenshot.mode = btn.modelData.mode;
                            win.hovered = null;
                        }
                    }
                }
            }

            Label {
                Layout.leftMargin: 8
                Layout.rightMargin: 10
                text: "Esc para cancelar"
                color: Theme.subtext
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
