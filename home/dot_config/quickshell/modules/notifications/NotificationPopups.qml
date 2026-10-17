import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.services

// Popups de notificaciones arriba a la derecha del monitor principal
PanelWindow {
    id: win

    visible: Notifs.popups.length > 0 && !Notifs.centerOpen
    screen: Hypr.mainScreen
    anchors {
        top: true
        right: true
    }
    margins {
        top: Config.reserve("top") + 8
        right: Config.reserve("right") + 12
    }
    implicitWidth: 380
    implicitHeight: Math.max(1, column.implicitHeight)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"

    Column {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            // Máximo 4 a la vez, la más nueva arriba
            // ScriptModel conserva las tarjetas existentes al cambiar la lista
            model: ScriptModel {
                values: Notifs.popups.slice(-4).reverse()
            }

            NotificationCard {
                id: popupCard
                required property var modelData

                entry: modelData
                popup: true
                width: column.width

                // Entrada deslizándose desde la derecha
                transform: Translate {
                    id: slide
                    x: 400
                }
                Component.onCompleted: slideIn.start()
                NumberAnimation {
                    id: slideIn
                    target: slide
                    property: "x"
                    to: 0
                    duration: 220
                    easing.type: Easing.OutCubic
                }

                // Se oculta tras su tiempo (las críticas se quedan); pausa con el ratón encima
                Timer {
                    interval: popupCard.entry.expireTimeout > 0 ? popupCard.entry.expireTimeout : 5000
                    running: popupCard.entry.urgency !== NotificationUrgency.Critical && !popupCard.hovered
                    onTriggered: {
                        Notifs.removePopup(popupCard.entry);
                        if (popupCard.entry.notif?.transient) popupCard.entry.notif.expire();
                    }
                }
            }
        }
    }
}
