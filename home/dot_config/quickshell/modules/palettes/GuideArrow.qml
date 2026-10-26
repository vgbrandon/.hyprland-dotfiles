import QtQuick
import QtQuick.Layouts

// Flecha entre los pasos de las guías, con lo que pasa de uno al siguiente
RowLayout {
    id: arrow
    property string text
    Layout.fillWidth: true
    spacing: 12
    GuideText { Layout.leftMargin: 26; text: "↓"; size: 22; color: "#5a5a64" }
    GuideText { Layout.fillWidth: true; text: arrow.text; size: 12; color: "#8a8a92"; wrapMode: Text.Wrap }
}
