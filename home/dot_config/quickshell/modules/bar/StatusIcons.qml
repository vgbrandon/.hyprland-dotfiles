import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.components.base
import qs.components.buttons
import qs.modules.github
import qs.modules.network
import qs.modules.servers
import qs.services

// Bandeja, red (NetworkManager), Bluetooth, asistente de IA, notificaciones, ajustes y energía
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

    // Servidores locales: solo si hay alguno en marcha, con cuántos
    Item {
        id: serversIcon
        visible: LocalServers.servers.length > 0
        implicitWidth: serversRow.implicitWidth
        implicitHeight: serversRow.implicitHeight

        Row {
            id: serversRow
            spacing: 3
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.iServer
                color: Theme.primary
            }
            Label {
                visible: !Config.barVertical
                anchors.verticalCenter: parent.verticalCenter
                text: LocalServers.servers.length
                color: Theme.primary
                font.pixelSize: Theme.fontSize
            }
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: serversPanel.toggle()
        }
        Connections {
            target: LocalServers
            function onPanelRequested() {
                serversPanel.toggleOnFocusedScreen();
            }
        }
        ServersPanel {
            id: serversPanel
            anchorItem: serversIcon
        }
    }

    // GitHub: la cuenta de gh y git (iniciar sesión, cambiar de cuenta…)
    IconButton {
        id: ghIcon
        text: Theme.iGithub
        // Esperando a que se autorice el inicio de sesión: en color
        color: GitHub.loggingIn ? Theme.primary : Theme.text
        onClicked: ghPanel.toggle()

        Connections {
            target: GitHub
            function onPanelRequested() {
                ghPanel.toggleOnFocusedScreen();
            }
        }
        GitHubPanel {
            id: ghPanel
            anchorItem: ghIcon
        }
    }

    // Asistente de IA (logo de OpenCode): de color mientras trabaja; amarillo si espera un permiso
    Item {
        implicitWidth: aiLogo.implicitWidth
        implicitHeight: aiLogo.implicitHeight

        OpenCodeLogo {
            id: aiLogo
            size: 15
            color: AI.permissions.length > 0 ? Theme.warning : AI.busy ? Theme.primary : Theme.text
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: AI.toggle()
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
