pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Fondo de pantalla dibujado por Quickshell (con fundido al cambiar) y su selector.
// El tema se genera a partir del fondo actual. Las capas del fondo y el selector
// están en modules/wallpaper.
//   quickshell ipc call wallpaper toggle
Singleton {
    id: root

    readonly property string dir: `${Quickshell.env("HOME")}/Pictures`
    property bool open: false
    property var files: []
    // Miniatura en caché de cada fondo (ruta -> miniatura)
    property var thumbs: ({})
    // Fondo actual (se guarda y se restaura al iniciar)
    property string current: ""

    function toggle() {
        open = !open;
    }

    function choose(path) {
        current = path;
        state.setText(JSON.stringify({ wallpaper: path }));
        open = false;
    }

    onCurrentChanged: Theme.setWallpaper(current)
    onOpenChanged: if (open) listProc.running = true
    // Prepara las miniaturas al iniciar, para que el selector abra al instante
    Component.onCompleted: listProc.running = true

    IpcHandler {
        target: "wallpaper"

        function toggle(): void { root.toggle(); }
        function set(path: string): void { root.choose(path); }
    }

    Process {
        id: listProc
        command: ["sh", Quickshell.shellPath("scripts/wallpaper-thumbs.sh"), root.dir, Quickshell.cachePath("wallpaper-thumbs")]
        stdout: StdioCollector {
            onStreamFinished: {
                const files = [];
                const thumbs = {};
                for (const line of this.text.split("\n")) {
                    const [file, thumb] = line.split("\t");
                    if (!file) continue;
                    files.push(file);
                    thumbs[file] = thumb || file;
                }
                root.thumbs = thumbs;
                root.files = files;
                if (root.current === "" && root.files.length > 0) root.choose(root.files[0]);
            }
        }
    }

    // Fondo guardado; si no hay, se toma el que tenga hyprpaper o, si no está,
    // la primera imagen de la carpeta
    FileView {
        id: state
        path: Quickshell.statePath("wallpaper.json")
        onLoaded: {
            try {
                root.current = JSON.parse(text()).wallpaper ?? "";
            } catch (e) {}
            if (root.current === "") initProc.running = true;
        }
        onLoadFailed: initProc.running = true
    }
    Process {
        id: initProc
        command: ["hyprctl", "hyprpaper", "listactive"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.split("\n").find(l => l.includes(": /")) ?? "";
                const path = line.slice(line.indexOf(": ") + 2).trim();
                if (root.current !== "") return;
                if (path !== "") root.current = path;
                else listProc.running = true;
            }
        }
    }
}
