import QtQuick

// Botón de texto en forma de píldora (accent = color principal)
Rectangle {
    id: button
    property string text
    property bool accent: false
    signal clicked()

    implicitWidth: buttonLabel.implicitWidth + 32
    implicitHeight: 36
    radius: height / 2
    opacity: enabled ? 1 : 0.4
    color: accent ? (buttonMouse.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary)
        : buttonMouse.containsMouse ? Theme.surfaceHigh : Theme.surface

    Label {
        id: buttonLabel
        anchors.centerIn: parent
        text: button.text
        color: button.accent ? Theme.primaryFg : Theme.text
    }
    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (button.enabled) button.clicked()
    }
}
