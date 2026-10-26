import QtQuick
import QtQuick.Effects
import qs.services

// Interruptor: bola blanca con sombra que se desliza suave y se estira al pulsar;
// encendido, la pista en el acento con un leve resplandor.
// follow = cambia solo al pulsarlo; con false solo avisa (checked lo decide quien lo usa)
//   Toggle { checked: true; onToggled: … }
Item {
    id: root

    property bool checked: false
    property bool follow: true
    signal toggled()

    implicitWidth: 34
    implicitHeight: 18
    opacity: enabled ? 1 : 0.38

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Design.alpha("#ffffff", 0.14)
        border.color: root.checked ? "transparent" : Design.border
        border.width: 1

        AccentFill {
            opacity: root.checked ? 1 : 0
            glow: root.checked && root.enabled
            Behavior on opacity { NumberAnimation { duration: Design.normal } }
        }
    }
    Rectangle {
        id: knob
        readonly property int d: 14
        width: d + (mouse.pressed ? 4 : 0)
        height: d
        radius: d / 2
        y: 2
        x: root.checked ? root.width - width - 2 : 2
        color: "#ffffff"
        Behavior on x { NumberAnimation { duration: Design.springDuration; easing.type: Design.spring; easing.overshoot: Design.overshoot } }
        Behavior on width { NumberAnimation { duration: Design.fast } }
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.35
            shadowBlur: 0.3
            shadowVerticalOffset: 1
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: root.enabled
        onClicked: {
            if (root.follow) root.checked = !root.checked;
            root.toggled();
        }
    }
}
