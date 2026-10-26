import QtQuick
import QtQuick.Effects
import qs.services

// Control segmentado: hundido, con la opción elegida en vidrio elevado que se desliza
// con un poco de muelle
// follow = cambia solo al pulsar; con false solo avisa (current lo decide quien lo usa)
//   Segmented { options: ["Día", "Semana", "Mes"]; current: 0 }
Rectangle {
    id: root

    property var options: []
    property int current: 0
    property bool follow: true
    signal selected(int index)

    readonly property real segWidth: (width - 4) / Math.max(1, options.length)

    implicitWidth: 240
    implicitHeight: 32
    radius: Design.radiusSm
    color: Design.sunken
    border.color: Design.border
    border.width: 1

    Rectangle {
        x: 2 + root.current * root.segWidth
        y: 2
        width: root.segWidth
        height: root.height - 4
        radius: Design.radiusSm - 2
        color: Design.alpha("#ffffff", 0.14)
        Behavior on x { NumberAnimation { duration: Design.springDuration; easing.type: Design.spring; easing.overshoot: Design.overshoot } }
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.3
            shadowBlur: 0.3
            shadowVerticalOffset: 1
        }

        GlassEdge { inset: parent.radius }
    }
    Row {
        x: 2
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.options

            Item {
                required property string modelData
                required property int index
                width: root.segWidth
                height: root.height - 4

                Txt {
                    anchors.centerIn: parent
                    text: parent.modelData
                    textStyle: Design.label
                    color: parent.index === root.current ? Design.onSurface : Design.onSurfaceVariant
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.follow) root.current = parent.index;
                        root.selected(parent.index);
                    }
                }
            }
        }
    }
}
