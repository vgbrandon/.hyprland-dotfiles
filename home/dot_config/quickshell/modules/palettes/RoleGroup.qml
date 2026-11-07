import QtQuick
import QtQuick.Layouts
import qs.services

// Un grupo de tokens: [token, nombre] o [token, nombre, propiedad de Design]
ColumnLayout {
    id: group
    property string label
    property var roles: []
    // Los tokens (bg, primary…)
    property var source: null
    spacing: 8
    GuideLabel { text: group.label }
    Flow {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: group.roles
            Column {
                required property var modelData
                spacing: 3
                Rectangle {
                    width: 64
                    height: 40
                    radius: Design.corner(8)
                    color: group.source ? group.source[parent.modelData[0]] : "#000"
                    border.color: "#2a2a30"
                }
                GuideText { text: parent.modelData[1]; size: 11 }
                GuideText { text: group.source ? group.source[parent.modelData[0]] : ""; size: 9; color: "#77777f"; font.family: "JetBrainsMono Nerd Font" }
                GuideText { visible: parent.modelData.length > 2; text: parent.modelData[2] ?? ""; size: 9; color: "#8a8a92"; font.family: "JetBrainsMono Nerd Font" }
            }
        }
    }
}
