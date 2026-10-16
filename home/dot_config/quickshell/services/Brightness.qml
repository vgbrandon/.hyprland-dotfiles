pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Brillo de los monitores externos por DDC/CI (ddcutil; el acceso a /dev/i2c-* lo da
// el módulo i2c-dev). Al iniciar detecta los monitores y los empareja con las salidas
// de Hyprland (DP-4, HDMI-A-1…). DDC/CI es lento: los cambios seguidos (rueda,
// arrastre) se agrupan en una sola orden por monitor. Al cambiar, el aviso flotante.
//   quickshell ipc call brightness up | down | set 60
Singleton {
    id: root

    property bool installed: false
    // { output, bus, model, value (0-1) }
    property var displays: []
    readonly property bool available: displays.length > 0
    property bool detecting: false

    function find(output) {
        return displays.find(d => d.output === output) ?? null;
    }
    function levelOf(output) {
        return find(output)?.value ?? 0;
    }

    // Cambiar: fracción 0-1. Se ve al instante; la orden al monitor va un poco después
    function set(output, fraction, osd) {
        const d = find(output);
        if (!d) return;
        const v = Math.max(0, Math.min(1, Math.round(fraction * 100) / 100));
        displays = displays.map(x => x.output === output ? Object.assign({}, x, { value: v }) : x);
        const p = Object.assign({}, pending);
        p[output] = v;
        pending = p;
        sendTimer.restart();
        if (osd !== false) Osd.show("brightness", d.model || output, v);
    }
    function step(delta) {
        const out = Hypr.focusedScreen?.name ?? "";
        const d = find(out) ?? displays[0];
        if (d) set(d.output, d.value + delta);
    }

    // --- Detección ---
    function detect() {
        if (!installed || detecting) return;
        detecting = true;
        detectProc.running = true;
    }
    Process {
        command: ["sh", "-c", "command -v ddcutil"]
        running: true
        onExited: code => {
            root.installed = code === 0;
            root.detect();
        }
    }
    Process {
        id: detectProc
        command: ["ddcutil", "detect", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = [];
                let cur = null;
                for (const line of this.text.split("\n")) {
                    if (/^Display \d+/.test(line)) {
                        cur = { output: "", bus: -1, model: "", value: 0 };
                        found.push(cur);
                    } else if (cur) {
                        let m;
                        if ((m = line.match(/I2C bus:\s*\/dev\/i2c-(\d+)/))) cur.bus = Number(m[1]);
                        else if ((m = line.match(/DRM[ _]connector:\s*card\d+-(\S+)/))) cur.output = m[1];
                        else if ((m = line.match(/Monitor:\s*(.+)/))) cur.model = (m[1].split(":")[1] ?? m[1]).trim();
                    }
                }
                root.detected = found.filter(d => d.bus >= 0 && d.output !== "");
                root.readNext(0);
            }
        }
        onExited: if (root.detected.length === 0) root.detecting = false
    }
    property var detected: []

    // Brillo actual de cada uno, de uno en uno
    function readNext(i) {
        if (i >= detected.length) {
            displays = detected;
            detecting = false;
            return;
        }
        readProc.index = i;
        readProc.command = ["ddcutil", "getvcp", "10", "--bus", String(detected[i].bus), "--brief"];
        readProc.running = true;
    }
    Process {
        id: readProc
        property int index: 0
        stdout: StdioCollector {
            onStreamFinished: {
                // "VCP 10 C 50 100": actual y máximo
                const m = this.text.match(/VCP\s+10\s+\S+\s+(\d+)\s+(\d+)/);
                if (m) {
                    const arr = root.detected.slice();
                    arr[readProc.index] = Object.assign({}, arr[readProc.index], { value: Number(m[1]) / Math.max(1, Number(m[2])) });
                    root.detected = arr;
                }
            }
        }
        onExited: root.readNext(readProc.index + 1)
    }

    // --- Enviar los cambios (agrupados) ---
    property var pending: ({})
    Timer {
        id: sendTimer
        interval: 150
        onTriggered: root.sendNext()
    }
    function sendNext() {
        if (setProc.running) return;
        const output = Object.keys(pending)[0];
        if (output === undefined) return;
        const v = pending[output];
        const p = Object.assign({}, pending);
        delete p[output];
        pending = p;
        const d = find(output);
        if (!d) return sendNext();
        setProc.command = ["ddcutil", "setvcp", "10", String(Math.round(v * 100)), "--bus", String(d.bus), "--noverify"];
        setProc.running = true;
    }
    Process {
        id: setProc
        onExited: root.sendNext()
    }

    // Monitores conectados o desconectados: volver a detectar
    Connections {
        target: Quickshell
        function onScreensChanged() {
            redetect.restart();
        }
    }
    Timer {
        id: redetect
        interval: 2000
        onTriggered: root.detect()
    }

    IpcHandler {
        target: "brightness"

        function up(): void { root.step(0.05); }
        function down(): void { root.step(-0.05); }
        // Porcentaje (0-100) del monitor enfocado
        function set(percent: int): void {
            const out = Hypr.focusedScreen?.name ?? "";
            root.set(root.find(out) ? out : root.displays[0]?.output ?? "", percent / 100);
        }
    }
}
