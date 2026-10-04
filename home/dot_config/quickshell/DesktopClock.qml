import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Reloj grande en el escritorio (debajo de las ventanas, encima del fondo)
PanelWindow {
    id: root

    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.barHeight + 70
        right: 70
    }
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell:clock"
    mask: Region {} // no captura clics

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        id: col
        spacing: -10

        Text {
            Layout.alignment: Qt.AlignRight
            text: Qt.formatDateTime(clock.date, "hh:mm")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 110
            font.weight: Font.Light
        }
        Text {
            Layout.alignment: Qt.AlignRight
            text: Qt.formatDateTime(clock.date, "dddd, dd/MM")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 26
        }
    }
}
