import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// Una opción de varias (segmentado) con su nombre encima
ColumnLayout {
    id: seg
    property string label
    property var options: []
    property int current: 0
    signal picked(int index)

    Layout.fillWidth: true
    spacing: 6
    Txt { text: seg.label; textStyle: Design.label; color: Design.onSurfaceVariant }
    Segmented {
        Layout.fillWidth: true
        options: seg.options
        current: seg.current
        follow: false
        onSelected: i => seg.picked(i)
    }
}
