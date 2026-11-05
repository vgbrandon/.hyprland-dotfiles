import QtQuick
import QtQuick.Layouts
import qs.components.design
import qs.services

// Elegir un color: muestras comunes en stickers y el código hex a mano
ColumnLayout {
    id: row
    property string label
    property color value
    signal picked(color c)

    readonly property var swatches: ["#ffffff", "#000000", "#ffd400", "#ff3b30", "#ff8a00", "#34c759",
        "#0a84ff", "#bf5af2", "#ff2d92", "#8e8e93"]

    Layout.fillWidth: true
    spacing: 6
    Txt { text: row.label; textStyle: Design.label; color: Design.onSurfaceVariant }
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: row.swatches
            Rectangle {
                required property string modelData
                implicitWidth: 22
                implicitHeight: 22
                radius: 11
                color: modelData
                border.width: Qt.colorEqual(row.value, modelData) ? 2 : 1
                border.color: Qt.colorEqual(row.value, modelData) ? Design.accent : Design.border
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.picked(parent.modelData)
                }
            }
        }
        Item { Layout.fillWidth: true }
        Field {
            id: hex
            Layout.preferredWidth: 96
            placeholder: "#hex"
            text: row.value.toString().slice(0, 7)
            onTextChanged: {
                if (/^#[0-9a-fA-F]{6}$/.test(text) && !Qt.colorEqual(Qt.color(text), row.value))
                    row.picked(text);
            }
        }
    }
}
