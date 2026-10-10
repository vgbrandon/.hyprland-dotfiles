pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Módulo de pantallas: posición, resolución y Hz, escala,
// rotación, activar/desactivar, VRR y cuál es el monitor principal.
//   quickshell ipc call displays toggle | preview (monitors.lua que se escribiría)
// Al aplicar escribe ~/.config/hypr/monitors.lua (el que carga hyprland.lua), recarga
// Hyprland y pide confirmar en 10 s; si no se confirma, vuelve a lo anterior.
Singleton {
    id: root

    property bool open: false
    property real closedAt: 0

    function toggle() {
        if (!open && Date.now() - closedAt < 300) return;
        open = !open;
        if (open) refresh();
    }
    function close() {
        if (!open || confirming) return;
        open = false;
        closedAt = Date.now();
    }

    readonly property string monitorsPath: Quickshell.env("HOME") + "/.config/hypr/monitors.lua"

    // Monitores tal como están ahora (hyprctl) y la copia que se edita:
    // [{ name, description, enabled, width, height, rate, x, y, scale, transform, vrr, modes }]
    property var current: []
    property var edits: []
    property int selected: 0
    readonly property var selectedEdit: edits[selected] ?? null
    readonly property bool dirty: JSON.stringify(edits) !== JSON.stringify(current)

    // --- Monitor principal (lo usa la pantalla de inicio de sesión) ---
    // Elegido a mano (Config.primaryMonitor) si está conectado; si no, automático:
    // el más grande, y si empatan, el de más a la izquierda y luego el de más arriba
    readonly property string primary: {
        const list = current.filter(m => m.enabled);
        if (list.some(m => m.name === Config.primaryMonitor)) return Config.primaryMonitor;
        return autoPrimary(list);
    }
    function autoPrimary(list) {
        if (list.length === 0) return "";
        const area = m => m.width * m.height;
        const better = (a, b) => area(b) !== area(a) ? area(b) > area(a)
            : b.x !== a.x ? b.x < a.x : b.y < a.y;
        return list.reduce((a, b) => better(a, b) ? b : a, list[0]).name;
    }
    onPrimaryChanged: Theme.shareWithGreeter()

    // --- Lectura ---
    function refresh() {
        readProc.running = true;
    }

    Process {
        id: readProc
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(this.text).map(m => root.fromHyprland(m));
                    root.current = list;
                    root.edits = JSON.parse(JSON.stringify(list));
                    if (root.selected >= list.length) root.selected = 0;
                } catch (e) {
                    console.warn("displays:", e);
                }
            }
        }
    }
    Component.onCompleted: refresh()

    function fromHyprland(m) {
        // Modos sin repetir, como "1920x1080@60.00"
        const modes = [...new Set((m.availableModes ?? []).map(s => s.replace(/Hz$/, "")))];
        let width = m.width, height = m.height;
        if (!(width > 0) && modes.length > 0) [width, height] = modes[0].split("@")[0].split("x").map(Number);
        // La frecuencia tal como la escribe Hyprland en sus modos (p. ej. "59.79")
        const match = modes.find(s => {
            const [res, hz] = s.split("@");
            return res === `${width}x${height}` && Math.abs(Number(hz) - m.refreshRate) < 0.01;
        });
        return {
            name: m.name,
            description: `${m.make ?? ""} ${m.model ?? ""}`.trim() || m.description,
            enabled: !m.disabled,
            width, height,
            rate: match ? match.split("@")[1] : Number(m.refreshRate).toFixed(2),
            x: m.x, y: m.y,
            scale: Math.round(m.scale * 100) / 100,
            transform: m.transform % 4,
            vrr: !!m.vrr,
            modes
        };
    }

    // --- Edición ---
    function update(index, changes) {
        edits = edits.map((e, i) => i === index ? Object.assign({}, e, changes) : e);
    }
    function discard() {
        edits = JSON.parse(JSON.stringify(current));
    }

    // Tamaño en el escritorio (en píxeles lógicos): girado y dividido por la escala
    function logicalSize(e) {
        const rotated = e.transform % 2 === 1;
        return {
            w: Math.round((rotated ? e.height : e.width) / e.scale),
            h: Math.round((rotated ? e.width : e.height) / e.scale)
        };
    }

    // Resoluciones disponibles (de mayor a menor) y frecuencias de una resolución
    function resolutions(e) {
        const list = [...new Set(e.modes.map(s => s.split("@")[0]))];
        return list.sort((a, b) => {
            const [aw, ah] = a.split("x").map(Number), [bw, bh] = b.split("x").map(Number);
            return bw * bh - aw * ah || bw - aw;
        });
    }
    function rates(e, resolution) {
        const list = [...new Set(e.modes.filter(s => s.startsWith(resolution + "@")).map(s => s.split("@")[1]))];
        return list.sort((a, b) => Number(b) - Number(a));
    }

    // Al soltar un monitor arrastrado: se pega a los bordes de los demás si está cerca,
    // y todo se corre para que la esquina superior izquierda quede en 0,0
    function snap(index, threshold) {
        const e = edits[index];
        const s = logicalSize(e);
        let bestX = e.x, bestY = e.y, dx = threshold, dy = threshold;
        edits.forEach((o, i) => {
            if (i === index || !o.enabled) return;
            const so = logicalSize(o);
            for (const c of [o.x + so.w, o.x - s.w, o.x, o.x + so.w - s.w]) {
                if (Math.abs(c - e.x) < dx) { dx = Math.abs(c - e.x); bestX = c; }
            }
            for (const c of [o.y + so.h, o.y - s.h, o.y, o.y + so.h - s.h]) {
                if (Math.abs(c - e.y) < dy) { dy = Math.abs(c - e.y); bestY = c; }
            }
        });
        update(index, { x: Math.round(bestX), y: Math.round(bestY) });
        normalize();
    }
    function normalize() {
        const on = edits.filter(e => e.enabled);
        if (on.length === 0) return;
        const minX = Math.min(...on.map(e => e.x)), minY = Math.min(...on.map(e => e.y));
        if (minX !== 0 || minY !== 0)
            edits = edits.map(e => Object.assign({}, e, { x: e.x - minX, y: e.y - minY }));
    }

    // --- Aplicar (con confirmación) ---
    property bool confirming: false
    property int countdown: 0
    property string backup: ""

    function toLua(list) {
        const lines = [
            "-- Pantallas: lo genera el módulo de pantallas de Quickshell (Displays.qml).",
            "-- Se puede editar a mano, pero el módulo lo reescribe al aplicar cambios.",
            ""
        ];
        for (const e of list) {
            if (!e.enabled) {
                lines.push(`hl.monitor({ output = "${e.name}", disabled = true })`);
                continue;
            }
            lines.push("hl.monitor({",
                `    output = "${e.name}",`,
                `    mode = "${e.width}x${e.height}@${e.rate}",`,
                `    position = "${e.x}x${e.y}",`,
                `    scale = ${e.scale},`,
                `    transform = ${e.transform},`,
                `    vrr = ${e.vrr ? 1 : 0}`,
                "})");
        }
        return lines.join("\n") + "\n";
    }

    function apply() {
        if (!dirty || confirming) return;
        // Al menos un monitor encendido
        if (!edits.some(e => e.enabled)) return;
        monitorsFile.reload();
        backup = monitorsFile.text();
        monitorsFile.setText(toLua(edits));
        reloadProc.running = true;
        countdown = 10;
        confirming = true;
        countdownTimer.restart();
    }

    function keep() {
        if (!confirming) return;
        confirming = false;
        countdownTimer.stop();
        chezmoiProc.running = true;
        refreshLater.restart();
    }

    function revert() {
        if (!confirming) return;
        confirming = false;
        countdownTimer.stop();
        monitorsFile.setText(backup);
        reloadProc.running = true;
        refreshLater.restart();
    }

    FileView {
        id: monitorsFile
        path: root.monitorsPath
        blockLoading: true
        printErrors: false
    }

    Process {
        id: reloadProc
        command: ["hyprctl", "reload"]
        onExited: refreshLater.restart()
    }
    // Hyprland tarda un momento en reconfigurar los monitores
    Timer {
        id: refreshLater
        interval: 800
        onTriggered: root.refresh()
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown--;
            if (root.countdown <= 0) root.revert();
        }
    }

    // monitors.lua está en los dotfiles: se sincroniza con chezmoi al confirmar
    Process {
        id: chezmoiProc
        command: ["sh", "-c", `command -v chezmoi >/dev/null || exit 0
            chezmoi managed --include=files | grep -qx ".config/hypr/monitors.lua" || exit 0
            chezmoi add "$HOME/.config/hypr/monitors.lua"`]
    }

    IpcHandler {
        target: "displays"

        function toggle(): void { root.toggle(); }
        function open(): void { if (!root.open) root.toggle(); }
        function close(): void { root.close(); }
        // Muestra el monitors.lua que se escribiría con los cambios actuales, sin aplicarlo
        function preview(): string { return root.toLua(root.edits); }
    }

    DisplaysWindow {}
}
