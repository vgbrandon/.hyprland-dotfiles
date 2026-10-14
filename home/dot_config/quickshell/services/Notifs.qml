pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Servidor de notificaciones: historial, popups y "no molestar".
// El historial guarda una copia de cada notificación (Entry): si la app la cierra
// (ZapZap cierra la anterior al llegar otro mensaje) o caduca, sigue en el centro
// hasta que la descarte el usuario. Solo se borra al descartarla.
Singleton {
    id: root

    property bool dnd: false
    // Con el centro abierto no se muestran popups (ya se ven en el centro)
    property bool centerOpen: false
    // Historial (las más nuevas al final) y las que se muestran como popup
    property var history: []
    property var popups: []
    // Se actualiza cada 30 s para refrescar los "hace X min"
    property date now: new Date()

    readonly property var list: history
    readonly property int count: history.length

    // Una notificación del historial. Mientras la app no la cierre, sus datos vienen de
    // la notificación viva (notif); al cerrarse se queda con la copia (snapshot).
    component Entry: QtObject {
        property var notif: null
        property date time: new Date()
        property string savedApp
        property string savedIcon
        property string savedImage
        property string savedSummary
        property string savedBody
        property string savedEntry
        property int savedUrgency: NotificationUrgency.Normal
        property int savedTimeout: 0

        readonly property bool live: notif !== null
        readonly property string appName: notif ? notif.appName : savedApp
        readonly property string appIcon: notif ? notif.appIcon : savedIcon
        readonly property string image: notif ? notif.image : savedImage
        readonly property string summary: notif ? notif.summary : savedSummary
        readonly property string body: notif ? notif.body : savedBody
        readonly property string desktopEntry: notif ? notif.desktopEntry : savedEntry
        readonly property int urgency: notif ? notif.urgency : savedUrgency
        readonly property int expireTimeout: notif ? notif.expireTimeout : savedTimeout
        readonly property var actions: notif ? notif.actions : []

        function snapshot() {
            if (!notif) return;
            savedApp = notif.appName;
            savedIcon = notif.appIcon;
            savedImage = notif.image;
            savedSummary = notif.summary;
            savedBody = notif.body;
            savedEntry = notif.desktopEntry;
            savedUrgency = notif.urgency;
            savedTimeout = notif.expireTimeout;
        }
    }
    Component { id: entryComp; Entry {} }

    function entryFor(n) {
        return history.find(e => e.notif === n) ?? null;
    }

    // Descartar (el usuario): la viva se cierra en la app; la copia se borra
    function dismiss(entry) {
        if (entry.notif) entry.notif.dismiss();
        else forget(entry);
    }
    function forget(entry) {
        history = history.filter(e => e !== entry);
        removePopup(entry);
        entry.destroy();
    }

    // Clic en una notificación que la app ya cerró: abre la app
    function openApp(entry) {
        const app = DesktopEntries.heuristicLookup(entry.desktopEntry || entry.appName);
        if (app) app.execute();
        forget(entry);
    }

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

    function removePopup(entry) {
        popups = popups.filter(p => p !== entry);
    }

    function clearAll() {
        for (const e of history.slice()) dismiss(e);
    }

    function ago(entry) {
        const t = entry?.time;
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
            // Una que la app actualiza (mismo id): se sube al final, sin duplicarla
            const existing = root.entryFor(n);
            if (existing) {
                existing.time = new Date();
                root.history = [...root.history.filter(e => e !== existing), existing];
                if (!root.centerOpen && !root.popups.includes(existing)) root.popups = [...root.popups, existing];
                return;
            }
            const entry = entryComp.createObject(root, { notif: n });
            entry.snapshot();
            root.history = [...root.history, entry];
            n.closed.connect(reason => {
                // Descartada por el usuario: fuera. Cerrada por la app o caducada: se queda la copia
                if (reason === NotificationCloseReason.Dismissed) {
                    root.forget(entry);
                } else {
                    entry.snapshot();
                    entry.notif = null;
                }
            });
            if (!root.centerOpen && (!root.dnd || n.urgency === NotificationUrgency.Critical))
                root.popups = [...root.popups, entry];
        }
    }

    // Al recargar Quickshell el servidor conserva las notificaciones (keepOnReload):
    // se recuperan en el historial
    Component.onCompleted: {
        for (const n of server.trackedNotifications.values) {
            if (root.entryFor(n)) continue;
            const entry = entryComp.createObject(root, { notif: n });
            entry.snapshot();
            root.history = [...root.history, entry];
            n.closed.connect(reason => {
                if (reason === NotificationCloseReason.Dismissed) root.forget(entry);
                else {
                    entry.snapshot();
                    entry.notif = null;
                }
            });
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

}
