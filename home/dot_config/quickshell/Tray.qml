import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// Bandeja del sistema (en una píldora): iconos de las apps que se quedan en segundo plano (ZapZap,
// Discord, Steam…). Clic = abrir, clic derecho = su menú, clic central = acción
// secundaria, rueda = lo que haga la app. Sin apps, no ocupa espacio.
// Las de "hidden" no se muestran (siguen en marcha).
Pill {
    id: root

    // Apps que no se muestran aunque estén en segundo plano (por su Id en la bandeja)
    readonly property var hidden: []
    readonly property var items: SystemTray.items.values.filter(i => !hidden.includes(i.id))

    visible: items.length > 0
    spacing: 10

    Repeater {
        model: root.items

        Item {
            id: trayItem
            required property SystemTrayItem modelData

            Layout.alignment: Qt.AlignCenter
            implicitWidth: 18
            implicitHeight: 18

            IconImage {
                anchors.fill: parent
                source: trayItem.modelData.icon
                // Las apps en reposo se ven un poco apagadas
                opacity: trayItem.modelData.status === Status.Passive ? 0.6 : 1
            }

            // Pide atención (p. ej. mensajes nuevos): punto del color principal
            Rectangle {
                visible: trayItem.modelData.status === Status.NeedsAttention
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: -2
                width: 7
                height: 7
                radius: 3.5
                color: Theme.primary
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -3
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: e => {
                    const item = trayItem.modelData;
                    if (e.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else if (e.button === Qt.RightButton || item.onlyMenu) {
                        root.showMenu(trayItem);
                    } else {
                        item.activate();
                    }
                }
                onWheel: e => trayItem.modelData.scroll(e.angleDelta.y, false)
            }
        }
    }

    // Menú de la app junto a la barra, hacia el interior de la pantalla
    function showMenu(icon) {
        const item = icon.modelData;
        if (!item.hasMenu) return;
        const win = icon.QsWindow.window;
        const p = icon.mapToItem(null, 0, 0);
        const pos = Config.barPosition;
        const x = pos === "left" ? win.width : pos === "right" ? 0 : Math.round(p.x);
        const y = pos === "top" ? win.height : pos === "bottom" ? 0 : Math.round(p.y);
        item.display(win, x, y);
    }
}
