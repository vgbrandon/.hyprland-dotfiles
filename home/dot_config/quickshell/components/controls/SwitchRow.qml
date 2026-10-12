import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.services

// Fila de ajuste: icono (opcional), texto y un interruptor
//   SwitchRow { icon: Theme.iBlur; text: "Desenfoque"; checked: …; onToggled: … }
RowLayout {
    id: root

    property string icon
    property string text
    property bool checked: false
    signal toggled()

    Layout.fillWidth: true
    Layout.leftMargin: 6
    Layout.rightMargin: 4
    spacing: 10

    Icon {
        visible: root.icon !== ""
        text: root.icon
        color: Theme.subtext
    }
    Label {
        Layout.fillWidth: true
        text: root.text
    }
    Switch {
        checked: root.checked
        onToggled: root.toggled()
    }
}
