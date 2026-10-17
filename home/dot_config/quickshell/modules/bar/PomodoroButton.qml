import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components.base
import qs.modules.pomodoro

// Botón del pomodoro en la barra. Sin sesión: icono de temporizador.
// Con sesión: anillo de progreso y el tiempo restante (en pausa, atenuado).
// Clic = panel, clic derecho = empezar/pausar.
Item {
    id: root

    readonly property color phaseColor: Pomodoro.isBreak ? Theme.blue : Theme.error

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    GridLayout {
        id: grid
        anchors.centerIn: parent
        columns: Config.barVertical ? 1 : 2
        rowSpacing: 3
        columnSpacing: 5

        Icon {
            visible: !Pomodoro.active
            Layout.alignment: Qt.AlignCenter
            text: Theme.iTimer
        }

        // Anillo con lo que lleva la fase
        Canvas {
            id: ring
            visible: Pomodoro.active
            Layout.alignment: Qt.AlignCenter
            implicitWidth: 14
            implicitHeight: 14
            readonly property real progress: Pomodoro.progress
            readonly property color fg: Pomodoro.running ? root.phaseColor : Theme.subtext
            onProgressChanged: requestPaint()
            onFgChanged: requestPaint()
            onVisibleChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const c = width / 2, r = c - 1.5;
                ctx.lineWidth = 2.5;
                ctx.strokeStyle = Theme.withAlpha(fg, 0.25);
                ctx.beginPath();
                ctx.arc(c, c, r, 0, 2 * Math.PI);
                ctx.stroke();
                ctx.strokeStyle = fg;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.max(0.01, progress));
                ctx.stroke();
            }
        }

        Label {
            visible: Pomodoro.active
            Layout.alignment: Qt.AlignCenter
            // En una barra lateral: minutos sobre segundos
            text: Config.barVertical ? Pomodoro.timeText().replace(":", "\n") : Pomodoro.timeText()
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 0.9
            color: Pomodoro.running ? root.phaseColor : Theme.subtext
            font.features: { "tnum": 1 }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => {
            if (e.button === Qt.RightButton) Pomodoro.toggle();
            else panel.toggle();
        }
    }

    // IPC: se abre en la barra del monitor principal
    Connections {
        target: Pomodoro
        function onPanelRequested() {
            panel.toggleOnMainScreen();
        }
    }

    PomodoroPanel {
        id: panel
        anchorItem: root
    }
}
