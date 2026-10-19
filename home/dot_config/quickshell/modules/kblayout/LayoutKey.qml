import QtQuick
import qs.components.design
import qs.services

// Una tecla del mapa de la distribución. Con letras (Mayús = la misma en mayúscula) se
// ve solo la mayúscula, como en un teclado de verdad; si no, lo de Mayús arriba y lo
// normal abajo a la izquierda, y lo de AltGr (y AltGr + Mayús) a la derecha, en acento.
// Las de control (Tab, Mayús…) llevan su nombre en gris.
Rectangle {
    id: key

    // Código de la tecla (AE01…) o "" para las de control
    property string code
    property string label
    property real units: 1
    property real unit: 44
    // Sin dibujo propio (el trozo de abajo del Intro ISO, que va pegado al de arriba)
    property bool ghost: false

    readonly property var chars: KeyboardLayout.mapKeys[code] ?? ["", "", "", ""]
    readonly property bool letter: chars[0] !== "" && chars[0] !== chars[1] && chars[0].toUpperCase() === chars[1]

    width: units * unit - 4
    height: unit - 4
    radius: Design.radiusSm
    color: ghost ? "transparent" : code === "" ? Design.surface1 : Design.surface2
    border.color: ghost ? "transparent" : Design.border

    // Control: su nombre
    Txt {
        visible: key.code === "" && !key.ghost
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 6
        text: key.label
        textStyle: Design.caption
        color: Design.onSurfaceVariant
    }

    // Letra: solo la mayúscula, centrada
    Txt {
        visible: key.letter
        anchors.centerIn: parent
        text: key.chars[1]
        font.pixelSize: 17
        font.weight: Font.Medium
    }
    // Resto: Mayús arriba y normal abajo
    Txt {
        visible: key.code !== "" && !key.letter
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 7
        anchors.topMargin: 3
        text: key.chars[1]
        font.pixelSize: 13
        color: Design.onSurfaceVariant
    }
    Txt {
        visible: key.code !== "" && !key.letter
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 7
        anchors.bottomMargin: 3
        text: key.chars[0]
        font.pixelSize: 15
        font.weight: Font.Medium
    }
    // AltGr (abajo) y AltGr + Mayús (arriba), a la derecha
    Txt {
        visible: key.code !== ""
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 6
        anchors.topMargin: 3
        text: key.chars[3] !== key.chars[2] ? key.chars[3] : ""
        font.pixelSize: 11
        color: Design.alpha(Design.accent, 0.75)
    }
    Txt {
        visible: key.code !== ""
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 6
        anchors.bottomMargin: 3
        text: key.chars[2]
        font.pixelSize: 12
        color: Design.accent
    }
}
