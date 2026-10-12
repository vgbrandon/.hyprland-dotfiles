import QtQuick
import qs.services

// Botón de texto en forma de píldora, con icono opcional.
// accent = color principal; small = más bajo (cabeceras y pies); flat = sin fondo
// hasta pasar el ratón.
Rectangle {
    id: button

    property string text
    property string icon
    property bool accent: false
    property bool small: false
    property bool flat: false
    signal clicked()

    readonly property color foreground: accent ? Theme.primaryFg : Theme.text

    implicitWidth: row.implicitWidth + (small ? 24 : 32)
    implicitHeight: small ? 30 : 36
    radius: height / 2
    opacity: enabled ? 1 : 0.4
    color: accent ? (buttonMouse.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary)
        : buttonMouse.containsMouse ? Theme.surfaceHigh : flat ? "transparent" : Theme.surface

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
            font.pixelSize: button.small ? Theme.fontSize + 1 : Theme.fontSize + 2
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
