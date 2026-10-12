import QtQuick
import qs.services

// Opción en forma de píldora; la elegida (selected) se resalta con el color principal.
// Con icono y sin texto queda casi redonda.
Rectangle {
    id: chip

    property string text
    property string icon
    property bool selected: false
    property color textColor: selected ? Theme.primaryFg : Theme.text
    property color iconColor: textColor
    signal clicked()

    implicitWidth: row.implicitWidth + (text !== "" ? 24 : 16)
    implicitHeight: 32
    radius: height / 2
    color: selected ? Theme.primary : chipMouse.containsMouse ? Theme.surfaceHigh : Theme.surface

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: chip.icon !== ""
            text: chip.icon
            color: chip.iconColor
            font.pixelSize: chip.text !== "" ? 14 : 16
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: chip.text !== ""
            text: chip.text
            color: chip.textColor
        }
    }
    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
