import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.containers
import qs.components.controls
import qs.services

// Panel del sistema (clic en la píldora de CPU y RAM): CPU con gráfica, memoria,
// gráfica (GPU), discos, red y los procesos que más CPU usan. Los datos están en
// SystemStats; lo detallado solo se lee mientras el panel está abierto.
BarPopup {
    id: panel

    // Color según lo cargado que esté (barras y temperaturas)
    function level(fraction) {
        return fraction > 0.9 ? Theme.error : fraction > 0.8 ? Theme.warning : Theme.primary;
    }

    readonly property var info: SystemStats.info

    implicitWidth: 520
    onVisibleChanged: SystemStats.detailed = visible

    // --- Cabecera ---
    PanelHeader {
        title: SystemStats.hostname || "Sistema"
        subtitle: `Linux ${SystemStats.kernel}`

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

            Meter {
                label: "RAM"
                value: `${SystemStats.bytes(SystemStats.ramUsed)} / ${SystemStats.bytes(SystemStats.ramTotal)}`
                fraction: SystemStats.ramTotal > 0 ? SystemStats.ramUsed / SystemStats.ramTotal : 0
            }
            Meter {
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

            Meter {
                label: "Uso"
                value: `${panel.info?.gpu?.busy ?? 0}%`
                fraction: (panel.info?.gpu?.busy ?? 0) / 100
            }
            Meter {
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

                Meter {
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

    // --- Componentes del panel ---

    // Etiqueta, valor y barra fina debajo
    component Meter: ColumnLayout {
        id: meter
        property string label
        property string value
        property real fraction: 0

        Layout.fillWidth: true
        spacing: 4

        RowLayout {
            Label {
                Layout.fillWidth: true
                text: meter.label
                color: Theme.subtext
                font.pixelSize: Theme.fontSize
            }
            Label {
                text: meter.value
                font.pixelSize: Theme.fontSize
            }
        }
        Slider {
            Layout.fillWidth: true
            interactive: false
            value: meter.fraction
            color: panel.level(meter.fraction)
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
