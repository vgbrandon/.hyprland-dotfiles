import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

import Quickshell.Wayland

// Centro de notificaciones: panel que entra desde la derecha del monitor enfocado
PanelWindow {
    id: panel

    // Se mantiene mapeado mientras dura la animación de salida
    visible: Notifs.centerOpen || slide.running
    screen: Quickshell.screens.find(s => Hyprland.monitorFor(s) === Hyprland.focusedMonitor) ?? Quickshell.screens[0]
    anchors {
        top: true
        bottom: true
        right: true
    }
    margins {
        top: Theme.barHeight + 8
        bottom: 8
        right: 8
    }
    implicitWidth: 420
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: Notifs.centerOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:notification-center"

    // Clic fuera = cerrar
    HyprlandFocusGrab {
        id: grab
        windows: [panel]
        onCleared: Notifs.closeCenter()
    }
    Connections {
        target: Notifs
        function onCenterOpenChanged() {
            grab.active = false;
            if (Notifs.centerOpen) grabTimer.restart();
        }
    }
    Timer {
        id: grabTimer
        interval: 50
        onTriggered: {
            grab.active = Notifs.centerOpen;
            keys.forceActiveFocus();
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: Notifs.closeCenter()
    }

    Rectangle {
        id: sheet
        width: parent.width
        height: parent.height
        radius: 24
        x: Notifs.centerOpen ? 0 : panel.implicitWidth + 16
        Behavior on x {
            NumberAnimation {
                id: slide
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        color: Theme.panelBg
        border.color: Theme.surfaceHigh
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Encabezado
            RowLayout {
                Layout.leftMargin: 6
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    text: "Notificaciones"
                    font.pixelSize: 16
                }

                // No molestar
                Rectangle {
                    implicitWidth: dndRow.implicitWidth + 20
                    implicitHeight: 30
                    radius: height / 2
                    color: Notifs.dnd ? Theme.primary : Theme.surfaceHigh

                    RowLayout {
                        id: dndRow
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            text: Theme.iBellOff
                            color: Notifs.dnd ? Theme.primaryFg : Theme.text
                            font.pixelSize: 14
                        }
                        Label {
                            text: "No molestar"
                            color: Notifs.dnd ? Theme.primaryFg : Theme.text
                            font.pixelSize: Theme.fontSize + 1
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }

                Rectangle {
                    visible: Notifs.count > 0
                    implicitWidth: clearLabel.implicitWidth + 20
                    implicitHeight: 30
                    radius: height / 2
                    color: clearMouse.containsMouse ? Theme.surfaceHigh : Theme.surface

                    Label {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Limpiar"
                        font.pixelSize: Theme.fontSize + 1
                    }
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.clearAll()
                    }
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
                            notif: modelData
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
    }
}
