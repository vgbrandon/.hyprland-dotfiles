import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.components.buttons
import qs.services

// Valor con flechas a los lados (‹ 1920 × 1080 ›) y una etiqueta encima.
// step(-1) con la flecha izquierda, step(1) con la derecha.
ColumnLayout {
    id: cycler

    property string label
    property string text
    signal step(int d)

    spacing: 4

    Label {
        Layout.leftMargin: 4
        text: cycler.label
        color: Design.onSurfaceVariant
        font.pixelSize: Design.caption.size
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 36
        radius: Design.radiusSm
        color: Design.surface2
        border.color: Design.border
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6

            CircleButton {
                icon: Theme.iChevronLeft
                size: 28
                iconColor: Theme.subtext
                onClicked: cycler.step(-1)
            }
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: cycler.text
            }
            CircleButton {
                icon: Theme.iChevronRight
                size: 28
                iconColor: Theme.subtext
                onClicked: cycler.step(1)
            }
        }
    }
}
