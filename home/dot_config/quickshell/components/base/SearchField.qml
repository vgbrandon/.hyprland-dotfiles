import QtQuick
import QtQuick.Layouts
import qs.services

// Campo de búsqueda grande (lanzador, portapapeles): icono, texto y aviso cuando
// está vacío. Cada tecla llega antes a keyPressed(evento): quien lo usa maneja las
// suyas (flechas, Enter…) y marca e.accepted = true; el resto las procesa el campo.
//   SearchField { icon: Theme.iSearch; placeholder: "Buscar…"; onKeyPressed: e => … }
Rectangle {
    id: root

    property string icon
    property string placeholder
    property alias text: input.text
    signal keyPressed(var event)

    function forceActiveFocus() {
        input.forceActiveFocus();
    }

    Layout.fillWidth: true
    implicitHeight: 44
    radius: Design.radiusMd
    color: Design.surface0
    border.color: input.activeFocus ? Design.alpha(Design.accent, 0.6) : Design.outlineVariant
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 12

        Icon {
            text: root.icon
            color: Theme.subtext
            font.pixelSize: 20
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            color: Theme.text
            selectionColor: Design.alpha(Design.accent, 0.4)
            font.family: Theme.font
            font.pixelSize: 16
            clip: true
            Keys.onPressed: e => root.keyPressed(e)

            Text {
                visible: input.text === ""
                text: root.placeholder
                color: Theme.subtext
                font: input.font
            }
        }
    }
}
