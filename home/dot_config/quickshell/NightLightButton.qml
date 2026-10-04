import QtQuick
import QtQuick.Layouts
import Quickshell

// Icono de luz nocturna: clic = activar/desactivar, rueda = temperatura (con OSD)
Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Icon {
        id: icon
        text: NightLight.enabled ? Theme.iNight : Theme.iSun
        color: !NightLight.available ? Theme.dot : NightLight.enabled ? Theme.warm : Theme.text
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            NightLight.toggle();
            osd.show();
        }
        onWheel: e => {
            NightLight.setTemperature(NightLight.temperature + (e.angleDelta.y > 0 ? -100 : 100));
            osd.show();
        }
    }

    PopupWindow {
        id: osd

        function show() {
            visible = true;
            hideTimer.restart();
        }

        anchor.item: root
        anchor.rect.x: root.width / 2 - width / 2
        anchor.rect.y: root.height + 14
        implicitWidth: 220
        implicitHeight: 56
        color: "transparent"

        Timer {
            id: hideTimer
            interval: 1500
            onTriggered: osd.visible = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Theme.surface

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Icon {
                    text: NightLight.enabled ? Theme.iNight : Theme.iSun
                    color: NightLight.enabled ? Theme.warm : Theme.text
                    font.pixelSize: 22
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Label {
                            Layout.fillWidth: true
                            text: NightLight.available ? "Luz nocturna" : "Instala hyprsunset"
                        }
                        Label {
                            visible: NightLight.available
                            text: NightLight.enabled ? `${NightLight.temperature}K` : "Off"
                            color: Theme.subtext
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 4
                        radius: 2
                        color: Theme.surfaceHigh

                        Rectangle {
                            width: parent.width * (NightLight.enabled ? NightLight.strength : 0)
                            height: parent.height
                            radius: 2
                            color: Theme.warm
                            Behavior on width { NumberAnimation { duration: 150 } }
                        }
                    }
                }
            }
        }
    }
}
