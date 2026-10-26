import QtQuick
import QtQuick.Layouts

// Un paso de las guías: número, título, subtítulo y contenido, en una tarjeta neutra
Rectangle {
    id: step
    property string number
    property string title
    property string subtitle
    default property alias content: body.data
    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 40
    radius: 14
    color: "#141417"
    border.color: "#24242a"
    ColumnLayout {
        id: col
        x: 20
        y: 20
        width: parent.width - 40
        spacing: 14
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Rectangle {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                color: "#26262c"
                GuideText { anchors.centerIn: parent; text: step.number; size: 14; weight: Font.DemiBold }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                GuideText { text: step.title; size: 20 }
                GuideText { Layout.fillWidth: true; text: step.subtitle; size: 12; color: "#8a8a92"; wrapMode: Text.Wrap }
            }
        }
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 12
        }
    }
}
