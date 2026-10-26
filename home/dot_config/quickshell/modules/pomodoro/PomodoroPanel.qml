import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.containers
import qs.components.design
import qs.services

// Panel del pomodoro (clic en el temporizador de la barra), con el diseño Velure
// (docs/velure.md de los dotfiles): fase, anillo con el tiempo, rondas del ciclo, controles,
// duraciones y opciones. El estado está en Pomodoro.
BarPopup {
    id: panel

    // Enfoque en rojo, descansos en azul (armonizados con el fondo)
    readonly property color phaseColor: Pomodoro.isBreak ? Design.info : Design.error
    readonly property var phases: ["work", "short", "long"]

    padding: 16
    spacing: 14

    // --- Cabecera ---
    RowLayout {
        spacing: 6

        Txt {
            Layout.fillWidth: true
            text: "Pomodoro"
            textStyle: Design.headline
        }
        Icon {
            text: Theme.iCheck
            color: Design.onSurfaceVariant
            font.pixelSize: 14
        }
        Txt {
            text: Pomodoro.todayCount === 1 ? "1 hoy" : `${Pomodoro.todayCount} hoy`
            textStyle: Design.caption
            color: Design.onSurfaceVariant
        }
    }

    // --- Fase (elegirla la reinicia) ---
    Segmented {
        Layout.fillWidth: true
        options: ["Enfoque", "Corto", "Largo"]
        current: panel.phases.indexOf(Pomodoro.phase)
        follow: false
        onSelected: i => {
            if (panel.phases[i] !== Pomodoro.phase) Pomodoro.setPhase(panel.phases[i]);
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
            readonly property color track: Design.surface3
            onProgressChanged: requestPaint()
            onFgChanged: requestPaint()
            onTrackChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const c = width / 2, w = 8, r = c - w / 2 - 1;
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
            Txt {
                Layout.alignment: Qt.AlignHCenter
                text: Pomodoro.timeText()
                font.pixelSize: 42
                font.weight: Font.Medium
                font.features: { "tnum": 1 }
                opacity: Pomodoro.running || !Pomodoro.active ? 1 : 0.55
                Behavior on opacity { NumberAnimation { duration: Design.normal } }
            }
            Txt {
                Layout.alignment: Qt.AlignHCenter
                text: Pomodoro.running ? Pomodoro.phaseNames[Pomodoro.phase]
                    : Pomodoro.active ? "En pausa" : Pomodoro.phaseNames[Pomodoro.phase]
                textStyle: Design.caption
                color: Design.onSurfaceVariant
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
                color: done ? Design.error : current ? Design.alpha(Design.error, 0.5) : Design.surface3
                Behavior on width { NumberAnimation { duration: Design.normal; easing.type: Design.easing } }
                Behavior on color { ColorAnimation { duration: Design.normal } }
            }
        }
    }

    // --- Controles ---
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 16

        IconBtn {
            icon: Theme.iRefresh
            kind: "tonal"
            size: 40
            iconSize: 19
            radius: Design.radiusMd
            onClicked: Pomodoro.reset()
        }
        // Empezar / pausar, en el color de la fase
        IconBtn {
            icon: Pomodoro.running ? Theme.iPause : Theme.iPlay
            kind: "filled"
            size: 56
            iconSize: 26
            radius: Design.radiusLg
            color: panel.phaseColor
            iconColor: Design.background
            onClicked: Pomodoro.toggle()
        }
        IconBtn {
            icon: Theme.iNext
            kind: "tonal"
            size: 40
            iconSize: 19
            radius: Design.radiusMd
            onClicked: Pomodoro.skip()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Design.outlineVariant
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

            NumberStep {
                required property var modelData
                label: modelData.label
                unit: "min"
                value: Pomodoro.minutesOf(modelData.id)
                // De 5 en 5 los largos, de 1 en 1 los cortos
                step: modelData.id === "work" || modelData.id === "long" ? 5 : 1
                onChanged: v => Pomodoro.setMinutes(modelData.id, v)
            }
        }
        NumberStep {
            label: "Rondas hasta el largo"
            value: Pomodoro.rounds
            onChanged: v => Pomodoro.setRounds(v)
        }

        ToggleRow {
            Layout.topMargin: 4
            text: "Seguir automáticamente"
            checked: Pomodoro.autoStart
            onToggled: Pomodoro.setAutoStart(!Pomodoro.autoStart)
        }
        ToggleRow {
            text: "Sonido al terminar"
            checked: Pomodoro.sound
            onToggled: Pomodoro.setSound(!Pomodoro.sound)
        }
    }

    Btn {
        Layout.alignment: Qt.AlignHCenter
        kind: "text"
        small: true
        text: "Reiniciar ciclo"
        enabled: Pomodoro.round > 0 || Pomodoro.phase !== "work" || Pomodoro.active
        onClicked: Pomodoro.resetCycle()
    }
}
