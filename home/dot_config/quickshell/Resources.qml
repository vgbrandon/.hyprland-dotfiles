import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// CPU, RAM y reproductor actual (como el primer grupo de la captura)
Pill {
    id: root

    // Sin sitio (barra vertical en un monitor bajo): solo el reproductor
    property bool compact: false
    property int cpu: 0
    property int ram: 0
    property var lastCpu: null

    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const v = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = v[3] + v[4];
            const total = v.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total;
                if (dt > 0)
                    root.cpu = Math.round(100 * (1 - (idle - root.lastCpu.idle) / dt));
            }
            root.lastCpu = { idle, total };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const get = k => Number(text().match(new RegExp(k + ":\\s+(\\d+)"))[1]);
            root.ram = Math.round(100 * (1 - get("MemAvailable") / get("MemTotal")));
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { stat.reload(); meminfo.reload(); }
    }

    Icon { visible: !root.compact; text: Theme.iCpu; color: Theme.subtext }
    Label { visible: !root.compact; text: root.cpu }
    Icon { visible: !root.compact; text: Theme.iRam; color: Theme.subtext }
    Label { visible: !root.compact; text: root.ram }

    // Botón play/pausa
    Rectangle {
        visible: root.player !== null
        implicitWidth: 22
        implicitHeight: 22
        radius: 11
        color: "transparent"
        border.color: Theme.text
        border.width: 1.5

        Icon {
            anchors.centerIn: parent
            text: root.player?.isPlaying ? Theme.iPause : Theme.iPlay
            font.pixelSize: 13
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.player?.canTogglePlaying) root.player.togglePlaying()
        }
    }

    // Barra vertical: no cabe el título, una nota abre el panel
    Icon {
        visible: root.player !== null && root.vertical
        text: Theme.iMusic

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: mediaPanel.toggle()
        }
    }

    Label {
        visible: root.player !== null && !root.vertical
        Layout.maximumWidth: 200
        Layout.leftMargin: 4
        text: {
            const p = root.player;
            if (!p) return "";
            return p.trackArtist ? `${p.trackTitle} • ${p.trackArtist}` : p.trackTitle;
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: mediaPanel.toggle()
        }
    }

    MediaPanel {
        id: mediaPanel
        player: root.player
        anchorItem: root
        visible: false
    }
}
