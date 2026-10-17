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
        radius: Design.radiusXs
        color: root.checked ? Design.accent : "transparent"
        border.color: root.checked ? Design.accent : Design.outline
        border.width: root.checked ? 0 : 1.5
        Behavior on color { ColorAnimation { duration: Design.fast } }

        Icon {
            anchors.centerIn: parent
            visible: root.checked
            text: Theme.iCheck
            color: Design.onAccent
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
