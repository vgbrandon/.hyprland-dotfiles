import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

// Workspaces: iconos de las apps abiertas en cada uno, punto si está vacío
Pill {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
    readonly property int shown: 8
    readonly property int group: Math.floor((activeId - 1) / shown)
    readonly property int slot: compact ? 22 : 26
    // Grosor de las celdas (alto en la barra horizontal, ancho en la vertical)
    readonly property int thickness: slot - 4

    padding: 4

    function dispatch(ws) {
        if (Hyprland.usingLua === false)
            Hyprland.dispatch(`workspace ${ws}`);
        else
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${ws}" })`);
    }

    Item {
        implicitWidth: root.vertical ? root.thickness : cells.implicitWidth
        implicitHeight: root.vertical ? cells.implicitHeight : root.thickness

        // Indicador del workspace activo (sigue la posición y el tamaño de su celda)
        Rectangle {
            readonly property Item cell: repeater.count > 0 ? repeater.itemAt(root.activeId - root.group * root.shown - 1) : null
            x: root.vertical ? 0 : (cell?.x ?? 0) + 2
            y: root.vertical ? (cell?.y ?? 0) + 2 : 0
            width: root.vertical ? parent.width : (cell?.width ?? root.slot) - 4
            height: root.vertical ? (cell?.height ?? root.slot) - 4 : parent.height
            radius: Math.min(width, height) / 2
            color: Theme.surfaceHigh
            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        // Fila en la barra horizontal, columna en la vertical
        Grid {
            id: cells
            columns: root.vertical ? 1 : root.shown

            Repeater {
                id: repeater
                model: root.shown

                Item {
                    id: cell
                    required property int index
                    readonly property int wsId: root.group * root.shown + index + 1
                    readonly property HyprlandWorkspace ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                    // Apps distintas del workspace (sin repetir), máximo 3 iconos
                    readonly property var apps: {
                        const ids = (ws?.toplevels.values ?? []).map(t => t.wayland?.appId ?? t.lastIpcObject?.class ?? "").filter(a => a !== "");
                        return [...new Set(ids)];
                    }
                    // En columna caben menos (el alto es más justo)
                    readonly property int maxIcons: root.compact ? 1 : root.vertical ? 2 : 3

                    width: root.vertical ? root.thickness : apps.length > 0 ? icons.implicitWidth + 12 : root.slot
                    height: !root.vertical ? root.thickness : apps.length > 0 ? icons.implicitHeight + 12 : root.slot
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Grid {
                        id: icons
                        anchors.centerIn: parent
                        columns: root.vertical ? 1 : cell.maxIcons + 1
                        spacing: 3
                        horizontalItemAlignment: Grid.AlignHCenter
                        verticalItemAlignment: Grid.AlignVCenter

                        Repeater {
                            model: cell.apps.slice(0, cell.maxIcons)

                            IconImage {
                                required property string modelData
                                implicitSize: 16
                                source: {
                                    if (DesktopEntries.applications.values.length === 0) return ""; // aún cargando
                                    const icon = DesktopEntries.heuristicLookup(modelData)?.icon ?? modelData.toLowerCase();
                                    return Quickshell.iconPath(icon, true) || Quickshell.iconPath("application-x-executable", true);
                                }
                            }
                        }

                        Text {
                            visible: cell.apps.length > cell.maxIcons
                            text: `+${cell.apps.length - cell.maxIcons}`
                            color: Theme.subtext
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        visible: cell.apps.length === 0
                        width: cell.wsId === root.activeId ? 6 : 4
                        height: width
                        radius: width / 2
                        color: cell.ws ? Theme.text : Theme.dot
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dispatch(cell.wsId)
                    }
                }
            }
        }

        WheelHandler {
            onWheel: e => root.dispatch(e.angleDelta.y < 0 ? "e+1" : "e-1")
        }
    }
}
