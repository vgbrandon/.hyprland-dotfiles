import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Icono de luz nocturna: clic = activar/desactivar y muestra el OSD.
// Con el ratón sobre el OSD (o el icono), la rueda cambia la intensidad si está activado.
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
            NightLight.scroll(e.angleDelta.y);
            osd.show();
        }
    }

    PopupWindow {
        id: osd

        // Ratón encima del OSD (incluido el botón de reinicio)
        readonly property bool hovering: osdHover.containsMouse || resetMouse.containsMouse

        function show() {
            visible = true;
            if (!hovering) hideTimer.restart();
        }

        onHoveringChanged: hovering ? hideTimer.stop() : hideTimer.restart()

        // Clic en cualquier otro lugar = cerrar al instante
        HyprlandFocusGrab {
            id: grab
            windows: [osd]
            onCleared: osd.visible = false
        }
        onVisibleChanged: {
            grab.active = false;
            if (visible) grabTimer.restart();
        }
        Timer {
            id: grabTimer
            interval: 50
            onTriggered: grab.active = osd.visible
        }

        anchor.item: root
        anchor.rect.x: root.width / 2 - width / 2
        anchor.rect.y: root.height + 14
        implicitWidth: 260
        implicitHeight: 56
        color: "transparent"

        // Se oculta 1.5 s después de que el ratón sale del OSD
        Timer {
            id: hideTimer
            interval: 1500
            onTriggered: osd.visible = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Theme.surface

            // Ratón encima: no se oculta y la rueda cambia la intensidad
            MouseArea {
                id: osdHover
                anchors.fill: parent
                hoverEnabled: true
                onWheel: e => NightLight.scroll(e.angleDelta.y)
            }

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

                // Volver a la intensidad por defecto
                Rectangle {
                    readonly property bool usable: NightLight.enabled && NightLight.temperature !== NightLight.defaultTemp

                    visible: NightLight.available
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    color: resetMouse.containsMouse && usable ? Theme.surfaceHigh : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        text: Theme.iRestore
                        color: parent.usable ? Theme.text : Theme.dot
                        font.pixelSize: 18
                    }
                    MouseArea {
                        id: resetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: parent.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: NightLight.reset()
                    }
                }
            }
        }
    }
}
