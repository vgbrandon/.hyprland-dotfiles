import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.containers
import qs.services

// Centro de notificaciones: panel que entra desde la derecha del monitor principal
//   quickshell ipc call notifications toggle
SidePanel {
    open: Notifs.centerOpen
    onCloseRequested: Notifs.closeCenter()
    namespace: "quickshell:notification-center"

    // Encabezado
    PanelHeader {
        title: "Notificaciones"

        TextButton {
            icon: Theme.iBellOff
            text: "No molestar"
            small: true
            accent: Notifs.dnd
            onClicked: Notifs.dnd = !Notifs.dnd
        }
        TextButton {
            visible: Notifs.count > 0
            text: "Limpiar"
            small: true
            onClicked: Notifs.clearAll()
        }
    }

    // Lista (las más nuevas arriba)
    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: Notifs.count > 0
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: parent.width
            spacing: 8

            Repeater {
                model: ScriptModel {
                    values: Notifs.list.slice().reverse()
                }

                NotificationCard {
                    required property var modelData
                    entry: modelData
                    width: list.width
                }
            }
        }
    }

    // Vacío
    Item {
        visible: Notifs.count === 0
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6

            Icon {
                Layout.alignment: Qt.AlignHCenter
                text: Theme.iBellEmpty
                color: Theme.subtext
                font.pixelSize: 36
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "Sin notificaciones"
                color: Theme.subtext
            }
        }
    }
}
