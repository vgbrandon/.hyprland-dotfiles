import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.services

// Tarjeta (fondo surface) con cabecera opcional (icono, título y subtítulo) y el
// contenido en columna debajo.
//   Card { icon: Theme.iCpu; title: "CPU"; Label { … } }
Rectangle {
    id: card

    default property alias content: body.data
    property alias spacing: body.spacing
    property string icon
    property string title
    property string subtitle
    property int padding: 12

    implicitWidth: layout.implicitWidth + padding * 2
    implicitHeight: layout.implicitHeight + padding * 2
    radius: Theme.radiusSmall
    color: Theme.surface

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: card.padding
        spacing: 8

        RowLayout {
            visible: card.title !== ""
            spacing: 8

            Icon {
                visible: card.icon !== ""
                text: card.icon
                color: Theme.primary
            }
            Label {
                text: card.title
            }
            Label {
                Layout.fillWidth: true
                visible: card.subtitle !== ""
                text: card.subtitle
                color: Theme.subtext
                font.pixelSize: Theme.fontSize
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 8
        }
    }
}
