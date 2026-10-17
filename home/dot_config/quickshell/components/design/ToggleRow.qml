import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.services

// Fila de ajuste: icono (opcional), texto y un interruptor. checked lo decide quien
// la usa (el interruptor no cambia solo).
//   ToggleRow { text: "Sonido"; checked: …; onToggled: … }
RowLayout {
    id: root

    property string icon
    property string text
    property bool checked: false
    signal toggled()

    Layout.fillWidth: true
    spacing: 10

    Icon {
        visible: root.icon !== ""
        text: root.icon
        color: Design.onSurfaceVariant
    }
    Txt {
        Layout.fillWidth: true
        text: root.text
    }
    Toggle {
        checked: root.checked
        follow: false
        onToggled: root.toggled()
    }
}
