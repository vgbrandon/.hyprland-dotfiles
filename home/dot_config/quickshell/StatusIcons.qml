import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Bluetooth

// Red (lee /sys/class/net, no necesita NetworkManager) y Bluetooth
RowLayout {
    id: root
    spacing: 14

    property string net: ""
    readonly property BluetoothAdapter bt: Bluetooth.defaultAdapter
    readonly property bool btConnected: bt?.devices.values.some(d => d.connected) ?? false

    Process {
        id: netProc
        command: ["sh", "-c", "for d in /sys/class/net/*; do [ \"${d##*/}\" = lo ] && continue; [ \"$(cat $d/operstate)\" = up ] || continue; [ -d $d/wireless ] && echo wifi || echo ethernet; done | sort -u | head -1"]
        stdout: StdioCollector {
            onStreamFinished: root.net = this.text.trim()
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    Icon {
        text: root.net === "ethernet" ? Theme.iEthernet : root.net === "wifi" ? Theme.iWifi : Theme.iNoNet
    }
    Icon {
        visible: root.bt !== null
        text: !root.bt?.enabled ? Theme.iBtOff : root.btConnected ? Theme.iBtOn : Theme.iBt
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.bt.enabled = !root.bt.enabled
        }
    }
    Icon {
        text: Theme.iPower
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: PowerMenu.toggle()
        }
    }
}
