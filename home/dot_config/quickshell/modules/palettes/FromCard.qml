import QtQuick
import QtQuick.Layouts

// Del generador → al tema: el color de origen (o «calculado»), una flecha y el papel
Rectangle {
    id: card
    property var from
    property string to
    property string name
    property string detail
    // Opcional: el token de Design que lo usa
    property string token
    implicitHeight: 78
    radius: 10
    color: "#1a1a1e"
    border.color: "#26262c"
    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10
        ColumnLayout {
            spacing: 2
            Rectangle {
                implicitWidth: 40
                implicitHeight: 40
                radius: 8
                color: card.from ?? "transparent"
                border.width: card.from ? 0 : 1
                border.color: "#55555e"
                GuideText { anchors.centerIn: parent; visible: !card.from; text: "calc."; size: 9; color: "#8a8a92" }
            }
            GuideText { text: card.from ? "generador" : "calculado"; size: 9; color: "#77777f" }
        }
        GuideText { text: "→"; size: 20; color: "#5a5a64" }
        Rectangle {
            implicitWidth: 52
            implicitHeight: 52
            radius: 10
            color: card.to
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            GuideText { text: card.name; size: 14; weight: Font.Medium }
            GuideText { Layout.fillWidth: true; text: card.detail; size: 11; color: "#8a8a92"; wrapMode: Text.Wrap }
            GuideText {
                text: card.to + (card.token !== "" ? "  ·  Design." + card.token : "")
                size: 10
                color: "#77777f"
                font.family: "JetBrainsMono Nerd Font"
            }
        }
    }
}
