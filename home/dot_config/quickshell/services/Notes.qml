pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Notas de texto simple: archivos .txt en ~/Notas.
// Lista (las editadas más recientemente primero), buscador por nombre y contenido,
// crear, renombrar (el título es el nombre del archivo), borrar (a la papelera) y
// editar; se guarda solo, un momento después de dejar de escribir. La ventana está en
// modules/notes.
//   quickshell ipc call notes toggle
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Notas"
    property bool open: false

    // [{ path, title, modified (ms) }]
    property var notes: []
    // Nota abierta y su texto (lo que se edita)
    property string current: ""
    property string text: ""
    readonly property string currentTitle: titleOf(current)

    // Búsqueda: por título y, si hay algo escrito, también dentro (grep)
    property string query: ""
    property var contentMatches: []
    readonly property var shown: {
        const q = query.trim().toLowerCase();
        if (q === "") return notes;
        return notes.filter(n => n.title.toLowerCase().includes(q) || contentMatches.includes(n.path));
    }

    function toggle() {
        open = !open;
    }
    onOpenChanged: {
        if (open) refresh();
        else flush();
    }

    function titleOf(path) {
        return path.split("/").pop().replace(/\.txt$/, "");
    }

    function refresh() {
        listProc.running = true;
    }

    function select(path) {
        if (path === current) return;
        flush();
        current = path;
        file.path = path;
        file.reload();
    }

    // Texto editado: se guarda al rato (o al cambiar de nota / cerrar)
    function edit(t) {
        if (t === text) return;
        text = t;
        saveTimer.restart();
    }
    function flush() {
        if (!saveTimer.running) return;
        saveTimer.stop();
        save();
    }
    function save() {
        if (current === "") return;
        file.setText(text);
        // Sube al principio de la lista (la más reciente)
        notes = [{ path: current, title: currentTitle, modified: Date.now() }].concat(notes.filter(n => n.path !== current));
    }
    Timer {
        id: saveTimer
        interval: 700
        onTriggered: root.save()
    }

    // Nombre libre para un título (añade " 2", " 3"… si ya existe)
    function freePath(title, except) {
        const clean = title.replace(/[\/\\:*?"<>|]/g, "-").trim() || "Sin título";
        let name = clean, i = 2;
        while (notes.some(n => n.path === `${dir}/${name}.txt` && n.path !== except)) name = `${clean} ${i++}`;
        return `${dir}/${name}.txt`;
    }

    function create() {
        flush();
        const path = freePath("Nota nueva");
        notes = [{ path, title: titleOf(path), modified: Date.now() }].concat(notes);
        current = path;
        text = "";
        file.path = path;
        file.setText("");
    }

    function rename(title) {
        if (current === "" || title.trim() === "" || title === currentTitle) return;
        flush();
        const from = current, to = freePath(title, current);
        Quickshell.execDetached(["mv", "-n", from, to]);
        current = to;
        file.path = to;
        notes = notes.map(n => n.path === from ? { path: to, title: titleOf(to), modified: Date.now() } : n);
    }

    function remove() {
        if (current === "") return;
        saveTimer.stop();
        Quickshell.execDetached(["gio", "trash", current]);
        notes = notes.filter(n => n.path !== current);
        current = "";
        text = "";
        if (notes.length > 0) select(notes[0].path);
    }

    FileView {
        id: file
        printErrors: false
        onLoaded: root.text = text()
    }

    // Lista: los .txt de la carpeta (también en subcarpetas), los más recientes primero
    Process {
        id: listProc
        command: ["sh", "-c", `mkdir -p "$1" && find "$1" -name '.*' -prune -o -type f -name '*.txt' -printf '%T@\\t%p\\n' | sort -rn`, "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of this.text.split("\n")) {
                    const [t, path] = line.split("\t");
                    if (!path) continue;
                    list.push({ path, title: root.titleOf(path), modified: parseFloat(t) * 1000 });
                }
                root.notes = list;
                if (root.current === "" && list.length > 0) root.select(list[0].path);
            }
        }
    }

    // Búsqueda dentro de las notas
    onQueryChanged: {
        const q = query.trim();
        if (q === "") {
            contentMatches = [];
            return;
        }
        grepProc.command = ["grep", "-rilF", "--include=*.txt", "--", q, dir];
        grepProc.running = true;
    }
    Process {
        id: grepProc
        stdout: StdioCollector {
            onStreamFinished: root.contentMatches = this.text.split("\n").filter(l => l !== "")
        }
    }

    IpcHandler {
        target: "notes"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
        function create(): void {
            root.open = true;
            root.create();
        }
    }
}
