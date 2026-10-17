import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.services

// Mosaico de ajuste rápido (centro de control): icono en un círculo, nombre y estado.
// Encendido = contenedor de acento.
//   Tile { icon: Theme.iWifi; title: "Wi-Fi"; subtitle: "Casa"; checked: true }
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool checked: false

    Layout.fillWidth: true
    implicitHeight: 56
    radius: Design.radiusMd
    color: checked ? Design.accentContainer : Design.surface2
    border.color: Design.border
    border.width: 1
    Behavior on color { ColorAnimation { duration: Design.normal } }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: mouse.pressed ? Design.pressLayer : mouse.containsMouse ? Design.hoverLayer : "transparent"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        Rectangle {
            implicitWidth: 34
            implicitHeight: 34
            radius: 17
            color: root.checked ? Design.accent : Design.surface3
            Behavior on color { ColorAnimation { duration: Design.normal } }

            Icon {
                anchors.centerIn: parent
                text: root.icon
                color: root.checked ? Design.onAccent : Design.onSurfaceVariant
                font.pixelSize: 17
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Txt {
                Layout.fillWidth: true
                text: root.title
                textStyle: Design.label
                color: root.checked ? Design.onAccentContainer : Design.onSurface
            }
            Txt {
                Layout.fillWidth: true
                text: root.subtitle
                textStyle: Design.caption
                color: root.checked ? Design.alpha(Design.onAccentContainer, 0.75) : Design.onSurfaceVariant
            }
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.checked = !root.checked
    }
}
