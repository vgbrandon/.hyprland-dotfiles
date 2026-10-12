pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Datos del sistema para la píldora (CPU y RAM, siempre) y el panel del sistema
// (lo detallado: scripts/sysinfo.py, que solo corre mientras el panel está abierto).
//   quickshell ipc call system toggle
Singleton {
    id: root

    // --- Siempre (cada 2 s, leyendo /proc) ---
    property int cpu: 0
    property var lastCpu: null
    // Últimos 60 valores de CPU (2 minutos) para la gráfica
    property var cpuHistory: []
    property real ramUsed: 0 // bytes
    property real ramTotal: 0
    property real swapUsed: 0
    property real swapTotal: 0
    readonly property int ram: ramTotal > 0 ? Math.round(100 * ramUsed / ramTotal) : 0

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const v = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = v[3] + v[4];
            const total = v.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total;
                if (dt > 0) {
                    root.cpu = Math.round(100 * (1 - (idle - root.lastCpu.idle) / dt));
                    root.cpuHistory = root.cpuHistory.concat([root.cpu]).slice(-60);
                }
            }
            root.lastCpu = { idle, total };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const get = k => Number(text().match(new RegExp(k + ":\\s+(\\d+)"))?.[1] ?? 0) * 1024;
            root.ramTotal = get("MemTotal");
            root.ramUsed = root.ramTotal - get("MemAvailable");
            root.swapTotal = get("SwapTotal");
            root.swapUsed = root.swapTotal - get("SwapFree");
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
        }
    }

    // --- Detallado (solo con el panel abierto) ---
    property bool detailed: false
    // Última línea del script: cpuTemp, cpuFreq, cpus, gpu, disks, uptime, procs…
    property var info: null
    // Velocidad de la red en bytes/s
    property real netDown: 0
    property real netUp: 0
    property var lastNet: null

    // Datos fijos
    property string cpuModel: ""
    property string hostname: ""
    property string kernel: ""

    Process {
        running: root.detailed
        command: ["python3", "-I", Quickshell.shellDir + "/scripts/sysinfo.py"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const d = JSON.parse(line);
                    const now = Date.now();
                    if (root.lastNet) {
                        const dt = (now - root.lastNet.t) / 1000;
                        root.netDown = Math.max(0, (d.netRx - root.lastNet.rx) / dt);
                        root.netUp = Math.max(0, (d.netTx - root.lastNet.tx) / dt);
                    }
                    root.lastNet = { t: now, rx: d.netRx, tx: d.netTx };
                    root.info = d;
                } catch (e) {}
            }
        }
        onRunningChanged: if (!running) root.lastNet = null
    }

    FileView {
        path: "/proc/cpuinfo"
        onLoaded: {
            const m = text().match(/model name\s*:\s*(.+)/);
            root.cpuModel = m ? m[1].replace(/\s+\d+-Core Processor$/, "").trim() : "";
        }
    }
    FileView {
        path: "/proc/sys/kernel/hostname"
        onLoaded: root.hostname = text().trim()
    }
    FileView {
        path: "/proc/sys/kernel/osrelease"
        onLoaded: root.kernel = text().trim()
    }

    // Pide abrir/cerrar el panel (lo abre la píldora del monitor enfocado)
    signal panelRequested()

    IpcHandler {
        target: "system"
        function toggle(): void { root.panelRequested(); }
    }

    // --- Formato ---
    function bytes(n) {
        if (n >= 1e12) return `${(n / 1e12).toFixed(1)} TB`;
        if (n >= 1e9) return `${(n / 1e9).toFixed(1)} GB`;
        if (n >= 1e6) return `${(n / 1e6).toFixed(0)} MB`;
        if (n >= 1e3) return `${(n / 1e3).toFixed(0)} KB`;
        return `${Math.round(n)} B`;
    }
    function speed(n) {
        return n >= 1e6 ? `${(n / 1e6).toFixed(1)} MB/s` : `${Math.round(n / 1e3)} KB/s`;
    }
    function duration(seconds) {
        const d = Math.floor(seconds / 86400), h = Math.floor(seconds % 86400 / 3600), m = Math.floor(seconds % 3600 / 60);
        return d > 0 ? `${d} d ${h} h` : h > 0 ? `${h} h ${m} min` : `${m} min`;
    }
}
