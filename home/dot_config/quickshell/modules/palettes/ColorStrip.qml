import QtQuick
import QtQuick.Layouts

// Una tira de colores con su nombre (secciones del generador)
ColumnLayout {
    id: strip
    property string label
    property var colors: []
    property bool big: false
    spacing: 4
    GuideLabel { text: strip.label }
    Row {
        Repeater {
            model: strip.colors
            Rectangle {
                required property var modelData
                width: strip.big ? 44 : 22
                height: strip.big ? 26 : 18
                color: modelData ?? "transparent"
            }
        }
    }
}
