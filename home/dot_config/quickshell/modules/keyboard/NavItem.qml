import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// Elemento de la barra lateral
Rectangle {
    id: nav
    property string icon
    property string text
    property bool selected: false
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 40
    radius: Design.radiusSm
    color: selected ? Design.selection : navMouse.containsMouse ? Design.hoverLayer : "transparent"
    border.color: selected ? Design.selectionBorder : "transparent"
    Behavior on color { ColorAnimation { duration: Design.fast } }

    // Marca de la sección actual
    Rectangle {
        visible: nav.selected
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 18
        radius: 1.5
        color: Design.accent
        AccentFill { glow: true }
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        spacing: 12
        Icon {
            text: nav.icon
            color: nav.selected ? Design.accent : Design.onSurfaceVariant
            font.pixelSize: 17
        }
        Txt {
            Layout.fillWidth: true
            text: nav.text
            textStyle: Design.label
            font.weight: nav.selected ? Font.DemiBold : Font.Medium
        }
    }
    MouseArea {
        id: navMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: nav.clicked()
    }
}
