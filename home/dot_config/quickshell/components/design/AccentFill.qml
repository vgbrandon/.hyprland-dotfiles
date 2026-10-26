import QtQuick
import qs.services

// Relleno del acento: liso, sin brillo ni resplandor. secondary = énfasis secundario
// (escritorio activo, mosaicos encendidos, casillas, insignias): en blanco roto. Va
// dentro de lo que se rellena y toma su radio. glow se mantiene por compatibilidad.
//   Rectangle { …; AccentFill {} }
Rectangle {
    property bool glow: false
    property bool secondary: false

    anchors.fill: parent
    radius: parent ? parent.radius ?? 0 : 0
    color: secondary ? Design.hi : Design.accent
}
