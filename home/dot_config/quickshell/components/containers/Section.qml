import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.services

// Grupo con un título pequeño en gris (y un icono opcional) y su contenido debajo
//   Section { title: "Dispositivos"; SwitchRow { … } }
ColumnLayout {
    id: root

    default property alias content: body.data
    property alias contentSpacing: body.spacing
    property string title
    property string icon
    property color iconColor: Theme.subtext

    Layout.fillWidth: true
    spacing: 6

    RowLayout {
        visible: root.title !== ""
        Layout.leftMargin: 6
        spacing: 6

        Icon {
            visible: root.icon !== ""
            text: root.icon
            color: root.iconColor
            font.pixelSize: 14
        }
        Label {
            text: root.title
            color: Theme.subtext
            font.pixelSize: Theme.fontSize
        }
    }
    ColumnLayout {
        id: body
        Layout.fillWidth: true
        // Solo se estira si la sección lo pide (p. ej. una lista que llena el panel);
        // si no, las secciones reparten el alto sobrante y aparecen huecos
        Layout.fillHeight: root.Layout.fillHeight
        spacing: 4
    }
}
