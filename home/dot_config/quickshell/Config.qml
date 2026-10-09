pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Estado del panel de ajustes rápidos (entra desde la derecha).
//   quickshell ipc call config toggle
Singleton {
    id: root

    property bool open: false
    property real closedAt: 0

    // Posición de la barra: top | bottom | left | right (se guarda en settings.json).
    // barTarget es la elegida; barPosition, la que se ve: cambia a mitad de la
    // animación, cuando la barra está escondida.
    readonly property string barTarget: settings.barPosition
    property string barPosition: "top"
    readonly property bool barVertical: barPosition === "left" || barPosition === "right"
    // 0 = barra visible, 1 = escondida fuera de su borde
    property real barHide: 0

    function setBarPosition(position) {
        settings.barPosition = position;
        settingsFile.writeAdapter();
    }

    // Al iniciar se coloca directamente, sin animación
    property bool settingsLoaded: false

    // Al cambiar la posición (desde el panel o editando el archivo):
    // sale por su borde, cambia de lado y entra por el nuevo
    Connections {
        target: settings
        function onBarPositionChanged() {
            if (!root.settingsLoaded) return;
            if (settings.barPosition !== root.barPosition || moveAnim.running)
                moveAnim.restart();
        }
    }

    SequentialAnimation {
        id: moveAnim

        NumberAnimation {
            target: root
            property: "barHide"
            to: 1
            duration: 200
            easing.type: Easing.InCubic
        }
        ScriptAction { script: root.barPosition = settings.barPosition }
        // Deja que la barra se recoloque en el borde nuevo antes de entrar
        PauseAnimation { duration: 100 }
        NumberAnimation {
            target: root
            property: "barHide"
            to: 0
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    // Espacio que ocupa la barra en un borde del monitor (0 si no está ahí).
    // Los paneles que ignoran la zona exclusiva lo suman a su margen.
    function reserve(edge) {
        return barPosition === edge ? Theme.barHeight : 0;
    }

    // Posición de un popup de la barra, relativa al elemento que lo abre:
    // pegado al borde interior de la barra, centrado en el elemento y sin
    // salirse del monitor. "open" solo sirve para recalcularla al abrirlo.
    function popupPos(item, w, h, open) {
        const win = item?.QsWindow.window;
        if (!win) return Qt.point(0, 0);
        const p = item.mapToItem(null, 0, 0);
        const gap = 8;
        const clamp = (v, size, max) => Math.max(gap, Math.min(max - size - gap, v));
        let x, y;
        if (barVertical) {
            x = barPosition === "left" ? win.width + gap : -w - gap;
            y = clamp(p.y + item.height / 2 - h / 2, h, win.height);
        } else {
            x = clamp(p.x + item.width / 2 - w / 2, w, win.width);
            y = barPosition === "top" ? win.height + gap : -h - gap;
        }
        return Qt.point(x - p.x, y - p.y);
    }

    FileView {
        id: settingsFile
        path: Quickshell.statePath("settings.json")
        blockLoading: true
        // Aún no existe hasta el primer cambio: no es un error
        printErrors: false
        // Editar el archivo a mano también mueve la barra
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (root.settingsLoaded) return;
            root.barPosition = settings.barPosition;
            root.settingsLoaded = true;
        }
        onLoadFailed: root.settingsLoaded = true

        JsonAdapter {
            id: settings
            property string barPosition: "top"
        }
    }

    function toggle() {
        // Evita reabrir si el mismo clic en el engranaje acaba de cerrarlo
        if (!open && Date.now() - closedAt < 300) return;
        open = !open;
    }

    function close() {
        if (!open) return;
        open = false;
        closedAt = Date.now();
    }

    IpcHandler {
        target: "config"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.close(); }
    }

    ConfigPanel {}
}
