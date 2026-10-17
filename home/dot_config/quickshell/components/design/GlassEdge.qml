import QtQuick
import qs.services

// Brillo del canto superior del vidrio: una línea de 1 px más clara en el centro.
// Se pone dentro del fondo de una superficie (anclado arriba).
//   Rectangle { …; GlassEdge { inset: radius } }
Rectangle {
    // Margen a los lados (el radio de la superficie, para no pisar las esquinas)
    property real inset: Design.radiusMd

    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    width: parent.width - inset * 2
    height: 1
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: "transparent" }
        GradientStop { position: 0.5; color: Design.borderHighlight }
        GradientStop { position: 1; color: "transparent" }
    }
}
