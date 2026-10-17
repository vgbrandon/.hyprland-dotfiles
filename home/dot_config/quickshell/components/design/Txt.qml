import QtQuick
import qs.services

// Texto del diseño nuevo con un estilo de la escala (Design.body, Design.title…)
//   Txt { text: "Hola"; textStyle: Design.headline }
Text {
    property var textStyle: Design.body

    color: Design.onSurface
    font.family: Design.font
    font.pixelSize: textStyle.size
    font.weight: textStyle.weight
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
}
