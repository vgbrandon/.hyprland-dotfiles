import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Panel del pomodoro (clic en el temporizador de la barra): fase, anillo con el
// tiempo, controles, rondas del ciclo y duraciones. El estado está en Pomodoro.
PopupWindow {
    id: panel

    required property Item anchorItem
    property real closedAt: 0

    // Abre/cierra desde la barra. Si el mismo clic acaba de cerrarlo, no lo reabre.
    function toggle() {
        if (!visible && Date.now() - closedAt < 300) return;
        visible = !visible;
    }

    readonly property color phaseColor: Pomodoro.isBreak ? Theme.blue : Theme.error

    anchor.item: anchorItem
    anchor.rect.x: popupPos.x
    anchor.rect.y: popupPos.y
    // Junto a la barra, esté donde esté
    readonly property point popupPos: Config.popupPos(anchorItem, implicitWidth, implicitHeight, visible)
    implicitWidth: 340
    implicitHeight: layout.implicitHeight + 32
    color: "transparent"

    onVisibleChanged: {
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

    // Botón redondo con icono
    component RoundButton: Rectangle {
        id: btn
        property string icon
        property int size: 40
        property bool accent: false
        signal clicked()

        implicitWidth: size
        implicitHeight: size
        radius: size / 2
        color: accent ? (btnMouse.containsMouse ? Qt.lighter(panel.phaseColor, 1.1) : panel.phaseColor)
            : btnMouse.containsMouse ? Theme.surfaceHigh : Theme.surface

        Icon {
            anchors.centerIn: parent
            text: btn.icon
            color: btn.accent ? Theme.primaryFg : Theme.text
            font.pixelSize: btn.size * 0.48
        }
        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    // Botón pequeño − / + de los ajustes
    component StepButton: Rectangle {
        id: stepBtn
        property string icon
        signal clicked()

        implicitWidth: 28
        implicitHeight: 28
        radius: 14
        color: stepMouse.containsMouse ? Theme.surfaceHigh : Theme.surface

        Icon {
            anchors.centerIn: parent
            text: stepBtn.icon
            font.pixelSize: 14
        }
        MouseArea {
            id: stepMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: stepBtn.clicked()
        }
    }

    // Ajuste numérico: nombre, − valor +
    component Stepper: RowLayout {
        id: stepper
        property string label
        property int value
        property string unit: "min"
        property int step: 1
        signal changed(int v)

        spacing: 6

        Label {
            Layout.fillWidth: true
            text: stepper.label
        }
        StepButton {
            icon: Theme.iMinus
            onClicked: stepper.changed(stepper.value - stepper.step)
        }
        Label {
            Layout.preferredWidth: 52
            horizontalAlignment: Text.AlignHCenter
            text: stepper.unit ? `${stepper.value} ${stepper.unit}` : String(stepper.value)
            font.features: { "tnum": 1 }
        }
        StepButton {
            icon: Theme.iPlus
            onClicked: stepper.changed(stepper.value + stepper.step)
        }
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
            anchors.margins: 16
            spacing: 14

            // --- Cabecera ---
            RowLayout {
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    text: "Pomodoro"
                    font.pixelSize: 16
                }
                Icon {
                    text: Theme.iCheck
                    color: Theme.subtext
                    font.pixelSize: 14
                }
                Label {
                    text: Pomodoro.todayCount === 1 ? "1 hoy" : `${Pomodoro.todayCount} hoy`
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                }
            }

            // --- Fase (elegirla la reinicia) ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: height / 2
                color: Theme.surface

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    Repeater {
                        model: [
                            { id: "work", label: "Enfoque" },
                            { id: "short", label: "Corto" },
                            { id: "long", label: "Largo" }
                        ]

                        Rectangle {
                            id: seg
                            required property var modelData
                            readonly property bool on: Pomodoro.phase === modelData.id

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: height / 2
                            color: on ? panel.phaseColor : segMouse.containsMouse ? Theme.surfaceHigh : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Label {
                                anchors.centerIn: parent
                                text: seg.modelData.label
                                color: seg.on ? Theme.primaryFg : Theme.text
                                font.pixelSize: Theme.fontSize + 1
                            }
                            MouseArea {
                                id: segMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (!seg.on) Pomodoro.setPhase(seg.modelData.id)
                            }
                        }
                    }
                }
            }

            // --- Anillo con el tiempo ---
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 196
                implicitHeight: 196

                Canvas {
                    id: ring
                    anchors.fill: parent
                    readonly property real progress: Pomodoro.progress
                    readonly property color fg: panel.phaseColor
                    readonly property color track: Theme.surfaceHigh
                    onProgressChanged: requestPaint()
                    onFgChanged: requestPaint()
                    onTrackChanged: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const c = width / 2, w = 10, r = c - w / 2 - 1;
                        ctx.lineWidth = w;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = track;
                        ctx.beginPath();
                        ctx.arc(c, c, r, 0, 2 * Math.PI);
                        ctx.stroke();
                        if (progress <= 0) return;
                        ctx.strokeStyle = fg;
                        ctx.beginPath();
                        ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * progress);
                        ctx.stroke();
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        text: Pomodoro.isBreak ? Theme.iCoffee : Theme.iBrain
                        color: panel.phaseColor
                        font.pixelSize: 20
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: Pomodoro.timeText()
                        font.pixelSize: 40
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                        opacity: Pomodoro.running || !Pomodoro.active ? 1 : 0.55
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: Pomodoro.running ? Pomodoro.phaseNames[Pomodoro.phase]
                            : Pomodoro.active ? "En pausa" : Pomodoro.phaseNames[Pomodoro.phase]
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize
                    }
                }
            }

            // --- Rondas del ciclo (la última lleva al descanso largo) ---
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Repeater {
                    model: Pomodoro.rounds

                    Rectangle {
                        required property int index
                        readonly property bool done: index < Pomodoro.round
                        // La ronda en curso, más ancha
                        readonly property bool current: !Pomodoro.isBreak && index === Pomodoro.round

                        width: current ? 20 : 8
                        height: 8
                        radius: 4
                        color: done ? Theme.error : current ? Theme.withAlpha(Theme.error, 0.5) : Theme.surfaceHigh
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                }
            }

            // --- Controles ---
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                RoundButton {
                    icon: Theme.iRefresh
                    onClicked: Pomodoro.reset()
                }
                RoundButton {
                    icon: Pomodoro.running ? Theme.iPause : Theme.iPlay
                    size: 56
                    accent: true
                    onClicked: Pomodoro.toggle()
                }
                RoundButton {
                    icon: Theme.iNext
                    onClicked: Pomodoro.skip()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.surfaceHigh
            }

            // --- Duraciones y opciones ---
            ColumnLayout {
                Layout.leftMargin: 4
                Layout.rightMargin: 2
                spacing: 8

                Repeater {
                    model: [
                        { id: "work", label: "Enfoque" },
                        { id: "short", label: "Descanso corto" },
                        { id: "long", label: "Descanso largo" }
                    ]

                    Stepper {
                        required property var modelData
                        Layout.fillWidth: true
                        label: modelData.label
                        value: Pomodoro.minutesOf(modelData.id)
                        // De 5 en 5 los largos, de 1 en 1 los cortos
                        step: modelData.id === "work" || modelData.id === "long" ? 5 : 1
                        onChanged: v => Pomodoro.setMinutes(modelData.id, v)
                    }
                }
                Stepper {
                    Layout.fillWidth: true
                    label: "Rondas hasta el largo"
                    unit: ""
                    value: Pomodoro.rounds
                    onChanged: v => Pomodoro.setRounds(v)
                }

                RowLayout {
                    spacing: 10
                    Label {
                        Layout.fillWidth: true
                        text: "Seguir automáticamente"
                    }
                    Switch {
                        checked: Pomodoro.autoStart
                        onToggled: Pomodoro.setAutoStart(!Pomodoro.autoStart)
                    }
                }
                RowLayout {
                    spacing: 10
                    Label {
                        Layout.fillWidth: true
                        text: "Sonido al terminar"
                    }
                    Switch {
                        checked: Pomodoro.sound
                        onToggled: Pomodoro.setSound(!Pomodoro.sound)
                    }
                }
            }

            TextButton {
                Layout.alignment: Qt.AlignHCenter
                text: "Reiniciar ciclo"
                enabled: Pomodoro.round > 0 || Pomodoro.phase !== "work" || Pomodoro.active
                onClicked: Pomodoro.resetCycle()
            }
        }
    }
}
