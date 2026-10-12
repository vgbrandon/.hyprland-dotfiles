import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.containers
import qs.components.controls
import qs.services

// Menú de la grabación de pantalla (clic en el botón de video de la barra):
// qué grabar y con qué audio
BarPopup {
    id: menu

    implicitWidth: 280

    // Espera a que el menú desaparezca y suelte el ratón antes de empezar
    Timer {
        id: startTimer
        property bool region: false
        interval: 300
        onTriggered: region ? Recorder.recordRegion() : Recorder.recordScreen()
    }

    Label {
        Layout.leftMargin: 6
        text: "Grabar pantalla"
        font.pixelSize: 16
    }

    // Qué grabar
    RowLayout {
        spacing: 8

        Repeater {
            model: [
                { label: "Pantalla", icon: Theme.iMonitor, region: false },
                { label: "Región", icon: Theme.iRegion, region: true }
            ]

            Rectangle {
                id: opt
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 70
                radius: Theme.radiusSmall
                color: optMouse.containsMouse ? Theme.primary : Theme.surfaceHigh

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        text: opt.modelData.icon
                        color: optMouse.containsMouse ? Theme.primaryFg : Theme.text
                        font.pixelSize: 22
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: opt.modelData.label
                        color: optMouse.containsMouse ? Theme.primaryFg : Theme.text
                    }
                }
                MouseArea {
                    id: optMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // Suelta el ratón y el teclado antes de cerrar: si no, slurp
                        // (la selección de región) arranca sin recibir el ratón y se cierra
                        menu.close();
                        startTimer.region = opt.modelData.region;
                        startTimer.restart();
                    }
                }
            }
        }
    }

    // Audio
    SwitchRow {
        icon: Theme.iVolume
        text: "Audio del sistema"
        checked: Recorder.systemAudio
        onToggled: Recorder.systemAudio = !Recorder.systemAudio
    }
    SwitchRow {
        icon: Theme.iMic
        text: "Micrófono"
        checked: Recorder.microphone
        onToggled: Recorder.microphone = !Recorder.microphone
    }
}
