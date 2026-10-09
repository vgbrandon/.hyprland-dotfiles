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
