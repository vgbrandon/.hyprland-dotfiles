import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Networking

// Red (NetworkManager), Bluetooth, notificaciones, ajustes y energía
RowLayout {
    id: root
    spacing: 14

    // Red (NetworkManager)
    readonly property bool wiredUp: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property var wifiNet: Networking.devices.values.find(d => d.type === DeviceType.Wifi)?.networks.values.find(n => n.connected) ?? null
    readonly property BluetoothAdapter bt: Bluetooth.defaultAdapter
    readonly property bool btConnected: bt?.devices.values.some(d => d.connected) ?? false

    // Red: clic = panel de WiFi, clic derecho = encender/apagar WiFi
    Icon {
        id: netIcon
        text: {
            if (root.wiredUp) return Theme.iEthernet;
            if (root.wifiNet) {
                const v = root.wifiNet.signalStrength > 1 ? root.wifiNet.signalStrength / 100 : root.wifiNet.signalStrength;
                return v > 0.75 ? Theme.iWifi4 : v > 0.5 ? Theme.iWifi3 : v > 0.25 ? Theme.iWifi2 : Theme.iWifi1;
            }
            return Networking.wifiEnabled ? Theme.iNoNet : Theme.iWifiOff;
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: e => {
                if (e.button === Qt.RightButton) Networking.wifiEnabled = !Networking.wifiEnabled;
                else wifiPanel.toggle();
            }
        }

        WifiPanel {
            id: wifiPanel
            anchorItem: netIcon
            visible: false
        }
    }
    Icon {
        id: btIcon
        visible: root.bt !== null
        text: !root.bt?.enabled ? Theme.iBtOff : root.btConnected ? Theme.iBtOn : Theme.iBt
        // Clic = panel, clic derecho = encender/apagar
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: e => {
                if (e.button === Qt.RightButton) btPanel.setPower(!btPanel.on);
                else btPanel.toggle();
            }
        }

        BluetoothPanel {
            id: btPanel
            anchorItem: btIcon
            visible: false
        }
    }
    // Campana: abre el centro de notificaciones. Con notificaciones
    // muestra un puntito sobre la campana (en vez de la cantidad).
    Icon {
        id: bell
        text: Notifs.dnd ? Theme.iBellOff : Notifs.count > 0 ? Theme.iBellBadge : Theme.iBell

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Notifs.toggleCenter()
        }
    }
    // Ajustes rápidos (clic = panel)
    ConfigButton {}
    Icon {
        text: Theme.iPower
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: PowerMenu.toggle()
        }
    }
}
