import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Wayland

// Panel de ajustes rápidos: ocupa todo el alto disponible y
// entra desde la derecha del monitor enfocado (como el centro
// de notificaciones).
PanelWindow {
    id: panel

    // Se mantiene mapeado mientras dura la animación de salida
    visible: Config.open || slide.running
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
    implicitWidth: 400
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: Config.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:config-panel"

    // Clic fuera = cerrar
    HyprlandFocusGrab {
        id: grab
        windows: [panel]
        onCleared: Config.close()
    }
    Connections {
        target: Config
        function onOpenChanged() {
            grab.active = false;
            if (Config.open) grabTimer.restart();
        }
    }
    Timer {
        id: grabTimer
        interval: 50
        onTriggered: {
            grab.active = Config.open;
            keys.forceActiveFocus();
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: Config.close()
    }

    HyprOption { id: animations; option: "animations:enabled" }
    HyprOption { id: blur; option: "decoration:blur:enabled" }
    HyprOption { id: shadows; option: "decoration:shadow:enabled" }
    HyprOption { id: gapsIn; option: "general:gaps_in"; max: 20; fallback: 5 }
    HyprOption { id: gapsOut; option: "general:gaps_out"; max: 30; fallback: 10 }

    readonly property BluetoothAdapter bt: Bluetooth.defaultAdapter

    // Suspende el equipo
    Process {
        id: suspendProc
        command: ["systemctl", "suspend"]
    }

    Rectangle {
        id: sheet
        width: parent.width
        height: parent.height
        radius: 24
        x: Config.open ? 0 : panel.implicitWidth + 16
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

            Label {
                Layout.leftMargin: 6
                text: "Configuración"
                font.pixelSize: 16
            }

            // --- Dispositivos ---
            Label {
                Layout.leftMargin: 6
                text: "Dispositivos"
                color: Theme.subtext
                font.pixelSize: Theme.fontSize
            }

            RowLayout {
                Layout.leftMargin: 6
                Layout.rightMargin: 4
                spacing: 10

                Icon {
                    text: Networking.wifiEnabled ? Theme.iWifi : Theme.iWifiOff
                    color: Theme.subtext
                }
                Label {
                    Layout.fillWidth: true
                    text: "Red inalámbrica"
                }
                Switch {
                    checked: Networking.wifiEnabled
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            RowLayout {
                Layout.leftMargin: 6
                Layout.rightMargin: 4
                spacing: 10

                Icon {
                    text: panel.bt?.enabled ? Theme.iBtOn : Theme.iBt
                    color: Theme.subtext
                }
                Label {
                    Layout.fillWidth: true
                    text: "Bluetooth"
                }
                Switch {
                    checked: panel.bt?.enabled ?? false
                    onToggled: if (panel.bt) panel.bt.enabled = !panel.bt.enabled
                }
            }

            RowLayout {
                Layout.leftMargin: 6
                Layout.rightMargin: 4
                spacing: 10

                Icon {
                    text: Notifs.dnd ? Theme.iBellOff : Theme.iBell
                    color: Theme.subtext
                }
                Label {
                    Layout.fillWidth: true
                    text: "No molestar"
                }
                Switch {
                    checked: Notifs.dnd
                    onToggled: Notifs.dnd = !Notifs.dnd
                }
            }

            RowLayout {
                Layout.leftMargin: 6
                Layout.rightMargin: 4
                spacing: 10

                Icon {
                    text: NightLight.enabled ? Theme.iNight : Theme.iSun
                    color: Theme.subtext
                }
                Label {
                    Layout.fillWidth: true
                    text: "Luz nocturna"
                }
                Switch {
                    checked: NightLight.available && NightLight.enabled
                    onToggled: NightLight.toggle()
                }
            }

            // --- Apariencia ---
            Label {
                Layout.leftMargin: 6
                text: "Apariencia"
                color: Theme.subtext
                font.pixelSize: Theme.fontSize
            }

            RowLayout {
                Layout.leftMargin: 6
                Layout.rightMargin: 4
                spacing: 10

                Icon {
                    text: Theme.iAnimation
                    color: Theme.subtext
                }
                Label {
                    Layout.fillWidth: true
                    text: "Animaciones"
                }
                Switch {
                    checked: animations.boolValue
                    onToggled: animations.set(!animations.boolValue)
                }
            }

            RowLayout {
                Layout.leftMargin: 6
                Layout.rightMargin: 4
                spacing: 10

                Icon {
                    text: Theme.iBlur
                    color: Theme.subtext
                }
                Label {
                    Layout.fillWidth: true
                    text: "Desenfoque"
                }
                Switch {
                    checked: blur.boolValue
                    onToggled: blur.set(!blur.boolValue)
                }
            }

            RowLayout {
                Layout.leftMargin: 6
                Layout.rightMargin: 4
                spacing: 10

                Icon {
                    text: Theme.iShadow
                    color: Theme.subtext
                }
                Label {
                    Layout.fillWidth: true
                    text: "Sombras"
                }
                Switch {
                    checked: shadows.boolValue
                    onToggled: shadows.set(!shadows.boolValue)
                }
            }

            // --- Bordes ---
            // Un slider por cada borde: clic o arrastre para fijar
            // el tamaño, y reset al valor por defecto si cambió.
            RowLayout {
                Layout.leftMargin: 6
                Layout.rightMargin: 4
                spacing: 10

                Icon {
                    text: Theme.iGaps
                    color: Theme.subtext
                }
                Label {
                    text: "Interiores"
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: Theme.surfaceHigh

                    Rectangle {
                        width: parent.width * (gapsIn.intValue / gapsIn.max)
                        height: parent.height
                        radius: 2
                        color: Theme.primary
                        Behavior on width { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: e => gapsIn.set(e.x / width * gapsIn.max)
                        onPositionChanged: e => {
                            if (pressed) gapsIn.set(e.x / width * gapsIn.max)
                        }
                    }
                }

                Label {
                    text: gapsIn.intValue
                    color: Theme.subtext
                    Layout.preferredWidth: 26
                }

                Rectangle {
                    visible: gapsIn.intValue !== gapsIn.fallback
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: resetMouseIn.containsMouse ? Theme.surfaceHigh : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        text: Theme.iRestore
                        color: Theme.text
                        font.pixelSize: 16
                    }
                    MouseArea {
                        id: resetMouseIn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: gapsIn.set(gapsIn.fallback)
                    }
                }
            }

            RowLayout {
                Layout.leftMargin: 6
                Layout.rightMargin: 4
                spacing: 10

                Icon {
                    text: Theme.iGaps
                    color: Theme.subtext
                }
                Label {
                    text: "Exteriores"
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: Theme.surfaceHigh

                    Rectangle {
                        width: parent.width * (gapsOut.intValue / gapsOut.max)
                        height: parent.height
                        radius: 2
                        color: Theme.primary
                        Behavior on width { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: e => gapsOut.set(e.x / width * gapsOut.max)
                        onPositionChanged: e => {
                            if (pressed) gapsOut.set(e.x / width * gapsOut.max)
                        }
                    }
                }

                Label {
                    text: gapsOut.intValue
                    color: Theme.subtext
                    Layout.preferredWidth: 26
                }

                Rectangle {
                    visible: gapsOut.intValue !== gapsOut.fallback
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: resetMouseOut.containsMouse ? Theme.surfaceHigh : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        text: Theme.iRestore
                        color: Theme.text
                        font.pixelSize: 16
                    }
                    MouseArea {
                        id: resetMouseOut
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: gapsOut.set(gapsOut.fallback)
                    }
                }
            }

            // Espacio para que las acciones queden al pie del panel
            Item { Layout.fillHeight: true }

            // --- Acciones ---
            RowLayout {
                spacing: 8

                Repeater {
                    model: [
                        { label: "Bloquear", icon: Theme.iLock, run: () => Lock.lock() },
                        { label: "Suspender", icon: Theme.iSleep, run: () => suspendProc.running = true }
                    ]

                    Rectangle {
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: 44
                        radius: 14
                        color: actMouse.containsMouse ? Theme.surfaceHigh : Theme.surface

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Icon {
                                text: modelData.icon
                                font.pixelSize: 18
                            }
                            Label {
                                text: modelData.label
                            }
                        }

                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.close();
                                modelData.run();
                            }
                        }
                    }
                }
            }
        }
    }
}
