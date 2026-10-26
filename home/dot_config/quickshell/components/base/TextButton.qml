import QtQuick
import qs.services

// Botón de texto con icono opcional (diseño Velure, como Btn).
// accent = relleno de acento (lo principal); normal = tonal; flat = sin fondo hasta
// pasar el ratón; small = más bajo (cabeceras y pies).
Rectangle {
    id: button

    property string text
    property string icon
    property bool accent: false
    property bool small: false
    property bool flat: false
    signal clicked()

    readonly property color foreground: accent ? Design.onAccent : flat ? Design.onSurface : Design.onTonal

    implicitWidth: row.implicitWidth + (small ? 20 : 28)
    implicitHeight: small ? 28 : 34
    radius: Design.radiusSm
    opacity: enabled ? 1 : 0.38
    color: accent ? Design.accent : flat ? "transparent" : Design.tonal

    // Capa de estado
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: buttonMouse.pressed ? Design.pressLayer : buttonMouse.containsMouse ? Design.hoverLayer : "transparent"
        Behavior on color { ColorAnimation { duration: Design.fast } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: button.icon !== ""
            text: button.icon
            color: button.foreground
            font.pixelSize: button.small ? 14 : 16
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: button.text
            color: button.foreground
            font.pixelSize: Design.label.size
            font.weight: Design.label.weight
        }
    }
    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
