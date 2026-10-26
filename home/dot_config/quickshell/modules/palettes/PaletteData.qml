import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Los datos de las guías: `paleta roles` sobre el fondo actual (lo que saca el
// generador, los papeles del tema y de qué color sale cada uno). Se regenera al llamar
// a refresh() y al cambiar de fondo mientras active es true.
Item {
    id: data
    property bool active: false
    readonly property string out: Quickshell.env("HOME") + "/.cache/velure/paleta-actual.json"
    property var d: null
    readonly property var r: d ? d.roles : null
    readonly property var sec: d ? d.sections : null
    readonly property var org: d ? d.origins : null
    readonly property bool running: gen.running

    function refresh() {
        gen.running = true;
    }
    onActiveChanged: if (active) refresh()

    Process {
        id: gen
        command: [Quickshell.env("HOME") + "/.local/bin/paleta", "roles", Theme.wallpaper, "-o", data.out]
        onExited: file.reload()
    }
    FileView {
        id: file
        path: data.out
        printErrors: false
        onLoaded: {
            try {
                data.d = JSON.parse(text())[0] ?? null;
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
