import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.services

// Botón con texto (e icono opcional). kind: "filled" (acento, lo principal), "tonal"
// (contenedor tonal), "outline" (borde) o "text" (sin fondo).
//   Btn { kind: "tonal"; text: "Guardar"; icon: Theme.iCheck }
Rectangle {
    id: root

    property string kind: "tonal"
    property string text
    property string icon
    property bool small: false
    signal clicked()

    readonly property color fg: kind === "filled" ? Design.onAccent : kind === "tonal" ? Design.onTonal
        : kind === "outline" ? Design.onSurface : Design.accent

    implicitWidth: row.implicitWidth + (small ? 20 : 28)
    implicitHeight: small ? 28 : 34
    radius: Design.radiusSm
    color: kind === "filled" ? Design.accent : kind === "tonal" ? Design.tonal : "transparent"
    border.color: kind === "outline" ? Design.outlineVariant : "transparent"
    border.width: kind === "outline" ? 1 : 0
    opacity: enabled ? 1 : 0.38

    // Capa de estado: pasar el ratón / pulsar
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: mouse.pressed ? Design.pressLayer : mouse.containsMouse ? Design.hoverLayer : "transparent"
        Behavior on color { ColorAnimation { duration: Design.fast } }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Icon {
            visible: root.icon !== ""
            text: root.icon
            color: root.fg
            font.pixelSize: root.small ? 14 : 16
        }
        Txt {
            text: root.text
            textStyle: Design.label
            color: root.fg
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
