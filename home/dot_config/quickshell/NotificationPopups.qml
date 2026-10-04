import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications

// Popups de notificaciones arriba a la derecha del monitor enfocado
PanelWindow {
    id: win

    visible: Notifs.popups.length > 0 && !Notifs.centerOpen
    screen: Quickshell.screens.find(s => Hyprland.monitorFor(s) === Hyprland.focusedMonitor) ?? Quickshell.screens[0]
    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.barHeight + 8
        right: 12
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

                notif: modelData
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
                    interval: popupCard.notif.expireTimeout > 0 ? popupCard.notif.expireTimeout : 5000
                    running: popupCard.notif.urgency !== NotificationUrgency.Critical && !popupCard.hovered
                    onTriggered: {
                        Notifs.removePopup(popupCard.notif);
                        if (popupCard.notif.transient) popupCard.notif.expire();
                    }
                }
            }
        }
    }
}
