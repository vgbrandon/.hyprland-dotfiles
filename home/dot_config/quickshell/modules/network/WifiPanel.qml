import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs.components.base
import qs.components.containers
import qs.services

// Panel de WiFi (NetworkManager): encender/apagar, redes disponibles, conectar
BarPopup {
    id: panel

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property bool on: Networking.wifiEnabled
    // Conectada primero, luego guardadas, luego por señal
    readonly property var networks: (wifi?.networks.values ?? []).filter(n => n.name !== "").slice()
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))

    maxHeight: 560

    // Busca redes solo mientras el panel está abierto
    Binding {
        when: panel.wifi !== null
        target: panel.wifi
        property: "scannerEnabled"
        value: panel.visible && panel.on
    }

    PanelHeader {
        Layout.rightMargin: 4
        icon: panel.on ? Theme.iWifi : Theme.iWifiOff
        title: "Wi-Fi"
        subtitle: !panel.wifi ? "Sin tarjeta WiFi"
            : !Networking.wifiHardwareEnabled ? "Bloqueado por hardware"
            : !panel.on ? "Apagado"
            : panel.networks.find(n => n.connected)?.name ?? "Sin conectar"

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

    Section {
        visible: panel.on && panel.wifi !== null
        Layout.topMargin: 4
        Layout.fillHeight: true
        title: "Redes"

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: list.implicitHeight
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
