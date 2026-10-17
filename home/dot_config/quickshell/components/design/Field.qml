import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.services

// Campo de texto: fondo hundido, y al enfocarlo un anillo de acento (como en macOS).
// focusInput() le da el foco; cada tecla pasa antes por keyPressed(evento): quien lo
// usa maneja las suyas (flechas, Enter…) y marca e.accepted = true.
//   Field { icon: Theme.iSearch; placeholder: "Buscar" }
Rectangle {
    id: root

    property string icon
    property string placeholder
    property alias text: input.text
    signal keyPressed(var event)

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitWidth: 240
    implicitHeight: 34
    radius: Design.radiusSm
    color: Design.surface0
    border.color: input.activeFocus ? Design.accent : Design.outlineVariant
    border.width: 1

    // Anillo de foco
    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: parent.radius + 3
        color: "transparent"
        border.color: Design.alpha(Design.accent, 0.35)
        border.width: 3
        opacity: input.activeFocus ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Design.fast } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Icon {
            visible: root.icon !== ""
            text: root.icon
            color: Design.onSurfaceVariant
            font.pixelSize: 15
        }
        TextInput {
            id: input
            Layout.fillWidth: true
            color: Design.onSurface
            selectionColor: Design.alpha(Design.accent, 0.4)
            selectedTextColor: Design.onSurface
            font.family: Design.font
            font.pixelSize: Design.body.size
            clip: true
            Keys.onPressed: e => root.keyPressed(e)

            Text {
                visible: input.text === ""
                text: root.placeholder
                color: Design.muted
                font: input.font
            }
        }
    }
}
