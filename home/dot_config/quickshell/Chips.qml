import QtQuick
import QtQuick.Layouts

// Fila de opciones con etiqueta encima; la elegida se resalta
ColumnLayout {
    id: chips
    property string label
    property var options: []
    property var format: v => String(v)
    property var value
    signal picked(var v)

    spacing: 4

    Label {
        Layout.leftMargin: 4
        text: chips.label
        color: Theme.subtext
        font.pixelSize: Theme.fontSize
    }
    Row {
        spacing: 4

        Repeater {
            model: chips.options

            Rectangle {
                id: chip
                required property var modelData
                // Números con tolerancia (escalas como 1.25); texto, igual exacto
                readonly property bool on: typeof modelData === "number"
                    ? Math.abs(Number(chips.value) - modelData) < 0.001
                    : chips.value === modelData

                width: chipLabel.implicitWidth + 20
                height: 32
                radius: height / 2
                color: on ? Theme.primary : chipMouse.containsMouse ? Theme.surfaceHigh : Theme.surface

                Label {
                    id: chipLabel
                    anchors.centerIn: parent
                    text: chips.format(chip.modelData)
                    color: chip.on ? Theme.primaryFg : Theme.text
                }
                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: chips.picked(chip.modelData)
                }
            }
        }
    }
}
