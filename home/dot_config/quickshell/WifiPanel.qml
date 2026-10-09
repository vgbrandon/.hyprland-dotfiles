import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking

// Panel de WiFi (NetworkManager): encender/apagar, redes disponibles, conectar
PopupWindow {
    id: panel

    required property Item anchorItem
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property bool on: Networking.wifiEnabled
    // Conectada primero, luego guardadas, luego por señal
    readonly property var networks: (wifi?.networks.values ?? []).filter(n => n.name !== "").slice()
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))

    property real closedAt: 0

    // Abre/cierra desde la barra. Si el mismo clic acaba de cerrarlo, no lo reabre.
    function toggle() {
        if (!visible && Date.now() - closedAt < 300) return;
        visible = !visible;
    }

    anchor.item: anchorItem
    anchor.rect.x: popupPos.x
    anchor.rect.y: popupPos.y
    // Junto a la barra, esté donde esté
    readonly property point popupPos: Config.popupPos(anchorItem, implicitWidth, implicitHeight, visible)
    implicitWidth: 360
    implicitHeight: Math.min(560, layout.implicitHeight + 24)
    color: "transparent"

    // Busca redes solo mientras el panel está abierto
    Binding {
        when: panel.wifi !== null
        target: panel.wifi
        property: "scannerEnabled"
        value: panel.visible && panel.on
    }

    // Clic fuera del panel = cerrar
    HyprlandFocusGrab {
        id: grab
        windows: [panel]
        onCleared: {
            panel.visible = false;
            panel.closedAt = Date.now();
        }
    }
    onVisibleChanged: {
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
                    text: panel.on ? Theme.iWifi : Theme.iWifiOff
                    font.pixelSize: 20
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Label {
                        text: "Wi-Fi"
                        font.pixelSize: 16
                    }
                    Label {
                        Layout.fillWidth: true
                        text: !panel.wifi ? "Sin tarjeta WiFi"
                            : !Networking.wifiHardwareEnabled ? "Bloqueado por hardware"
                            : !panel.on ? "Apagado"
                            : panel.networks.find(n => n.connected)?.name ?? "Sin conectar"
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize
                    }
                }
                Switch {
                    visible: panel.wifi !== null
                    checked: panel.on
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            // Cable (si está conectado)
            RowLayout {
                visible: panel.wired !== null
                Layout.leftMargin: 10
                spacing: 12

                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: Theme.radiusSmall
                    color: Theme.surfaceHigh

                    Icon {
                        anchors.centerIn: parent
                        text: Theme.iEthernet
                        font.pixelSize: 18
                    }
                }
                ColumnLayout {
                    spacing: 0
                    Label { text: "Cable" }
                    Label {
                        text: panel.wired?.linkSpeed ? `Conectado • ${panel.wired.linkSpeed} Mb/s` : "Conectado"
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize
                    }
                }
            }

            Label {
                visible: panel.on && panel.wifi !== null
                Layout.leftMargin: 8
                Layout.topMargin: 4
                text: "Redes"
                color: Theme.subtext
                font.pixelSize: Theme.fontSize
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: list.implicitHeight
                visible: panel.on && panel.wifi !== null
                contentHeight: list.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: list
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: ScriptModel {
                            values: panel.networks
                        }
                        WifiNetworkRow {
                            Layout.fillWidth: true
                        }
                    }
                    Label {
                        visible: panel.networks.length === 0
                        Layout.leftMargin: 8
                        Layout.bottomMargin: 6
                        text: "Buscando redes…"
                        color: Theme.dot
                        font.pixelSize: Theme.fontSize
                    }
                }
            }
        }
    }
}
