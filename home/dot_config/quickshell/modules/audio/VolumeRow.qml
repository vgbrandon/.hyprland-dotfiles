import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components.base
import qs.components.controls
import qs.components.design
import qs.services

// Volumen de un nodo: silenciar, deslizador y porcentaje
RowLayout {
    id: vrow
    property var node
    property string icon
    readonly property real level: node?.audio?.volume ?? 0
    readonly property bool muted: node?.audio?.muted ?? false

    Layout.fillWidth: true
    Layout.leftMargin: 2
    spacing: 10

    IconBtn {
        icon: vrow.icon
        checked: !vrow.muted
        iconColor: vrow.muted ? Design.error : Design.onTonal
        onClicked: Audio.toggleMute(vrow.node)
    }
    Slider {
        Layout.fillWidth: true
        value: vrow.level
        color: vrow.muted ? Design.muted : Design.accent
        onMoved: f => Audio.setVolume(vrow.node, f)
        WheelHandler {
            onWheel: e => Audio.setVolume(vrow.node, vrow.level + (e.angleDelta.y > 0 ? 0.01 : -0.01))
        }
    }
    Txt {
        Layout.preferredWidth: 38
        horizontalAlignment: Text.AlignRight
        text: Math.round(vrow.level * 100) + "%"
        textStyle: Design.label
        color: vrow.muted ? Design.muted : Design.onSurface
        font.features: { "tnum": 1 }
    }
}
