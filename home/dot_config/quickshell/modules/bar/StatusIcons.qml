import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.components.buttons
import qs.modules.network
import qs.services

// Bandeja, red (NetworkManager), Bluetooth, notificaciones, ajustes y energía
// (en columna si la barra está a un lado)
GridLayout {
    id: root

    property bool compact: false
    columns: Config.barVertical ? 1 : -1
    rowSpacing: compact ? 7 : 10
    columnSpacing: 14

    // Centra los iconos en la columna (si no, quedan a la izquierda)
    Component.onCompleted: {
        for (const child of children)
            child.Layout.alignment = Qt.AlignCenter;
    }

    // Red (NetworkManager)
    readonly property bool wiredUp: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property var wifiNet: Networking.devices.values.find(d => d.type === DeviceType.Wifi)?.networks.values.find(n => n.connected) ?? null
    readonly property BluetoothAdapter bt: Bluetooth.defaultAdapter
    readonly property bool btConnected: bt?.devices.values.some(d => d.connected) ?? false

    // Bandeja del sistema (apps en segundo plano)
    Tray {}

    // Red: clic = panel de WiFi, clic derecho = encender/apagar WiFi
    IconButton {
        id: netIcon
        text: {
            if (root.wiredUp) return Theme.iEthernet;
            if (root.wifiNet) {
                const v = root.wifiNet.signalStrength > 1 ? root.wifiNet.signalStrength / 100 : root.wifiNet.signalStrength;
                return v > 0.75 ? Theme.iWifi4 : v > 0.5 ? Theme.iWifi3 : v > 0.25 ? Theme.iWifi2 : Theme.iWifi1;
            }
            return Networking.wifiEnabled ? Theme.iNoNet : Theme.iWifiOff;
        }
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: button => {
            if (button === Qt.RightButton) Networking.wifiEnabled = !Networking.wifiEnabled;
            else wifiPanel.toggle();
        }

        WifiPanel {
            id: wifiPanel
            anchorItem: netIcon
        }
    }

    // Bluetooth: clic = panel, clic derecho = encender/apagar
    IconButton {
        id: btIcon
        visible: root.bt !== null
        text: !root.bt?.enabled ? Theme.iBtOff : root.btConnected ? Theme.iBtOn : Theme.iBt
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: button => {
            if (button === Qt.RightButton) btPanel.setPower(!btPanel.on);
            else btPanel.toggle();
        }

        BluetoothPanel {
            id: btPanel
            anchorItem: btIcon
        }
    }

    // Campana: abre el centro de notificaciones. Con notificaciones
    // muestra un puntito sobre la campana (en vez de la cantidad).
    IconButton {
        text: Notifs.dnd ? Theme.iBellOff : Notifs.count > 0 ? Theme.iBellBadge : Theme.iBell
        onClicked: Notifs.toggleCenter()
    }

    // Ajustes rápidos
    IconButton {
        text: Theme.iSettings
        onClicked: Config.toggle()
    }

    IconButton {
        text: Theme.iPower
        onClicked: PowerMenu.toggle()
    }
}
