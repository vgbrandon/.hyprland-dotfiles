import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.containers
import qs.components.design
import qs.services

// Selector del visualizador de audio (Ajustes → Visualizador): una cuadrícula con
// todos los estilos moviéndose con lo que suena (si no suena nada, con una señal de
// ejemplo), el color arriba y "Apagado". Clic en un estilo = usarlo.
//   quickshell ipc call visualizer picker
OverlayWindow {
    id: win

    open: Visualizer.pickerOpen
    onCloseRequested: Visualizer.pickerOpen = false
    namespace: "quickshell:visualizer"
    cardWidth: 860
    padding: 16
    spacing: 14

    // Sin audio, una señal de ejemplo para ver cómo se mueve cada estilo
    readonly property bool live: Visualizer.values.length > 0
    property var demo: []
    property real t: 0
    Timer {
        interval: 33
        repeat: true
        running: win.visible && !win.live
        onTriggered: {
            win.t += 0.033;
            const n = Visualizer.bands, v = [];
            for (let i = 0; i < n; i++) {
                const x = i / n;
                const s = 0.5 + 0.5 * Math.sin(win.t * 3 + x * 9) * Math.cos(win.t * 1.7 + x * 4);
                v.push(Math.max(0, (0.25 + 0.6 * s) * (1 - x * 0.55) + 0.12 * Math.sin(win.t * 11 + i)));
            }
            win.demo = v;
        }
    }

    // --- Cabecera: título, color y apagar ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Icon {
            text: Theme.iMusic
            font.pixelSize: 20
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Txt {
                text: "Visualizador de audio"
                textStyle: Design.headline
            }
            Txt {
                text: win.live ? "En el escritorio, mientras suena algo" : "Sin audio ahora: las vistas usan una señal de ejemplo"
                textStyle: Design.caption
                color: Design.onSurfaceVariant
            }
        }
        Segmented {
            implicitWidth: 270
            options: Visualizer.colors.map(c => c.label)
            current: Math.max(0, Visualizer.colors.findIndex(c => c.key === Visualizer.colorMode))
            follow: false
            onSelected: i => Config.setVisualizerColor(Visualizer.colors[i].key)
        }
        Btn {
            kind: Visualizer.style === "off" ? "filled" : "outline"
            text: Visualizer.style === "off" ? "Apagado" : "Apagar"
            onClicked: Config.setVisualizerStyle("off")
        }
    }

    // --- Los estilos ---
    GridLayout {
        Layout.fillWidth: true
        columns: 3
        rowSpacing: 12
        columnSpacing: 12

        Repeater {
            model: Visualizer.styles

            Rectangle {
                id: tile
                required property var modelData
                readonly property bool chosen: Visualizer.style === modelData.key

                Layout.fillWidth: true
                implicitHeight: 170
                radius: Design.radiusMd
                color: Design.surface0
                border.width: chosen ? 2 : 1
                border.color: chosen ? Design.accent : tileMouse.containsMouse ? Design.borderHighlight : Design.border
                clip: true

                VisualizerView {
                    x: 12
                    y: 10
                    width: tile.width - 24
                    height: tile.height - 44
                    style: tile.modelData.key
                    values: win.live ? Visualizer.values : win.demo
                }
                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 10
                    Txt {
                        Layout.fillWidth: true
                        text: tile.modelData.label
                        textStyle: Design.label
                        color: tile.chosen ? Design.accent : Design.onSurface
                    }
                    Icon {
                        visible: tile.chosen
                        text: Theme.iCheck
                        color: Design.accent
                        font.pixelSize: 16
                    }
                }
                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Config.setVisualizerStyle(tile.modelData.key)
                }
            }
        }
    }
}
