import QtQuick
import QtQuick.Effects
import qs.services

// Deslizador: pista fina con la parte llena en acento y bola con sombra
//   Slide { value: 0.4; onMoved: v => … }
Item {
    id: root

    property real value: 0.5
    signal moved(real v)

    implicitWidth: 200
    implicitHeight: 20

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Design.surface3

        Rectangle {
            width: knob.x + knob.width / 2
            height: parent.height
            radius: 2
            color: Design.accent
        }
    }
    Rectangle {
        id: knob
        width: area.pressed ? 18 : 16
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: Math.round(root.value * (root.width - width))
        color: Design.onSurface
        Behavior on width { NumberAnimation { duration: Design.fast } }
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.35
            shadowBlur: 0.35
            shadowVerticalOffset: 1
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function set(mx) {
            root.value = Math.max(0, Math.min(1, mx / width));
            root.moved(root.value);
        }
        onPressed: e => set(e.x)
        onPositionChanged: e => { if (pressed) set(e.x); }
        onWheel: e => {
            root.value = Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05)));
            root.moved(root.value);
        }
    }
}
