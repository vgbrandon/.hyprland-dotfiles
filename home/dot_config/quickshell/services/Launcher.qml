pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Lanzador de aplicaciones. Se abre con: quickshell ipc call launcher toggle
// La ventana es modules/launcher/LauncherWindow.qml.
Singleton {
    id: root

    property bool open: false
    property string query: ""
    // Veces que se abrió cada app ({ id: número }), guardado en disco
    property var usage: ({})

    // Más usadas primero; a igualdad, orden alfabético
    readonly property var apps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => (usage[b.id] ?? 0) - (usage[a.id] ?? 0) || a.name.localeCompare(b.name))

    // Coincidencias ordenadas: empieza por > palabra empieza por > contiene > otros campos.
    // Dentro de cada nivel se mantiene el orden por uso (sort estable).
    readonly property var results: {
        const q = query.trim().toLowerCase();
        if (q === "") return apps;
        const score = a => {
            const name = a.name.toLowerCase();
            if (name.startsWith(q)) return 4;
            if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 3;
            if (name.includes(q)) return 2;
            const extra = [a.genericName, a.comment, a.id, ...(a.keywords ?? [])].join(" ").toLowerCase();
            return extra.includes(q) ? 1 : 0;
        };
        return apps.map(a => ({ a, s: score(a) }))
            .filter(x => x.s > 0)
            .sort((x, y) => y.s - x.s)
            .map(x => x.a);
    }

    function toggle() {
        open = !open;
    }

    function launch(entry) {
        if (!entry) return;
        entry.execute();
        open = false;
        // Se actualiza después de cerrar para que el reordenamiento no se vea
        const u = Object.assign({}, usage);
        u[entry.id] = (u[entry.id] ?? 0) + 1;
        usage = u;
        usageFile.setText(JSON.stringify(u));
    }

    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher-usage.json")
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {
                root.usage = {};
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }
}
