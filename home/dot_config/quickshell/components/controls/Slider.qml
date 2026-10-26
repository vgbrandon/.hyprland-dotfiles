import QtQuick
import QtQuick.Effects
import qs.components.design
import qs.services

// Barra fina que se llena según "value" (0..1). Si es interactiva lleva la bola en
// relieve (diseño Velure) y un clic o un arrastre emite moved(fracción); si
// no, solo muestra el valor (uso de disco, subidas…).
Item {
    id: root

    property real value: 0
    property color color: Design.accent
    property bool interactive: true
    signal moved(real fraction)

    implicitHeight: 3

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Design.alpha("#ffffff", 0.14)
    }
    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, root.value))
        height: parent.height
        radius: height / 2
        color: root.color
        Behavior on width { NumberAnimation { duration: 150 } }
        // Con el color del acento, en relleno de acento
        AccentFill { visible: root.color === Design.accent }
    }

    // Bola (solo si se puede mover)
    Rectangle {
        visible: root.interactive
        width: knobMouse.pressed ? 16 : 13
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: Math.round(Math.max(0, Math.min(1, root.value)) * (parent.width - width))
        color: "#ffffff"
        Behavior on width { NumberAnimation { duration: Design.fast; easing.type: Design.spring } }
        Behavior on x { NumberAnimation { duration: 150 } }
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
        id: knobMouse
        visible: root.interactive
        anchors.fill: parent
        // Más fácil de atinar que los 4 px de la barra
        anchors.topMargin: -8
        anchors.bottomMargin: -8
        cursorShape: Qt.PointingHandCursor
        onPressed: e => root.moved(Math.max(0, Math.min(1, e.x / width)))
        onPositionChanged: e => {
            if (pressed) root.moved(Math.max(0, Math.min(1, e.x / width)));
        }
    }
}
