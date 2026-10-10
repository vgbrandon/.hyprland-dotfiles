import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// CPU y RAM (el reproductor va en la píldora multimedia, MediaPill)
Pill {
    id: root

    // Sin sitio en la barra vertical de un monitor bajo
    visible: !compact
    property int cpu: 0
    property int ram: 0
    property var lastCpu: null

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

    Icon { text: Theme.iCpu; color: Theme.subtext }
    Label { text: root.cpu }
    Icon { text: Theme.iRam; color: Theme.subtext }
    Label { text: root.ram }
}
