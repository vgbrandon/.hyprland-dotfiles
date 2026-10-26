import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// Opción con interruptor, título y explicación
RowLayout {
    id: opt
    property string title
    property string subtitle
    property bool checked: false
    signal toggled()

    Layout.fillWidth: true
    spacing: 12
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Txt { Layout.fillWidth: true; text: opt.title }
        Txt {
            Layout.fillWidth: true
            visible: opt.subtitle !== ""
            text: opt.subtitle
            textStyle: Design.caption
            color: Design.onSurfaceVariant
            wrapMode: Text.Wrap
        }
    }
    Toggle {
        checked: opt.checked
        follow: false
        onToggled: opt.toggled()
    }
}
