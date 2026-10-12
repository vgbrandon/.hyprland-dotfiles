import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.modules.recorder
import qs.services

// Botón de grabación de la barra. Sin grabar: icono de video (clic = menú).
// Grabando: punto rojo con el tiempo (clic = detener).
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    GridLayout {
        id: row
        anchors.centerIn: parent
        columns: Config.barVertical ? 1 : 3
        rowSpacing: 3
        columnSpacing: 5

        Icon {
            visible: !Recorder.recording
            text: Theme.iVideo
        }
        Rectangle {
            visible: Recorder.recording
            Layout.alignment: Qt.AlignCenter
            implicitWidth: 10
            implicitHeight: 10
            radius: 5
            color: Theme.error

            SequentialAnimation on opacity {
                running: Recorder.recording
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }
        Label {
            visible: Recorder.recording
            Layout.alignment: Qt.AlignCenter
            text: Recorder.timeText()
            color: Theme.error
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Recorder.recording ? Recorder.stop() : menu.toggle()
    }

    RecordMenu {
        id: menu
        anchorItem: root
    }
}
