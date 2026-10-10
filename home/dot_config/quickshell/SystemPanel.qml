import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Panel del sistema (clic en la píldora de CPU y RAM): CPU con gráfica, memoria,
// gráfica (GPU), discos, red y los procesos que más CPU usan. Los datos están en
// SystemStats; lo detallado solo se lee mientras el panel está abierto.
PopupWindow {
    id: panel

    required property Item anchorItem
    property real closedAt: 0

    // Abre/cierra desde la barra. Si el mismo clic acaba de cerrarlo, no lo reabre.
    function toggle() {
        if (!visible && Date.now() - closedAt < 300) return;
        visible = !visible;
    }

    // Color según lo cargado que esté (barras y temperaturas)
    function level(fraction) {
        return fraction > 0.9 ? Theme.error : fraction > 0.8 ? Theme.warning : Theme.primary;
    }

    readonly property var info: SystemStats.info

    anchor.item: anchorItem
    anchor.rect.x: popupPos.x
    anchor.rect.y: popupPos.y
    // Junto a la barra, esté donde esté
    readonly property point popupPos: Config.popupPos(anchorItem, implicitWidth, implicitHeight, visible)
    implicitWidth: 520
    implicitHeight: layout.implicitHeight + 24
    color: "transparent"

    onVisibleChanged: {
        SystemStats.detailed = visible;
        grab.active = false;
        if (visible) grabTimer.restart();
    }

    // Clic fuera del panel = cerrar
    HyprlandFocusGrab {
        id: grab
        windows: [panel]
        onCleared: {
            panel.visible = false;
            panel.closedAt = Date.now();
        }
    }
    Timer {
        id: grabTimer
        interval: 50
        onTriggered: grab.active = panel.visible
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panelBg
        border.color: Theme.surfaceHigh
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 10

            // --- Cabecera ---
            RowLayout {
                Layout.leftMargin: 6
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label {
                        text: SystemStats.hostname || "Sistema"
                        font.pixelSize: 16
                    }
                    Label {
                        text: `Linux ${SystemStats.kernel}`
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize
                    }
                }
                Label {
                    visible: !!panel.info
                    text: panel.info ? `Encendido ${SystemStats.duration(panel.info.uptime)}` : ""
                    color: Theme.subtext
                }
            }

            // --- CPU ---
            Card {
                Layout.fillWidth: true
                icon: Theme.iCpu
                title: "CPU"
                subtitle: SystemStats.cpuModel

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    // Uso actual
                    Label {
                        Layout.alignment: Qt.AlignBottom
                        text: `${SystemStats.cpu}%`
                        color: panel.level(SystemStats.cpu / 100)
                        font.pixelSize: 30
                        font.weight: Font.Light
                    }

                    // Gráfica de los últimos 2 minutos
                    Canvas {
                        id: graph
                        Layout.fillWidth: true
                        implicitHeight: 56

                        property var values: SystemStats.cpuHistory
                        property color lineColor: Theme.primary
                        onValuesChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onLineColorChanged: requestPaint()

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const n = 60, v = values;
                            if (v.length < 2) return;
                            const step = width / (n - 1);
                            const x0 = width - (v.length - 1) * step;
                            const y = p => height - 2 - (height - 4) * Math.min(100, p) / 100;
                            ctx.beginPath();
                            ctx.moveTo(x0, y(v[0]));
                            for (let i = 1; i < v.length; i++) ctx.lineTo(x0 + i * step, y(v[i]));
                            // Relleno tenue bajo la línea
                            ctx.lineTo(width, height);
                            ctx.lineTo(x0, height);
                            ctx.closePath();
                            ctx.fillStyle = Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.15);
                            ctx.fill();
                            ctx.beginPath();
                            ctx.moveTo(x0, y(v[0]));
                            for (let i = 1; i < v.length; i++) ctx.lineTo(x0 + i * step, y(v[i]));
                            ctx.lineWidth = 2;
                            ctx.strokeStyle = String(lineColor);
                            ctx.stroke();
                        }
                    }
                }

                RowLayout {
                    spacing: 16
                    Stat {
                        icon: Theme.iThermometer
                        text: panel.info?.cpuTemp != null ? `${Math.round(panel.info.cpuTemp)} °C` : "—"
                        color: panel.info?.cpuTemp != null ? panel.level(panel.info.cpuTemp / 95) : Theme.text
                    }
                    Stat {
                        icon: Theme.iSpeed
                        text: panel.info?.cpuFreq != null ? `${panel.info.cpuFreq.toFixed(2)} GHz` : "—"
                    }
                    Stat {
                        icon: Theme.iCpu
                        text: panel.info ? `${panel.info.cpus} hilos` : "—"
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                // --- Memoria ---
                Card {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    icon: Theme.iRam
                    title: "Memoria"

                    Bar {
                        label: "RAM"
                        value: `${SystemStats.bytes(SystemStats.ramUsed)} / ${SystemStats.bytes(SystemStats.ramTotal)}`
                        fraction: SystemStats.ramTotal > 0 ? SystemStats.ramUsed / SystemStats.ramTotal : 0
                    }
                    Bar {
                        visible: SystemStats.swapTotal > 0
                        label: "Swap"
                        value: `${SystemStats.bytes(SystemStats.swapUsed)} / ${SystemStats.bytes(SystemStats.swapTotal)}`
                        fraction: SystemStats.swapTotal > 0 ? SystemStats.swapUsed / SystemStats.swapTotal : 0
                    }
                }

                // --- Gráfica ---
                Card {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    icon: Theme.iGpu
                    title: "Gráfica"
                    subtitle: panel.info?.gpu?.name ?? ""

                    Bar {
                        label: "Uso"
                        value: `${panel.info?.gpu?.busy ?? 0}%`
                        fraction: (panel.info?.gpu?.busy ?? 0) / 100
                    }
                    Bar {
                        label: "VRAM"
                        value: panel.info?.gpu ? `${SystemStats.bytes(panel.info.gpu.vramUsed)} / ${SystemStats.bytes(panel.info.gpu.vramTotal)}` : "—"
                        fraction: panel.info?.gpu?.vramTotal ? panel.info.gpu.vramUsed / panel.info.gpu.vramTotal : 0
                    }
                    Stat {
                        icon: Theme.iThermometer
                        text: {
                            const g = panel.info?.gpu;
                            if (g?.temp == null) return "—";
                            return g.hotspot != null ? `${Math.round(g.temp)} °C · punto caliente ${Math.round(g.hotspot)} °C` : `${Math.round(g.temp)} °C`;
                        }
                        color: panel.info?.gpu?.hotspot != null ? panel.level(panel.info.gpu.hotspot / 100) : Theme.text
                    }
                }

                // --- Discos ---
                Card {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    icon: Theme.iDisk
                    title: "Discos"

                    Repeater {
                        model: panel.info?.disks ?? []

                        Bar {
                            required property var modelData
                            label: modelData.mount
                            value: `${SystemStats.bytes(modelData.used)} / ${SystemStats.bytes(modelData.total)}`
                            fraction: modelData.used / modelData.total
                        }
                    }
                }

                // --- Red ---
                Card {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    icon: Theme.iEthernet
                    title: "Red"

                    Stat {
                        icon: Theme.iArrowDown
                        text: `Bajada  ${SystemStats.speed(SystemStats.netDown)}`
                    }
                    Stat {
                        icon: Theme.iArrowUp
                        text: `Subida  ${SystemStats.speed(SystemStats.netUp)}`
                    }
                }
            }

            // --- Procesos ---
            Card {
                Layout.fillWidth: true
                icon: Theme.iList
                title: "Procesos"
                subtitle: "Los que más CPU usan ahora (100 % = un hilo)"

                Repeater {
                    model: panel.info?.procs ?? []

                    RowLayout {
                        id: proc
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 12

                        Label {
                            Layout.fillWidth: true
                            text: proc.modelData.name
                        }
                        Label {
                            Layout.preferredWidth: 60
                            horizontalAlignment: Text.AlignRight
                            text: `${proc.modelData.cpu.toFixed(1)} %`
                            color: Theme.subtext
                        }
                        Label {
                            Layout.preferredWidth: 70
                            horizontalAlignment: Text.AlignRight
                            text: SystemStats.bytes(proc.modelData.mem)
                            color: Theme.subtext
                        }
                    }
                }

                Label {
                    visible: !panel.info
                    text: "Cargando…"
                    color: Theme.subtext
                }
            }
        }
    }

    // --- Componentes del panel ---

    // Tarjeta con icono, título y subtítulo opcional
    component Card: Rectangle {
        id: card
        default property alias content: cardBody.data
        property string icon
        property string title
        property string subtitle

        implicitHeight: cardLayout.implicitHeight + 24
        radius: Theme.radiusSmall
        color: Theme.surface

        ColumnLayout {
            id: cardLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 8

            RowLayout {
                spacing: 8
                Icon {
                    text: card.icon
                    color: Theme.primary
                }
                Label {
                    text: card.title
                }
                Label {
                    Layout.fillWidth: true
                    visible: card.subtitle !== ""
                    text: card.subtitle
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                }
            }

            ColumnLayout {
                id: cardBody
                Layout.fillWidth: true
                spacing: 8
            }
        }
    }

    // Etiqueta, valor y barra fina debajo
    component Bar: ColumnLayout {
        id: bar
        property string label
        property string value
        property real fraction: 0

        Layout.fillWidth: true
        spacing: 4

        RowLayout {
            Label {
                Layout.fillWidth: true
                text: bar.label
                color: Theme.subtext
                font.pixelSize: Theme.fontSize
            }
            Label {
                text: bar.value
                font.pixelSize: Theme.fontSize
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 4
            radius: 2
            color: Theme.surfaceHigh

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, bar.fraction))
                height: parent.height
                radius: 2
                color: panel.level(bar.fraction)
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }
    }

    // Icono + texto
    component Stat: RowLayout {
        id: stat
        property string icon
        property string text
        property color color: Theme.text

        spacing: 6
        Icon {
            text: stat.icon
            color: Theme.subtext
            font.pixelSize: 14
        }
        Label {
            text: stat.text
            color: stat.color
        }
    }
}
