import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components.base
import qs.components.controls
import qs.components.design
import qs.services

// Una app que suena: icono, nombre y su volumen
ColumnLayout {
    id: arow
    property var node
    readonly property real level: node?.audio?.volume ?? 0
    readonly property bool muted: node?.audio?.muted ?? false

    Layout.fillWidth: true
    spacing: 2

    RowLayout {
        Layout.leftMargin: 4
        spacing: 8
        IconImage {
            implicitSize: 18
            source: Quickshell.iconPath(Audio.appIconOf(arow.node), true) || Quickshell.iconPath("audio-x-generic", true)
        }
        Txt {
            Layout.fillWidth: true
            text: Audio.appOf(arow.node)
            textStyle: Design.label
        }
    }
    VolumeRow {
        node: arow.node
        icon: arow.muted ? Theme.iMuted : Theme.iVolume
    }
}
