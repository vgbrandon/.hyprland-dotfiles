import QtQuick
import QtQuick.Layouts
import Quickshell

// Reloj grande en el escritorio (va dentro de la capa del fondo, debajo de las ventanas)
Item {
    id: root

    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: Config.reserve("top") + 70
    anchors.rightMargin: Config.reserve("right") + 70
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        id: col
        spacing: -10

        Text {
            Layout.alignment: Qt.AlignRight
            text: Qt.formatDateTime(clock.date, "hh:mm")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 110
            font.weight: Font.Light
        }
        Text {
            Layout.alignment: Qt.AlignRight
            text: Qt.formatDateTime(clock.date, "dddd, dd/MM")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 26
        }
    }
}
