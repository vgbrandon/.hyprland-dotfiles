import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.services

// Razonamiento del modelo: plegado por defecto ("Pensando…" mientras llega, luego
// "Razonamiento"); clic = verlo entero.
//   Reasoning { part: p }
ColumnLayout {
    id: root

    required property var part
    property bool expanded: false

    spacing: 4

    // Cabecera: toda la fila es pulsable
    Item {
        Layout.fillWidth: true
        implicitHeight: header.implicitHeight

        RowLayout {
            id: header
            spacing: 6

            Icon {
                text: Theme.iBrain
                color: Theme.subtext
                font.pixelSize: 14
            }
            Label {
                id: thinking
                text: root.part.done ? "Razonamiento" : "Pensando…"
                color: Theme.subtext
                font.pixelSize: Theme.fontSize
                font.italic: true

                SequentialAnimation on opacity {
                    running: !root.part.done
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.4; duration: 700 }
                    NumberAnimation { to: 1; duration: 700 }
                    onRunningChanged: if (!running) thinking.opacity = 1
                }
            }
            Icon {
                text: root.expanded ? Theme.iChevronUp : Theme.iChevronDown
                color: Theme.subtext
                font.pixelSize: 14
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    TextEdit {
        visible: root.expanded
        Layout.fillWidth: true
        Layout.leftMargin: 20
        text: root.part.text.trim()
        readOnly: true
        selectByMouse: true
        wrapMode: TextEdit.Wrap
        color: Theme.subtext
        selectionColor: Theme.withAlpha(Theme.primary, 0.4)
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.italic: true
    }
}
