import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components.design
import qs.services

// Escritorios de la barra: un punto por cada escritorio con ventanas, más el activo
// (los vacíos no se muestran), en orden. El activo se alarga en relleno de acento con
// un poco de muelle; los puntos nuevos crecen al aparecer. Clic = ir a él, rueda =
// anterior/siguiente. En fila o, en una barra lateral, en columna (vertical).
Item {
    id: root

    required property ShellScreen screen
    property bool vertical: false
    // Tamaño del punto, largo del activo y separación
    property int dot: 8
    property int activeLength: 26
    property int gap: 6
    // Grosor (alto en fila, ancho en columna)
    property int thickness: 26

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
    // Los que tienen ventanas y el activo (sin los especiales, de id negativo)
    readonly property var ids: {
        const list = Hyprland.workspaces.values
            .filter(w => w.id > 0 && w.toplevels.values.length > 0)
            .map(w => w.id);
        if (activeId > 0 && !list.includes(activeId)) list.push(activeId);
        return list.sort((a, b) => a - b);
    }

    implicitWidth: vertical ? thickness : grid.implicitWidth
    implicitHeight: vertical ? grid.implicitHeight : thickness

    Grid {
        id: grid
        anchors.centerIn: parent
        columns: root.vertical ? 1 : Math.max(1, root.ids.length)
        columnSpacing: root.gap
        rowSpacing: root.gap

        Repeater {
            model: ScriptModel { values: root.ids }

            Item {
                id: ws
                required property int modelData
                readonly property bool active: modelData === root.activeId
                // Crece desde 0 al aparecer
                property bool appeared: false
                readonly property int size: !appeared ? 0 : active ? root.activeLength : root.dot

                Component.onCompleted: appeared = true
                width: root.vertical ? root.thickness : size
                height: root.vertical ? size : root.thickness
                Behavior on width { NumberAnimation { duration: Design.springDuration; easing.type: Design.spring; easing.overshoot: Design.overshoot } }
                Behavior on height { NumberAnimation { duration: Design.springDuration; easing.type: Design.spring; easing.overshoot: Design.overshoot } }

                Rectangle {
                    anchors.centerIn: parent
                    width: root.vertical ? Math.min(root.dot, parent.height) : parent.width
                    height: root.vertical ? parent.height : Math.min(root.dot, parent.width)
                    radius: root.dot / 2
                    color: ws.active ? Design.hi : mouse.containsMouse ? Design.onSurface : Design.onSurfaceVariant
                    Behavior on color { ColorAnimation { duration: Design.fast } }

                    AccentFill {
                        visible: ws.active
                        secondary: true
                    }
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    // Más fácil de atinar que el punto (cubre la separación)
                    anchors.leftMargin: root.vertical ? 0 : -root.gap / 2
                    anchors.rightMargin: root.vertical ? 0 : -root.gap / 2
                    anchors.topMargin: root.vertical ? -root.gap / 2 : 0
                    anchors.bottomMargin: root.vertical ? -root.gap / 2 : 0
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hypr.focusWorkspace(ws.modelData)
                }
            }
        }
    }

    WheelHandler {
        onWheel: e => Hypr.focusWorkspace(e.angleDelta.y < 0 ? "e+1" : "e-1")
    }
}
