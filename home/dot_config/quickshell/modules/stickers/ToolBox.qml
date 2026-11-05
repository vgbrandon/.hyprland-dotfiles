import QtQuick
import QtQuick.Layouts
import qs.components.design
import qs.services

// Una sección del panel de herramientas del editor de stickers: título, nota y contenido
Rectangle {
    id: box
    property string title
    property string note
    default property alias content: body.data

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 32
    radius: Design.radiusMd
    color: Design.alpha("#ffffff", 0.045)
    border.color: Design.border

    ColumnLayout {
        id: col
        x: 16
        y: 16
        width: parent.width - 32
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Txt { text: box.title; textStyle: Design.headline }
            Txt {
                Layout.fillWidth: true
                visible: box.note !== ""
                text: box.note
                textStyle: Design.caption
                color: Design.onSurfaceVariant
                wrapMode: Text.Wrap
            }
        }
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 10
        }
    }
}
