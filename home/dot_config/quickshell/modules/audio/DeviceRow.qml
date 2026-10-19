import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components.base
import qs.components.controls
import qs.components.design
import qs.services

// Un dispositivo: el que se usa va en tonal con una marca; clic = usarlo
Rectangle {
    id: drow
    property var node
    readonly property bool active: node === (node?.isSink ? Audio.sink : Audio.source)
    readonly property string detail: Audio.detailOf(node)

    Layout.fillWidth: true
    implicitHeight: detail !== "" ? 44 : 36
    radius: Design.radiusSm
    color: active ? Design.tonal : "transparent"

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: dmouse.containsMouse && !drow.active ? Design.hoverLayer : "transparent"
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        Icon {
            text: Audio.iconOf(drow.node)
            color: drow.active ? Design.onTonal : Design.onSurfaceVariant
            font.pixelSize: 16
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Txt {
                Layout.fillWidth: true
                text: Audio.nameOf(drow.node)
                color: drow.active ? Design.onTonal : Design.onSurface
            }
            Txt {
                Layout.fillWidth: true
                visible: drow.detail !== ""
                text: drow.detail
                textStyle: Design.caption
                color: drow.active ? Design.alpha(Design.onTonal, 0.75) : Design.onSurfaceVariant
            }
        }
        Icon {
            visible: drow.active
            text: Theme.iCheck
            color: Design.onTonal
            font.pixelSize: 16
        }
    }
    MouseArea {
        id: dmouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: drow.active ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: Audio.setDefault(drow.node)
    }
}
