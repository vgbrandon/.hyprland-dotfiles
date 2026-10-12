import QtQuick
import qs.services

// Barra fina que se llena según "value" (0..1). Si es interactiva, un clic o un
// arrastre emite moved(fracción); si no, solo muestra el valor (uso de disco, subidas…).
Item {
    id: root

    property real value: 0
    property color color: Theme.primary
    property bool interactive: true
    signal moved(real fraction)

    implicitHeight: 4

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceHigh
    }
    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, root.value))
        height: parent.height
        radius: height / 2
        color: root.color
        Behavior on width { NumberAnimation { duration: 150 } }
    }

    MouseArea {
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
