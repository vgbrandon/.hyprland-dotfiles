import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// Tarjeta de una sección: título, subtítulo, algo a la derecha (trailing) y el contenido
Rectangle {
    id: box
    property string title
    property string subtitle
    property Item trailing: null
    property bool enabledContent: true
    default property alias content: body.data

    implicitWidth: col.implicitWidth + 36
    implicitHeight: col.implicitHeight + 36
    radius: Design.radiusMd
    color: Design.alpha("#ffffff", 0.045)
    border.color: Design.border

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        RowLayout {
            visible: box.title !== ""
            Layout.fillWidth: true
            spacing: 10
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Txt { Layout.fillWidth: true; text: box.title; textStyle: Design.headline }
                Txt {
                    Layout.fillWidth: true
                    visible: box.subtitle !== ""
                    text: box.subtitle
                    textStyle: Design.caption
                    color: Design.onSurfaceVariant
                }
            }
            Item {
                implicitWidth: box.trailing ? box.trailing.implicitWidth : 0
                implicitHeight: box.trailing ? box.trailing.implicitHeight : 0
                data: box.trailing ? [box.trailing] : []
            }
        }
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            enabled: box.enabledContent
            opacity: enabled ? 1 : 0.4
        }
    }
}
