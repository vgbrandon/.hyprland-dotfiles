import QtQuick
import QtQuick.Effects
import qs.services

// Interruptor: pista fina y bola con sombra (como en macOS), pista de acento encendido
// follow = cambia solo al pulsarlo; con false solo avisa (checked lo decide quien lo usa)
//   Toggle { checked: true; onToggled: … }
Item {
    id: root

    property bool checked: false
    property bool follow: true
    signal toggled()

    implicitWidth: 38
    implicitHeight: 22
    opacity: enabled ? 1 : 0.38

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Design.accent : Design.surface3
        border.color: root.checked ? "transparent" : Design.outlineVariant
        border.width: 1
        Behavior on color { ColorAnimation { duration: Design.normal } }
    }
    Rectangle {
        id: knob
        width: 18
        height: 18
        radius: 9
        y: 2
        x: root.checked ? root.width - width - 2 : 2
        color: root.checked ? Design.onAccent : Design.onSurfaceVariant
        Behavior on x { NumberAnimation { duration: Design.normal; easing.type: Design.easing } }
        Behavior on color { ColorAnimation { duration: Design.normal } }
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.3
            shadowBlur: 0.3
            shadowVerticalOffset: 1
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: root.enabled
        onClicked: {
            if (root.follow) root.checked = !root.checked;
            root.toggled();
        }
    }
}
