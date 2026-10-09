pragma Singleton

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// Menú de energía. Se abre con: quickshell ipc call power toggle
Singleton {
    id: root

    property bool open: false
    property int selected: 0

    readonly property var actions: [
        { label: "Bloquear", key: "B", icon: Theme.iLock, run: () => Lock.lock() },
        { label: "Suspender", key: "S", icon: Theme.iSleep, run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { label: "Cerrar sesión", key: "C", icon: Theme.iLogout, run: () => Hyprland.dispatch(Hyprland.usingLua === false ? "exit" : "hl.dsp.exit()") },
        { label: "Reiniciar", key: "R", icon: Theme.iReboot, run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { label: "Apagar", key: "A", icon: Theme.iPower, run: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
    ]

    function toggle() {
        open = !open;
    }

    property int pending: -1

    // Cierra primero y ejecuta después, para que el compositor alcance a
    // redibujar sin el panel (si no, se ve un instante al volver de suspender)
    function run(i) {
        open = false;
        pending = i;
        runTimer.restart();
    }

    Timer {
        id: runTimer
        interval: 300
        onTriggered: {
            root.actions[root.pending].run();
            root.pending = -1;
        }
    }

    IpcHandler {
        target: "power"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }

    PanelWindow {
        visible: root.open
        screen: Quickshell.screens.find(s => Hyprland.monitorFor(s) === Hyprland.focusedMonitor) ?? Quickshell.screens[0]
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: Qt.rgba(0, 0, 0, 0.5)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:power"

        // Se reinicia al cerrar para que al abrir ya esté listo
        onVisibleChanged: {
            if (visible) keys.forceActiveFocus();
            else root.selected = 0;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true

            Keys.onPressed: e => {
                const n = root.actions.length;
                if (e.key === Qt.Key_Escape) {
                    root.open = false;
                } else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) {
                    root.selected = (root.selected - 1 + n) % n;
                } else if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) {
                    root.selected = (root.selected + 1) % n;
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
                    root.run(root.selected);
                } else {
                    // Atajo por letra
                    const i = root.actions.findIndex(a => a.key === e.text.toUpperCase());
                    if (i < 0) return;
                    root.run(i);
                }
                e.accepted = true;
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: row.implicitWidth + 32
            height: row.implicitHeight + 32
            radius: Theme.radius
            color: Theme.surface
            border.color: Theme.surfaceHigh
            border.width: 1

            opacity: root.open ? 1 : 0
            scale: root.open ? 1 : 0.96
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            MouseArea {
                anchors.fill: parent // evita que el clic llegue al fondo
            }

            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: 12

                Repeater {
                    model: root.actions

                    Rectangle {
                        id: button
                        required property var modelData
                        required property int index
                        readonly property bool active: root.selected === index

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
                            onEntered: root.selected = button.index
                            onClicked: root.run(button.index)
                        }
                    }
                }
            }
        }
    }
}
