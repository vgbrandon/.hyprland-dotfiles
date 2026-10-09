import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets

// Panel de Bluetooth: encender/apagar, dispositivos emparejados y disponibles
PopupWindow {
    id: panel

    required property Item anchorItem
    readonly property BluetoothAdapter bt: Bluetooth.defaultAdapter
    readonly property bool on: bt?.enabled ?? false
    readonly property bool blocked: bt?.state === BluetoothAdapterState.Blocked

    readonly property var devices: (bt?.devices.values ?? []).slice()
        .sort((a, b) => (b.connected - a.connected) || deviceName(a).localeCompare(deviceName(b)))
    readonly property var paired: devices.filter(d => d.paired || d.connected)
    // Solo se muestran los que tienen nombre (los demás suelen ser ruido)
    readonly property var available: devices.filter(d => !d.paired && !d.connected && d.name !== "" && d.name !== d.address.replace(/:/g, "-"))

    function deviceName(d) {
        return d.name || d.deviceName || d.address;
    }

    function setPower(value) {
        if (!bt) return;
        // Si está bloqueado por rfkill, primero se desbloquea
        if (value && blocked) unblock.running = true;
        else bt.enabled = value;
    }

    // Pegado al borde derecho de la pantalla, debajo de la barra (como el de notificaciones)
    anchor.window: anchorItem.QsWindow.window
    anchor.rect.x: (anchorItem.QsWindow.window?.width ?? 0) - width - 8
    anchor.rect.y: Theme.barHeight + 8
    implicitWidth: 360
    implicitHeight: Math.min(520, layout.implicitHeight + 24)
    color: "transparent"

    Process {
        id: unblock
        command: ["rfkill", "unblock", "bluetooth"]
        onExited: code => { if (code === 0) enableTimer.restart(); }
    }
    // El adaptador tarda un momento en estar listo tras desbloquearlo
    Timer {
        id: enableTimer
        interval: 600
        onTriggered: if (panel.bt) panel.bt.enabled = true
    }

    // Busca dispositivos solo mientras el panel está abierto
    function updateDiscovery() {
        if (bt && on) bt.discovering = visible;
    }
    onOnChanged: updateDiscovery()

    property real closedAt: 0

    // Abre/cierra desde el botón de la barra. Si el mismo clic acaba de
    // cerrarlo (clic fuera del panel), no lo vuelve a abrir.
    function toggle() {
        if (!visible && Date.now() - closedAt < 300) return;
        visible = !visible;
    }

    HyprlandFocusGrab {
        id: grab
        windows: [panel]
        onCleared: {
            panel.visible = false;
            panel.closedAt = Date.now();
        }
    }
    onVisibleChanged: {
        updateDiscovery();
        grab.active = false;
        if (visible) grabTimer.restart();
    }
    Timer {
        id: grabTimer
        interval: 50
        onTriggered: grab.active = panel.visible
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panelBg
        border.color: Theme.surfaceHigh
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Encabezado
            RowLayout {
                Layout.leftMargin: 6
                Layout.rightMargin: 4
                spacing: 10

                Icon {
                    text: panel.on ? Theme.iBt : Theme.iBtOff
                    font.pixelSize: 20
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Label {
                        text: "Bluetooth"
                        font.pixelSize: 16
                    }
                    Label {
                        text: !panel.bt ? "Sin adaptador"
                            : panel.blocked ? "Bloqueado"
                            : !panel.on ? "Apagado"
                            : panel.bt.discovering ? "Buscando dispositivos…" : "Encendido"
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize
                    }
                }
                // Buscar de nuevo
                Rectangle {
                    visible: panel.on
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    color: scanMouse.containsMouse ? Theme.surfaceHigh : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        text: Theme.iRefresh
                        font.pixelSize: 18
                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 1200
                            loops: Animation.Infinite
                            running: panel.bt?.discovering ?? false
                            onRunningChanged: if (!running) parent.rotation = 0
                        }
                    }
                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panel.bt.discovering = !panel.bt.discovering
                    }
                }
                Switch {
                    visible: panel.bt !== null
                    checked: panel.on
                    onToggled: panel.setPower(!panel.on)
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: lists.implicitHeight
                visible: panel.on
                contentHeight: lists.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: lists
                    width: parent.width
                    spacing: 4

                    Label {
                        visible: panel.paired.length > 0
                        Layout.leftMargin: 8
                        Layout.topMargin: 4
                        text: "Mis dispositivos"
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize
                    }
                    Repeater {
                        model: ScriptModel { values: panel.paired }
                        BluetoothDeviceRow {
                            Layout.fillWidth: true
                        }
                    }

                    Label {
                        Layout.leftMargin: 8
                        Layout.topMargin: 8
                        text: "Disponibles"
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize
                    }
                    Repeater {
                        model: ScriptModel { values: panel.available }
                        BluetoothDeviceRow {
                            Layout.fillWidth: true
                        }
                    }
                    Label {
                        visible: panel.available.length === 0
                        Layout.leftMargin: 8
                        Layout.bottomMargin: 6
                        text: panel.bt?.discovering ? "Buscando…" : "No se encontraron dispositivos"
                        color: Theme.dot
                        font.pixelSize: Theme.fontSize
                    }
                }
            }
        }
    }
}
