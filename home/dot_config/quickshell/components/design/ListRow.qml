import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.services

// Fila de una lista: icono, título, subtítulo y lo que se ponga a la derecha.
// selected = contenedor tonal.
//   ListRow { icon: Theme.iWifi; title: "Casa"; subtitle: "Conectado"; selected: true }
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool selected: false
    default property alias trailing: trailingRow.data
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: subtitle !== "" ? 48 : 38
    radius: Design.radiusSm
    color: selected ? Design.tonal : "transparent"
    Behavior on color { ColorAnimation { duration: Design.normal } }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: mouse.pressed ? Design.pressLayer : mouse.containsMouse ? Design.hoverLayer : "transparent"
        Behavior on color { ColorAnimation { duration: Design.fast } }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12

        Icon {
            visible: root.icon !== ""
            text: root.icon
            color: root.selected ? Design.onTonal : Design.onSurfaceVariant
            font.pixelSize: 18
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Txt {
                Layout.fillWidth: true
                text: root.title
                color: root.selected ? Design.onTonal : Design.onSurface
            }
            Txt {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                text: root.subtitle
                textStyle: Design.caption
                color: root.selected ? Design.alpha(Design.onTonal, 0.75) : Design.onSurfaceVariant
            }
        }
        RowLayout {
            id: trailingRow
            spacing: 6
        }
    }
}
