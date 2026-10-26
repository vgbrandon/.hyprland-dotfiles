import QtQuick
import qs.components.base
import qs.services

// Botón de icono. kind: "plain" (sin fondo hasta pasar el ratón), "tonal" o "filled"
// (relleno de acento). checked = activo (selección de acento). clicked(button) dice con qué botón (para
// aceptar el derecho: acceptedButtons: Qt.LeftButton | Qt.RightButton).
//   IconBtn { icon: Theme.iSettings; onClicked: … }
Rectangle {
    id: root

    property string icon
    property string kind: "plain"
    property bool checked: false
    property int size: 32
    property int iconSize: 17
    // Corrección de la posición del icono en esta instancia, en píxeles (ver Icon)
    property real iconOffsetX: 0
    property real iconOffsetY: 0
    property alias acceptedButtons: mouse.acceptedButtons
    signal clicked(int button)

    readonly property bool on: checked || kind === "tonal"
    property color iconColor: kind === "filled" ? Design.onAccent : checked ? Design.accent : kind === "tonal" ? Design.onSurface : Design.onSurfaceVariant

    implicitWidth: size
    implicitHeight: size
    radius: Design.radiusSm
    color: kind === "filled" ? "transparent" : checked ? Design.selection : kind === "tonal" ? Design.raised : "transparent"
    opacity: enabled ? 1 : 0.38
    scale: mouse.pressed ? 0.92 : 1
    Behavior on scale { NumberAnimation { duration: Design.fast } }
    Behavior on color { ColorAnimation { duration: Design.normal } }

    AccentFill {
        visible: root.kind === "filled"
        glow: root.enabled
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: mouse.pressed ? Design.pressLayer : mouse.containsMouse ? Design.hoverLayer : "transparent"
        Behavior on color { ColorAnimation { duration: Design.fast } }
    }
    // Centrado en píxeles enteros: con decimales el icono queda medio píxel desplazado
    Icon {
        x: Math.round((root.width - advance) / 2)
        y: Math.round((root.height - height) / 2)
        text: root.icon
        color: root.iconColor
        font.pixelSize: root.iconSize
        offsetX: root.iconOffsetX
        offsetY: root.iconOffsetY
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: e => root.clicked(e.button)
    }
}
