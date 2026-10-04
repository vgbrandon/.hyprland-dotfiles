pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Servidor de notificaciones: historial, popups y "no molestar"
Singleton {
    id: root

    property bool dnd: false
    // Con el centro abierto no se muestran popups (ya se ven en el centro)
    property bool centerOpen: false
    // Notificaciones mostrándose como popup (las más nuevas al final)
    property var popups: []
    // Hora de llegada de cada notificación, por id
    property var times: ({})
    // Se actualiza cada 30 s para refrescar los "hace X min"
    property date now: new Date()

    readonly property var list: server.trackedNotifications.values
    readonly property int count: list.length

    property real closedAt: 0

    function toggleCenter() {
        // Evita reabrir si el mismo clic en la campana acaba de cerrarlo
        if (!centerOpen && Date.now() - closedAt < 300) return;
        centerOpen = !centerOpen;
    }

    function closeCenter() {
        if (!centerOpen) return;
        centerOpen = false;
        closedAt = Date.now();
    }

    onCenterOpenChanged: if (centerOpen) popups = []

    function removePopup(n) {
        popups = popups.filter(p => p !== n);
    }

    function clearAll() {
        for (const n of list.slice()) n.dismiss();
    }

    function ago(n) {
        const t = times[n.id];
        if (!t) return "";
        const min = Math.floor((now - t) / 60000);
        if (min < 1) return "ahora";
        if (min < 60) return `hace ${min} min`;
        return Qt.formatDateTime(t, "hh:mm");
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            const t = Object.assign({}, root.times);
            t[n.id] = new Date();
            root.times = t;
            n.closed.connect(() => root.removePopup(n));
            if (!root.centerOpen && (!root.dnd || n.urgency === NotificationUrgency.Critical))
                root.popups = [...root.popups, n];
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void { root.toggleCenter(); }
        function toggleDnd(): void { root.dnd = !root.dnd; }
        function clear(): void { root.clearAll(); }
    }

    NotificationPopups {}
    NotificationCenter {}
}
