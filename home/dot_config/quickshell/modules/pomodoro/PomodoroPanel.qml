import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.buttons
import qs.components.containers
import qs.components.controls
import qs.services

// Panel del pomodoro (clic en el temporizador de la barra): fase, anillo con el
// tiempo, controles, rondas del ciclo y duraciones. El estado está en Pomodoro.
BarPopup {
    id: panel

    readonly property color phaseColor: Pomodoro.isBreak ? Theme.blue : Theme.error

    implicitWidth: 340
    padding: 16
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

        CircleButton {
            icon: Theme.iRefresh
            size: 40
            iconSize: 19
            filled: true
            onClicked: Pomodoro.reset()
        }
        CircleButton {
            icon: Pomodoro.running ? Theme.iPause : Theme.iPlay
            size: 56
            iconSize: 27
            accent: true
            accentColor: panel.phaseColor
            onClicked: Pomodoro.toggle()
        }
        CircleButton {
            icon: Theme.iNext
            size: 40
            iconSize: 19
            filled: true
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
                unit: "min"
                value: Pomodoro.minutesOf(modelData.id)
                // De 5 en 5 los largos, de 1 en 1 los cortos
                step: modelData.id === "work" || modelData.id === "long" ? 5 : 1
                onChanged: v => Pomodoro.setMinutes(modelData.id, v)
            }
        }
        Stepper {
            Layout.fillWidth: true
            label: "Rondas hasta el largo"
            value: Pomodoro.rounds
            onChanged: v => Pomodoro.setRounds(v)
        }

        SwitchRow {
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            text: "Seguir automáticamente"
            checked: Pomodoro.autoStart
            onToggled: Pomodoro.setAutoStart(!Pomodoro.autoStart)
        }
        SwitchRow {
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            text: "Sonido al terminar"
            checked: Pomodoro.sound
            onToggled: Pomodoro.setSound(!Pomodoro.sound)
        }
    }

    TextButton {
        Layout.alignment: Qt.AlignHCenter
        text: "Reiniciar ciclo"
        enabled: Pomodoro.round > 0 || Pomodoro.phase !== "work" || Pomodoro.active
        onClicked: Pomodoro.resetCycle()
    }
}
