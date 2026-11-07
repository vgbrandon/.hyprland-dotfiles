import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Los datos de las guías: `velure tokens` sobre el fondo actual (los colores de la
// imagen, los tokens y de qué color sale cada acento). Se regenera al llamar
// a refresh() y al cambiar de fondo mientras active es true.
Item {
    id: data
    property bool active: false
    readonly property string out: Quickshell.env("HOME") + "/.cache/velure/tokens-actuales.json"
    property var d: null
    readonly property var r: d ? d.tokens : null
    readonly property var org: d ? d.origins : null
    readonly property bool running: gen.running

    function refresh() {
        gen.running = true;
    }
    onActiveChanged: if (active) refresh()

    Process {
        id: gen
        command: [Quickshell.env("HOME") + "/.local/bin/velure", "tokens", Theme.wallpaper, "-o", data.out]
        onExited: file.reload()
    }
    FileView {
        id: file
        path: data.out
        printErrors: false
        onLoaded: {
            try {
                data.d = JSON.parse(text());
            } catch (e) {}
        }
    }
    Connections {
        target: Theme
        function onWallpaperChanged() {
            if (data.active && Theme.wallpaper !== "") data.refresh();
        }
    }
}
