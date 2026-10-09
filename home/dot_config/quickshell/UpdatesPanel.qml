import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Panel de actualizaciones: lista de paquetes y botón para actualizar
PopupWindow {
    id: panel

    required property Item anchorItem
    property real closedAt: 0

    // Abre/cierra desde la barra. Si el mismo clic acaba de cerrarlo, no lo reabre.
    function toggle() {
        if (!visible && Date.now() - closedAt < 300) return;
        visible = !visible;
    }

    anchor.item: anchorItem
    anchor.rect.x: popupPos.x
    anchor.rect.y: popupPos.y
    // Junto a la barra, esté donde esté
    readonly property point popupPos: Config.popupPos(anchorItem, implicitWidth, implicitHeight, visible)
    implicitWidth: 380
    implicitHeight: Math.min(560, layout.implicitHeight + 24)
    color: "transparent"

    // Clic fuera del panel = cerrar
    HyprlandFocusGrab {
        id: grab
        windows: [panel]
        onCleared: {
            panel.visible = false;
            panel.closedAt = Date.now();
        }
    }
    onVisibleChanged: {
        grab.active = false;
        if (visible) grabTimer.restart();
    }
    Timer {
        id: grabTimer
        interval: 50
        onTriggered: grab.active = panel.visible
    }

    component Section: ColumnLayout {
        id: section
        required property string title
        required property string icon
        required property var packages
        required property color tint

        visible: packages.length > 0
        spacing: 2

        RowLayout {
            Layout.leftMargin: 8
            Layout.topMargin: 4
            spacing: 6

            Icon {
                text: section.icon
                color: section.tint
                font.pixelSize: 14
            }
            Label {
                text: `${section.title} (${section.packages.length})`
                color: Theme.subtext
                font.pixelSize: Theme.fontSize
            }
        }

        Repeater {
            model: section.packages

            RowLayout {
                id: pkg
                required property var modelData

                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    text: pkg.modelData.name
                }
                Label {
                    Layout.maximumWidth: 190
                    text: `${pkg.modelData.from} → ${pkg.modelData.to}`
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
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
                spacing: 10

                Icon {
                    text: Theme.iPacman
                    font.pixelSize: 20
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Label {
                        text: Updates.total === 0 ? "Sistema al día" : `${Updates.total} actualizaciones`
                        font.pixelSize: 16
                    }
                    Label {
                        text: Updates.upgrading ? "Actualizando…"
                            : Updates.checking ? "Buscando…"
                            : Updates.lastCheck.getTime() === 0 ? "" : "Revisado a las " + Qt.formatDateTime(Updates.lastCheck, "hh:mm")
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize
                    }
                }

                // Volver a buscar
                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    color: refreshMouse.containsMouse ? Theme.surfaceHigh : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        text: Theme.iRefresh
                        font.pixelSize: 18
                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 1200
                            loops: Animation.Infinite
                            running: Updates.checking
                            onRunningChanged: if (!running) parent.rotation = 0
                        }
                    }
                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Updates.check()
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: lists.implicitHeight
                visible: Updates.total > 0
                contentHeight: lists.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: lists
                    width: parent.width
                    spacing: 8

                    Section {
                        Layout.fillWidth: true
                        title: "Pacman"
                        icon: Theme.iPacman
                        packages: Updates.pacman
                        tint: Updates.pacmanColor()
                    }
                    Section {
                        Layout.fillWidth: true
                        title: "AUR"
                        icon: Theme.iGhost
                        packages: Updates.aur
                        tint: Updates.aurColor()
                    }
                }
            }

            // Actualizar todo
            Rectangle {
                visible: Updates.total > 0
                Layout.fillWidth: true
                implicitHeight: 40
                radius: height / 2
                color: Updates.upgrading ? Theme.surfaceHigh : upgradeMouse.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary

                Label {
                    anchors.centerIn: parent
                    text: Updates.upgrading ? "Actualizando en la terminal…" : "Actualizar todo"
                    color: Updates.upgrading ? Theme.subtext : Theme.primaryFg
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: upgradeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Updates.upgrading ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        Updates.upgrade();
                        panel.visible = false;
                    }
                }
            }
        }
    }
}
