import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.services

// Campo de texto: fondo hundido y, al enfocarlo, el borde en acento. big = el buscador
// grande de las ventanas (lanzador, portapapeles, atajos…).
// focusInput() le da el foco; cada tecla pasa antes por keyPressed(evento): quien lo
// usa maneja las suyas (flechas, Enter…) y marca e.accepted = true.
//   Field { icon: Theme.iSearch; placeholder: "Buscar" }
//   Field { big: true; Layout.fillWidth: true; icon: Theme.iSearch; placeholder: "Buscar…" }
Rectangle {
    id: root

    property string icon
    property string placeholder
    property alias text: input.text
    property bool big: false
    // TextInput.Password para contraseñas
    property alias echoMode: input.echoMode
    signal keyPressed(var event)

    function focusInput() {
        input.forceActiveFocus();
    }
    // Pega lo que hay en el portapapeles
    function paste() {
        input.paste();
        input.forceActiveFocus();
    }

    implicitWidth: 240
    implicitHeight: big ? 44 : 34
    radius: big ? Design.radiusMd : Design.radiusSm
    color: Design.surface0
    border.color: input.activeFocus ? Design.alpha(Design.accent, 0.6) : Design.outlineVariant
    border.width: 1
    Behavior on border.color { ColorAnimation { duration: Design.fast } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.big ? 18 : 10
        anchors.rightMargin: root.big ? 18 : 10
        spacing: root.big ? 12 : 8

        Icon {
            visible: root.icon !== ""
            text: root.icon
            color: Design.onSurfaceVariant
            font.pixelSize: root.big ? 20 : 15
        }
        TextInput {
            id: input
            Layout.fillWidth: true
            color: Design.onSurface
            selectionColor: Design.alpha(Design.accent, 0.4)
            selectedTextColor: Design.onSurface
            font.family: Design.font
            font.pixelSize: root.big ? 16 : Design.body.size
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
