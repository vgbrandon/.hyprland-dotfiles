import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// Nombre y valor (dispositivo)
RowLayout {
    id: info
    property string label
    property string value
    property bool mono: false
    property color valueColor: Design.onSurface

    Layout.fillWidth: true
    spacing: 12
    Txt {
        Layout.preferredWidth: 90
        text: info.label
        color: Design.onSurfaceVariant
    }
    Txt {
        Layout.fillWidth: true
        text: info.value
        color: info.valueColor
        font.family: info.mono ? Design.monoFont : Design.font
    }
}
