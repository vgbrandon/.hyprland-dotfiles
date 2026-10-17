import QtQuick
import QtQuick.Layouts
import qs.services

// Cabecera de un panel o ventana: icono, título y subtítulo. Lo que se ponga dentro
// (botones, interruptores…) va a la derecha.
//   PanelHeader { icon: Theme.iWifi; title: "Wi-Fi"; subtitle: "Conectado"; Switch { … } }
RowLayout {
    id: root

    property string icon
    property color iconColor: Design.onSurface
    property string title
    property string subtitle
    default property alias trailing: trailingRow.data

    Layout.fillWidth: true
    Layout.leftMargin: 6
    spacing: 10

    Icon {
        visible: root.icon !== ""
        text: root.icon
        color: root.iconColor
        font.pixelSize: 20
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Label {
            Layout.fillWidth: true
            text: root.title
            font.pixelSize: Design.headline.size
            font.weight: Design.headline.weight
        }
        Label {
            Layout.fillWidth: true
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Design.onSurfaceVariant
            font.pixelSize: Design.caption.size
        }
    }
    RowLayout {
        id: trailingRow
        visible: children.length > 0
        spacing: 8
    }
}
