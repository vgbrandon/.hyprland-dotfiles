import QtQuick
import qs.services

// Logo de OpenCode: un marco con la mitad de abajo del hueco rellena (como su icono).
// Dibujado con rectángulos para que tome el color del tema y quede nítido a cualquier
// tamaño. Proporciones del original (512×512): 4×5 bloques, marco de 1 bloque.
//   OpenCodeLogo { size: 16; color: Theme.text }
Item {
    id: root

    // Alto en píxeles (el ancho es 4/5)
    property int size: 16
    property color color: Theme.text
    // Un bloque, en píxeles enteros para que los bordes no queden borrosos
    readonly property int unit: Math.max(1, Math.round(size / 5))

    implicitWidth: unit * 4
    implicitHeight: unit * 5

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: root.unit
        border.color: root.color
    }
    Rectangle {
        x: root.unit
        y: root.unit * 2
        width: root.unit * 2
        height: root.unit * 2
        color: Theme.withAlpha(root.color, 0.45)
    }
}
