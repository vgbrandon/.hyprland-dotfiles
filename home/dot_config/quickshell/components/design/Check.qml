import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.services

// Casilla con su texto
//   Check { text: "Recordar"; checked: true }
RowLayout {
    id: root

    property bool checked: false
    property string text

    spacing: 10

    Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        radius: Design.radiusSm
        color: Design.sunken
        border.color: Design.alpha("#ffffff", 0.2)
        border.width: root.checked ? 0 : 1

        AccentFill {
            visible: root.checked
            secondary: true
        }

        Icon {
            anchors.centerIn: parent
            visible: root.checked
            text: Theme.iCheck
            color: Design.onHi
            font.pixelSize: 14
        }
    }
    Txt {
        text: root.text
    }

    TapHandler {
        cursorShape: Qt.PointingHandCursor
        onTapped: root.checked = !root.checked
    }
}
