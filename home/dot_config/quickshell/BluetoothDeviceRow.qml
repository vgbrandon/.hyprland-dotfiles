import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets

// Fila de un dispositivo Bluetooth. Clic = conectar / desconectar / emparejar
Rectangle {
    id: row

    required property BluetoothDevice modelData
    readonly property BluetoothDevice dev: modelData
    readonly property bool busy: dev.pairing || dev.state === BluetoothDeviceState.Connecting || dev.state === BluetoothDeviceState.Disconnecting
    // Tras emparejar, se conecta automáticamente
    property bool connectAfterPair: false

    function activate() {
        if (busy) return;
        if (dev.connected) {
            dev.disconnect();
        } else if (dev.paired) {
            dev.connect();
        } else {
            connectAfterPair = true;
            dev.pair();
        }
    }

    implicitHeight: 52
    radius: Theme.radiusSmall
    color: mouse.containsMouse ? Theme.surfaceHigh : "transparent"

    Connections {
        target: row.dev
        function onPairedChanged() {
            if (row.dev.paired && row.connectAfterPair) {
                row.connectAfterPair = false;
                row.dev.trusted = true;
                row.dev.connect();
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.activate()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 12

        Rectangle {
            implicitWidth: 34
            implicitHeight: 34
            radius: Theme.radiusSmall
            color: row.dev.connected ? Theme.primary : Theme.surfaceHigh

            IconImage {
                id: devIcon
                anchors.centerIn: parent
                implicitSize: 20
                source: row.dev.icon !== "" ? Quickshell.iconPath(row.dev.icon, true) : ""
                visible: source != ""
            }
            Icon {
                anchors.centerIn: parent
                visible: !devIcon.visible
                text: Theme.iBt
                color: row.dev.connected ? Theme.primaryFg : Theme.text
                font.pixelSize: 16
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: row.dev.name || row.dev.deviceName || row.dev.address
            }
            Label {
                Layout.fillWidth: true
                text: {
                    const d = row.dev;
                    if (d.pairing) return "Emparejando…";
                    if (d.state === BluetoothDeviceState.Connecting) return "Conectando…";
                    if (d.state === BluetoothDeviceState.Disconnecting) return "Desconectando…";
                    if (d.connected) return d.batteryAvailable ? `Conectado • ${Math.round(d.battery * 100)}%` : "Conectado";
                    if (d.paired) return "Emparejado";
                    return "Clic para emparejar";
                }
                color: row.dev.connected ? Theme.text : Theme.subtext
                font.pixelSize: Theme.fontSize
            }
        }

        // Olvidar (solo emparejados, al pasar el ratón)
        Rectangle {
            visible: row.dev.paired && (mouse.containsMouse || forgetMouse.containsMouse)
            implicitWidth: 28
            implicitHeight: 28
            radius: 14
            color: forgetMouse.containsMouse ? Theme.surface : "transparent"

            Icon {
                anchors.centerIn: parent
                text: Theme.iClose
                color: Theme.subtext
                font.pixelSize: 14
            }
            MouseArea {
                id: forgetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: row.dev.forget()
            }
        }
    }
}
