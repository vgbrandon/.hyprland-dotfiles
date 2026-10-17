import QtQuick
import qs.components.base
import qs.services

// Botón de icono. kind: "plain" (sin fondo hasta pasar el ratón), "tonal" o "filled".
// checked = activo (contenedor tonal). clicked(button) dice con qué botón (para
// aceptar el derecho: acceptedButtons: Qt.LeftButton | Qt.RightButton).
//   IconBtn { icon: Theme.iSettings; onClicked: … }
Rectangle {
    id: root

    property string icon
    property string kind: "plain"
    property bool checked: false
    property int size: 32
    property int iconSize: 17
    property alias acceptedButtons: mouse.acceptedButtons
    signal clicked(int button)

    readonly property bool on: checked || kind === "tonal"
    property color iconColor: kind === "filled" ? Design.onAccent : on ? Design.onTonal : Design.onSurfaceVariant

    implicitWidth: size
    implicitHeight: size
    radius: Design.radiusSm
    color: kind === "filled" ? Design.accent : on ? Design.tonal : "transparent"
    opacity: enabled ? 1 : 0.38
    Behavior on color { ColorAnimation { duration: Design.normal } }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: mouse.pressed ? Design.pressLayer : mouse.containsMouse ? Design.hoverLayer : "transparent"
        Behavior on color { ColorAnimation { duration: Design.fast } }
    }
    Icon {
        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
        font.pixelSize: root.iconSize
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
