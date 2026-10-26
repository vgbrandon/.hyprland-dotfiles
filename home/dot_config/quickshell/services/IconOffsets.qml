pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Ajuste fino de la posición de cada icono, para que se vea centrado en su caja: cada
// icono de la fuente tiene su forma y el redondeo lo puede dejar uno o dos píxeles
// desplazado. Va por icono (su carácter) y tamaño, en píxeles, y lo aplica Icon solo,
// en cualquier sitio donde salga ese icono a ese tamaño. Se ajusta a ojo con el editor
// de iconos (modules/iconeditor): los cambios se ven al momento y se guardan al pulsar
// Guardar en icon-offsets.json, junto a la shell (si se cierra sin guardar, se descartan)
// (quickshell ipc call iconeditor toggle):
//   { "f030c@16": { "x": 1, "y": 1 }, … }   (carácter en hex @ tamaño en px)
Singleton {
    id: root

    // Los que se aplican (con los cambios del editor aún sin guardar) y los guardados
    property var offsets: ({})
    property var saved: ({})
    readonly property bool dirty: JSON.stringify(offsets) !== JSON.stringify(saved)
    // Editor abierto (modules/iconeditor/IconEditor.qml)
    property bool editorOpen: false

    function key(text, size) {
        return text ? `${text.codePointAt(0).toString(16)}@${Math.round(size)}` : "";
    }
    // { x, y } del icono a ese tamaño (0, 0 si no tiene ajuste)
    function of(text, size) {
        return offsets[key(text, size)] ?? { x: 0, y: 0 };
    }
    function set(text, size, x, y) {
        const next = Object.assign({}, offsets);
        if (x === 0 && y === 0) delete next[key(text, size)];
        else next[key(text, size)] = { x, y };
        // Ordenado por clave, para que el archivo cambie lo mínimo
        const sorted = {};
        for (const k of Object.keys(next).sort()) sorted[k] = next[k];
        offsets = sorted;
    }
    // Guarda los cambios en icon-offsets.json (y en los dotfiles, si chezmoi lo sigue)
    function save() {
        if (!dirty) return;
        file.setText(JSON.stringify(offsets, null, 2) + "\n");
        saved = offsets;
        Quickshell.execDetached(["sh", "-c", 'chezmoi source-path "$1" >/dev/null 2>&1 && chezmoi add "$1"', "sh", file.path]);
    }
    // Vuelve a lo guardado
    function discard() {
        offsets = saved;
    }
    // Al cerrar el editor sin guardar, se descartan los cambios
    onEditorOpenChanged: if (!editorOpen) discard()

    IpcHandler {
        target: "iconeditor"

        function toggle(): void { root.editorOpen = !root.editorOpen; }
    }

    FileView {
        id: file
        path: Quickshell.shellPath("icon-offsets.json")
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.saved = JSON.parse(text());
            } catch (e) {
                root.saved = {};
            }
            root.offsets = root.saved;
        }
    }
}
