import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components.design
import qs.services

// Escritorios de la barra: números en grupos (de 8, o menos en una barra lateral de un
// monitor bajo). El activo, en un contenedor tonal más largo que se desliza; los que
// tienen ventanas, más claros; los vacíos, apagados. Clic = ir a él, rueda =
// anterior/siguiente. En fila o, en una barra lateral, en columna (vertical).
Item {
    id: root

    required property ShellScreen screen
    property bool vertical: false
    property int shown: 8
    // Lado de cada celda y largo de la activa
    property int cell: 28
    readonly property int activeLength: cell + 12
    // Grosor (alto en fila, ancho en columna)
    property int thickness: 26

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
    readonly property int group: Math.floor((activeId - 1) / shown)

    implicitWidth: vertical ? thickness : (shown - 1) * cell + activeLength
    implicitHeight: vertical ? (shown - 1) * cell + activeLength : thickness

    // Indicador del activo
    Rectangle {
        readonly property int slot: root.activeId - root.group * root.shown - 1
        x: root.vertical ? 0 : slot * root.cell
        y: root.vertical ? slot * root.cell : 0
        width: root.vertical ? parent.width : root.activeLength
        height: root.vertical ? root.activeLength : parent.height
        radius: Design.radiusSm - 2
        color: Design.tonal
        Behavior on x { NumberAnimation { duration: Design.normal; easing.type: Design.easing } }
        Behavior on y { NumberAnimation { duration: Design.normal; easing.type: Design.easing } }
    }

    Grid {
        columns: root.vertical ? 1 : root.shown

        Repeater {
            model: root.shown

            Item {
                id: ws
                required property int index
                readonly property int wsId: root.group * root.shown + index + 1
                readonly property bool active: wsId === root.activeId
                readonly property bool occupied: (Hyprland.workspaces.values.find(w => w.id === wsId)?.toplevels.values.length ?? 0) > 0
                readonly property int length: active ? root.activeLength : root.cell

                width: root.vertical ? root.thickness : length
                height: root.vertical ? length : root.thickness
                Behavior on width { NumberAnimation { duration: Design.normal; easing.type: Design.easing } }
                Behavior on height { NumberAnimation { duration: Design.normal; easing.type: Design.easing } }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Design.radiusSm - 2
                    color: mouse.containsMouse && !ws.active ? Design.hoverLayer : "transparent"
                }
                Txt {
                    anchors.centerIn: parent
                    text: ws.wsId
                    textStyle: Design.label
                    font.features: { "tnum": 1 }
                    color: ws.active ? Design.onTonal : ws.occupied ? Design.onSurface : Design.muted
                    Behavior on color { ColorAnimation { duration: Design.normal } }
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hypr.focusWorkspace(ws.wsId)
                }
            }
        }
    }

    WheelHandler {
        onWheel: e => Hypr.focusWorkspace(e.angleDelta.y < 0 ? "e+1" : "e-1")
    }
}
