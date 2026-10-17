import QtQuick
import Quickshell.Widgets
import qs.components.base
import qs.components.design
import qs.services

// Miniatura de un fondo (diseño Prisma): esquinas redondeadas; el fondo actual con
// borde de acento y una marca; con el ratón encima (o seleccionada con el teclado),
// un aro claro. Con full (cuando se ve grande) carga la imagen original a buena
// resolución encima de la miniatura de la caché. La usan el carrusel y la cuadrícula.
Item {
    id: root

    required property string file
    property bool highlighted: false
    property bool full: false
    readonly property bool active: file === Theme.wallpaper

    // Aro: acento si es el actual, claro si está señalada
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: Design.radiusMd + 4
        color: "transparent"
        border.width: 2
        border.color: root.active ? Design.accent : root.highlighted ? Design.alpha(Design.onSurface, 0.6) : "transparent"
        Behavior on border.color { ColorAnimation { duration: Design.fast } }
    }
    ClippingRectangle {
        anchors.fill: parent
        radius: Design.radiusMd
        color: Design.surface1

        Image {
            anchors.fill: parent
            source: root.file !== "" ? "file://" + (Wallpaper.thumbs[root.file] ?? root.file) : ""
            sourceSize.width: 400
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        // La original, nítida (aparece con un fundido cuando termina de cargar)
        Image {
            id: fullImage
            anchors.fill: parent
            source: root.full && root.file !== "" ? "file://" + root.file : ""
            sourceSize.width: 1440
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Design.normal } }
        }
    }
    // Marca del fondo actual
    Rectangle {
        visible: root.active
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        width: 24
        height: 24
        radius: Design.radiusSm
        color: Design.accent

        Icon {
            anchors.centerIn: parent
            text: Theme.iCheck
            color: Design.onAccent
            font.pixelSize: 16
        }
    }
}
