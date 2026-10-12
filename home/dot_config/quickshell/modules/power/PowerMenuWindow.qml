import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.containers
import qs.services

// Ventana del menú de energía (la lógica está en services/PowerMenu.qml)
//   quickshell ipc call power toggle
OverlayWindow {
    id: win

    open: PowerMenu.open
    onCloseRequested: PowerMenu.open = false
    namespace: "quickshell:power"
    dim: 0.5
    cardColor: Theme.surface

    // Se reinicia al cerrar para que al abrir ya esté listo
    onVisibleChanged: {
        if (visible) row.forceActiveFocus();
        else PowerMenu.selected = 0;
    }

    RowLayout {
        id: row
        spacing: 12

        Keys.onPressed: e => {
            const n = PowerMenu.actions.length;
            if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) {
                PowerMenu.selected = (PowerMenu.selected - 1 + n) % n;
            } else if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) {
                PowerMenu.selected = (PowerMenu.selected + 1) % n;
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
                PowerMenu.run(PowerMenu.selected);
            } else {
                // Atajo por letra (Esc y el resto pasan a la ventana)
                const i = PowerMenu.actions.findIndex(a => a.key === e.text.toUpperCase());
                if (i < 0) return;
                PowerMenu.run(i);
            }
            e.accepted = true;
        }

        Repeater {
            model: PowerMenu.actions

            Rectangle {
                id: button
                required property var modelData
                required property int index
                readonly property bool active: PowerMenu.selected === index

                implicitWidth: 128
                implicitHeight: 128
                radius: active ? Theme.radius * 2 : Theme.radius
                color: active ? Theme.primary : Theme.surfaceHigh
                Behavior on radius { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        text: button.modelData.icon
                        color: button.active ? Theme.primaryFg : Theme.text
                        font.pixelSize: 40
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: button.modelData.label
                        color: button.active ? Theme.primaryFg : Theme.text
                    }
                }

                // Letra del atajo
                Label {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 12
                    text: button.modelData.key
                    color: button.active ? Theme.primaryFg : Theme.subtext
                    font.pixelSize: Theme.fontSize
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: PowerMenu.selected = button.index
                    onClicked: PowerMenu.run(button.index)
                }
            }
        }
    }
}
