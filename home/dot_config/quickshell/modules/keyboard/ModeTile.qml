import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// Efecto de luces (en la cuadrícula): nombre y el seleccionado resaltado
Rectangle {
    id: tile
    property var mode
    readonly property bool picked: AulaKeyboard.light.mode === mode.id

    Layout.fillWidth: true
    implicitHeight: 40
    radius: Design.radiusSm
    color: picked ? Design.selection : tileMouse.containsMouse ? Design.hoverLayer : Design.alpha("#ffffff", 0.03)
    border.color: picked ? Design.selectionBorder : Design.border
    Behavior on color { ColorAnimation { duration: Design.fast } }

    Txt {
        anchors.centerIn: parent
        width: parent.width - 12
        horizontalAlignment: Text.AlignHCenter
        text: tile.mode.name
        textStyle: Design.label
        color: tile.picked ? Design.accent : Design.onSurface
        font.weight: tile.picked ? Font.DemiBold : Font.Medium
    }
    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AulaKeyboard.setLight({ mode: tile.mode.id })
    }
}
