import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import qs.components.base
import qs.components.buttons
import qs.components.containers
import qs.services

// Panel de Bluetooth: encender/apagar, dispositivos emparejados y disponibles
BarPopup {
    id: panel

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

    maxHeight: 520

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
    onVisibleChanged: updateDiscovery()

    PanelHeader {
        Layout.rightMargin: 4
        icon: panel.on ? Theme.iBt : Theme.iBtOff
        title: "Bluetooth"
        subtitle: !panel.bt ? "Sin adaptador"
            : panel.blocked ? "Bloqueado"
            : !panel.on ? "Apagado"
            : panel.bt.discovering ? "Buscando dispositivos…" : "Encendido"

        // Buscar de nuevo
        CircleButton {
            id: scanButton
            visible: panel.on
            icon: Theme.iRefresh
            iconSize: 18
            onClicked: panel.bt.discovering = !panel.bt.discovering

            RotationAnimation {
                target: scanButton.iconItem
                from: 0
                to: 360
                duration: 1200
                loops: Animation.Infinite
                running: panel.bt?.discovering ?? false
                onRunningChanged: if (!running) scanButton.iconItem.rotation = 0
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
            spacing: 8

            Section {
                visible: panel.paired.length > 0
                Layout.topMargin: 4
                title: "Mis dispositivos"

                Repeater {
                    model: ScriptModel { values: panel.paired }
                    BluetoothDeviceRow {
                        Layout.fillWidth: true
                    }
                }
            }

            Section {
                Layout.topMargin: 4
                title: "Disponibles"

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
