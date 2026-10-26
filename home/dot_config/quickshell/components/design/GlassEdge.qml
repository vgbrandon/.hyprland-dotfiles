import QtQuick
import qs.services

// Canto del vidrio: el brillo especular de 1 px arriba (más claro en el centro). Se pone
// dentro del fondo de una superficie, antes del contenido.
//   Rectangle { …; GlassEdge { inset: radius } }
Item {
    id: root

    // El radio de la superficie (y el margen del brillo a los lados)
    property real inset: Design.radiusMd

    anchors.fill: parent

    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - root.inset * 2
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Design.borderHighlight }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
