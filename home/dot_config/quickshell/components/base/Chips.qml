import QtQuick
import QtQuick.Layouts
import qs.services

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

            Chip {
                required property var modelData

                text: chips.format(modelData)
                // Números con tolerancia (escalas como 1.25); texto, igual exacto
                selected: typeof modelData === "number"
                    ? Math.abs(Number(chips.value) - modelData) < 0.001
                    : chips.value === modelData
                onClicked: chips.picked(modelData)
            }
        }
    }
}
