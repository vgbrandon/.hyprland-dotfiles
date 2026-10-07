import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Botón de grabación de la barra. Sin grabar: icono de video (clic = menú).
// Grabando: punto rojo con el tiempo (clic = detener).
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Icon {
            visible: !Recorder.recording
            text: Theme.iVideo
        }
        Rectangle {
            visible: Recorder.recording
            implicitWidth: 10
            implicitHeight: 10
            radius: 5
            color: Theme.error

            SequentialAnimation on opacity {
                running: Recorder.recording
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }
        Label {
            visible: Recorder.recording
            text: Recorder.timeText()
            color: Theme.error
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Recorder.recording ? Recorder.stop() : menu.toggle()
    }

    // Menú: qué grabar y con qué audio
    PopupWindow {
        id: menu

        property real closedAt: 0

        function toggle() {
            if (!visible && Date.now() - closedAt < 300) return;
            visible = !visible;
        }

        anchor.item: root
        anchor.rect.x: root.width / 2 - width / 2
        anchor.rect.y: root.height + 14
        implicitWidth: 280
        implicitHeight: menuLayout.implicitHeight + 24
        color: "transparent"

        HyprlandFocusGrab {
            id: grab
            windows: [menu]
            onCleared: {
                menu.visible = false;
                menu.closedAt = Date.now();
            }
        }
        onVisibleChanged: {
            grab.active = false;
            if (visible) grabTimer.restart();
        }
        Timer {
            id: grabTimer
            interval: 50
            onTriggered: grab.active = menu.visible
        }

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: Theme.panelBg
            border.color: Theme.surfaceHigh
            border.width: 1

            ColumnLayout {
                id: menuLayout
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Label {
                    Layout.leftMargin: 6
                    text: "Grabar pantalla"
                    font.pixelSize: 16
                }

                // Qué grabar
                RowLayout {
                    spacing: 8

                    Repeater {
                        model: [
                            { label: "Pantalla", icon: Theme.iMonitor, region: false },
                            { label: "Región", icon: Theme.iRegion, region: true }
                        ]

                        Rectangle {
                            id: opt
                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: 70
                            radius: 18
                            color: optMouse.containsMouse ? Theme.primary : Theme.surfaceHigh

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: opt.modelData.icon
                                    color: optMouse.containsMouse ? Theme.primaryFg : Theme.text
                                    font.pixelSize: 22
                                }
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: opt.modelData.label
                                    color: optMouse.containsMouse ? Theme.primaryFg : Theme.text
                                }
                            }
                            MouseArea {
                                id: optMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    menu.visible = false;
                                    // Un momento para que el menú desaparezca antes de grabar
                                    startTimer.region = opt.modelData.region;
                                    startTimer.restart();
                                }
                            }
                        }
                    }
                }

                Timer {
                    id: startTimer
                    property bool region: false
                    interval: 150
                    onTriggered: region ? Recorder.recordRegion() : Recorder.recordScreen()
                }

                // Audio
                Repeater {
                    model: [
                        { label: "Audio del sistema", icon: Theme.iVolume, key: "systemAudio" },
                        { label: "Micrófono", icon: Theme.iMic, key: "microphone" }
                    ]

                    RowLayout {
                        id: audioRow
                        required property var modelData

                        Layout.leftMargin: 6
                        Layout.rightMargin: 4
                        spacing: 10

                        Icon {
                            text: audioRow.modelData.icon
                            color: Theme.subtext
                        }
                        Label {
                            Layout.fillWidth: true
                            text: audioRow.modelData.label
                        }
                        Switch {
                            checked: Recorder[audioRow.modelData.key]
                            onToggled: Recorder[audioRow.modelData.key] = !Recorder[audioRow.modelData.key]
                        }
                    }
                }
            }
        }
    }
}
