pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Historial del portapapeles (Super + Shift + V). cliphist guarda lo copiado (texto e
// imágenes); aquí se vigila el portapapeles. La ventana es modules/clipboard/ClipboardWindow.qml.
// Elegir una entrada la copia y la pega en la ventana donde estabas.
//   quickshell ipc call clipboard toggle | open | close | clear
Singleton {
    id: root

    property bool open: false
    property string query: ""
    // Entradas: { id, line (la de cliphist), text, image, info }
    property var entries: []
    property bool available: true
    // Miniaturas de las imágenes (se decodifican al abrir)
    readonly property string thumbDir: Quickshell.cachePath("clipboard")
    property int thumbsRev: 0

    readonly property var results: {
        const q = query.trim().toLowerCase();
        if (q === "") return entries;
        return entries.filter(e => e.text.toLowerCase().includes(q));
    }

    function toggle() {
        open = !open;
    }
    onOpenChanged: if (open) available ? reload() : checkProc.running = true

    function reload() {
        listProc.running = true;
    }

    // --- Vigilar el portapapeles: cada cosa copiada se guarda en cliphist ---
    Process {
        id: watchText
        command: ["wl-paste", "--type", "text", "--watch", "cliphist", "store"]
        running: root.available
    }
    Process {
        id: watchImage
        command: ["wl-paste", "--type", "image", "--watch", "cliphist", "store"]
        running: root.available
    }

    // ¿Está instalado cliphist? (al iniciar y, si faltaba, al abrir la ventana)
    Process {
        id: checkProc
        command: ["sh", "-c", "command -v cliphist"]
        running: true
        onExited: code => {
            root.available = code === 0;
            if (root.available && root.open) root.reload();
        }
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of this.text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0) continue;
                    const id = line.slice(0, tab), text = line.slice(tab + 1);
                    // Imágenes: "[[ binary data 51 KiB png 1920x1080 ]]"
                    const m = text.match(/^\[\[ binary data (.+?) (\w+) (\d+x\d+) \]\]$/);
                    out.push({ id, line, text: m ? "" : text, image: !!m, info: m ? `${m[3].replace("x", " × ")} · ${m[1]}` : "" });
                }
                root.entries = out;
                root.decodeThumbs();
            }
        }
    }

    // Decodifica las imágenes que aún no tienen miniatura
    function decodeThumbs() {
        const ids = entries.filter(e => e.image).map(e => e.id);
        if (ids.length === 0) return;
        thumbProc.command = ["sh", "-c", 'd="$1"; shift; mkdir -p "$d"; for id; do [ -s "$d/$id" ] || cliphist decode "$id" > "$d/$id"; done',
            "sh", thumbDir, ...ids];
        thumbProc.running = true;
    }
    Process {
        id: thumbProc
        onExited: root.thumbsRev++
    }

    // --- Acciones ---
    // Copia la entrada y, si paste, la pega en la ventana activa (Ctrl+V, o
    // Ctrl+Shift+V en las terminales)
    property bool pasteAfterCopy: false
    function choose(entry, paste) {
        if (!entry) return;
        pasteAfterCopy = paste;
        copyProc.command = ["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", entry.id];
        copyProc.running = true;
        open = false;
    }
    Process {
        id: copyProc
        onExited: if (root.pasteAfterCopy) pasteTimer.restart()
    }
    // Espera a que la ventana recupere el foco del teclado
    Timer {
        id: pasteTimer
        interval: 120
        onTriggered: {
            const app = (Hyprland.activeToplevel?.wayland?.appId ?? "").toLowerCase();
            const terminal = ["kitty", "foot", "alacritty", "wezterm", "ghostty", "konsole", "terminal"].some(t => app.includes(t));
            Hypr.sendShortcut(terminal ? "CTRL SHIFT" : "CTRL", "V");
        }
    }

    function remove(entry) {
        entries = entries.filter(e => e.id !== entry.id);
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "sh", entry.line]);
    }

    function clear() {
        entries = [];
        Quickshell.execDetached(["sh", "-c", 'cliphist wipe; rm -rf "$1"', "sh", thumbDir]);
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
        function clear(): void { root.clear(); }
    }

}
