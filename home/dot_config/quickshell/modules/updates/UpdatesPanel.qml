import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.buttons
import qs.components.containers
import qs.services

// Panel de actualizaciones: lista de paquetes y botón para actualizar
BarPopup {
    id: panel

    implicitWidth: 380
    maxHeight: 560

    PanelHeader {
        icon: Theme.iPacman
        title: Updates.total === 0 ? "Sistema al día" : `${Updates.total} actualizaciones`
        subtitle: Updates.upgrading ? "Actualizando…"
            : Updates.checking ? "Buscando…"
            : Updates.lastCheck.getTime() === 0 ? "" : "Revisado a las " + Qt.formatDateTime(Updates.lastCheck, "hh:mm")

        // Volver a buscar
        CircleButton {
            id: refreshButton
            icon: Theme.iRefresh
            iconSize: 18
            onClicked: Updates.check()

            RotationAnimation {
                target: refreshButton.iconItem
                from: 0
                to: 360
                duration: 1200
                loops: Animation.Infinite
                running: Updates.checking
                onRunningChanged: if (!running) refreshButton.iconItem.rotation = 0
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

            Packages {
                name: "Pacman"
                icon: Theme.iPacman
                packages: Updates.pacman
                iconColor: Updates.pacmanColor()
            }
            Packages {
                name: "AUR"
                icon: Theme.iGhost
                packages: Updates.aur
                iconColor: Updates.aurColor()
            }
        }
    }

    // Actualizar todo
    TextButton {
        visible: Updates.total > 0
        Layout.fillWidth: true
        accent: true
        enabled: !Updates.upgrading
        text: Updates.upgrading ? "Actualizando en la terminal…" : "Actualizar todo"
        onClicked: {
            Updates.upgrade();
            panel.close();
        }
    }

    // Lista de paquetes de un origen, con su cantidad en el título
    component Packages: Section {
        id: section
        required property var packages
        property string name
        title: `${name} (${packages.length})`

        visible: packages.length > 0
        Layout.topMargin: 4
        contentSpacing: 2

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
}
