import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services

// Franja con el fondo de pantalla dentro de la guía de estilo, para ver los materiales
// transparentes de verdad: lo de dentro usa backdrop: <id>.wall. El contenido (un
// layout) ocupa todo el ancho.
ClippingRectangle {
    id: stage
    property alias wall: stageWall
    default property alias content: stageInner.data
    Layout.fillWidth: true
    implicitHeight: (stageInner.children.length > 0 ? stageInner.children[0].implicitHeight : 0) + 48
    radius: 10
    color: "#000000"

    Image {
        id: stageWall
        anchors.fill: parent
        source: Theme.wallpaper !== "" ? "file://" + Theme.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 1920
    }
    Item {
        id: stageInner
        x: 24
        y: 24
        width: parent.width - 48
        height: parent.height - 48
        onChildrenChanged: {
            for (const c of children) c.width = Qt.binding(() => stageInner.width);
        }
    }
}
