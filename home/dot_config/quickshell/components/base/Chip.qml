import QtQuick
import qs.services

// Opción; la elegida (selected) va en la selección de acento (diseño Velure).
// Con icono y sin texto queda casi cuadrada.
Rectangle {
    id: chip

    property string text
    property string icon
    property bool selected: false
    property color textColor: Design.onSurface
    property color iconColor: selected ? Design.accent : textColor
    signal clicked()

    implicitWidth: row.implicitWidth + (text !== "" ? 24 : 16)
    implicitHeight: 30
    radius: Design.radiusSm
    color: selected ? Design.selection : Design.raised
    border.color: selected ? Design.selectionBorder : Design.border
    border.width: 1
    Behavior on color { ColorAnimation { duration: Design.normal } }

    // Capa de estado
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: chipMouse.pressed ? Design.pressLayer : chipMouse.containsMouse ? Design.hoverLayer : "transparent"
        Behavior on color { ColorAnimation { duration: Design.fast } }
    }

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
            font.pixelSize: Design.label.size
            font.weight: Design.label.weight
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
