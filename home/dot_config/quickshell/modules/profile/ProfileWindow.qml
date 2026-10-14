import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components.base
import qs.components.buttons
import qs.components.containers
import qs.services

// Ventana del perfil (clic en la tarjeta del panel de ajustes): foto, nombre que se
// muestra, datos de la cuenta y acciones. La foto se elige entre las imágenes de
// ~/Pictures (las mismas del selector de fondos). Lógica en services/Profile.qml.
OverlayWindow {
    id: win

    // Elegir foto (la cuadrícula de imágenes)
    property bool picking: false

    open: Profile.open
    onCloseRequested: Profile.open = false
    namespace: "quickshell:profile"
    cardWidth: 460
    spacing: 14
    onOpenChanged: {
        picking = false;
        nameInput.text = Profile.name;
    }

    // --- Foto y nombre (centrados) ---
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 6
        implicitHeight: header.implicitHeight

        ColumnLayout {
            id: header

            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            // Foto: clic = elegir otra
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 104
                implicitHeight: 104

                Avatar {
                    anchors.fill: parent
                    size: 104
                    source: Profile.avatarUrl
                    initial: Profile.initial
                    opacity: Profile.working ? 0.5 : 1
                }
                // Insignia de cámara

                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 32
                    height: 32
                    radius: 16
                    color: photoMouse.containsMouse || win.picking ? Theme.primary : Theme.surfaceHigh
                    border.color: Theme.panelBg
                    border.width: 3

                    Icon {
                        anchors.centerIn: parent
                        text: Theme.iCamera
                        color: photoMouse.containsMouse || win.picking ? Theme.primaryFg : Theme.text
                        font.pixelSize: 14
                    }

                }

                MouseArea {
                    id: photoMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.picking = !win.picking
                }

            }

            // Nombre que se muestra (Enter guarda)
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Math.max(160, nameInput.contentWidth + 40)
                implicitHeight: 34

                TextInput {
                    id: nameInput

                    function commit() {
                        if (text.trim() === "")
                            text = Profile.name;
                        else
                            Profile.setName(text);
                    }

                    anchors.centerIn: parent
                    width: parent.width - 40
                    horizontalAlignment: TextInput.AlignHCenter
                    color: Theme.text
                    selectionColor: Theme.withAlpha(Theme.primary, 0.4)
                    font.family: Theme.font
                    font.pixelSize: 22
                    maximumLength: 40
                    Keys.onReturnPressed: {
                        commit();
                        focus = false;
                    }
                    Keys.onEnterPressed: {
                        commit();
                        focus = false;
                    }
                    onActiveFocusChanged: {
                        if (!activeFocus) {
                            commit();
                        }
                    }
                }
                // Lápiz justo a la derecha del texto (centrado)

                Icon {
                    anchors.left: parent.horizontalCenter
                    anchors.leftMargin: nameInput.contentWidth / 2 + 8
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !nameInput.activeFocus
                    text: Theme.iPencil
                    color: Theme.subtext
                    font.pixelSize: 14
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: nameInput.contentWidth + 16
                    height: 2
                    radius: 1
                    color: Theme.primary
                    visible: nameInput.activeFocus
                }

            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: `${Profile.user}@${Profile.host}`
                color: Theme.subtext
                font.pixelSize: Theme.fontSize + 1
            }

        }

    }

    // --- Elegir foto ---
    ColumnLayout {
        visible: win.picking
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.leftMargin: 4

            Label {
                Layout.fillWidth: true
                text: "Elige una imagen de ~/Pictures"
                color: Theme.subtext
                font.pixelSize: Theme.fontSize
            }

            TextButton {
                visible: Profile.hasAvatar
                small: true
                flat: true
                icon: Theme.iDelete
                text: "Quitar foto"
                onClicked: {
                    Profile.removeAvatar();
                    win.picking = false;
                }
            }

        }

        GridView {
            id: grid

            Layout.fillWidth: true
            implicitHeight: Math.min(3, Math.ceil(count / 5)) * cellHeight
            clip: true
            cellWidth: width / 5
            cellHeight: cellWidth
            model: Wallpaper.files
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: cell

                required property string modelData

                width: grid.cellWidth
                height: grid.cellHeight

                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: width / 2
                    color: Theme.surface
                    border.color: cellMouse.containsMouse ? Theme.primary : "transparent"
                    border.width: 2

                    Image {
                        anchors.fill: parent
                        source: "file://" + (Wallpaper.thumbs[cell.modelData] ?? cell.modelData)
                        sourceSize.width: 160
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                }

                MouseArea {
                    id: cellMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Profile.setAvatar(cell.modelData);
                        win.picking = false;
                    }
                }

            }

        }

    }

    // --- Datos de la cuenta ---
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: info.implicitHeight + 20
        radius: Theme.radiusSmall
        color: Theme.surface

        ColumnLayout {
            id: info

            anchors.fill: parent
            anchors.margins: 10
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 8

            Repeater {
                model: [{
                    "icon": Theme.iMonitor,
                    "label": "Equipo",
                    "value": Profile.host
                }, {
                    "icon": Theme.iConsole,
                    "label": "Usuario",
                    "value": Profile.user
                }, {
                    "icon": Theme.iRefresh,
                    "label": "Encendido hace",
                    "value": Profile.uptimeText
                }]

                RowLayout {
                    required property var modelData

                    spacing: 10

                    Icon {
                        text: modelData.icon
                        color: Theme.subtext
                        font.pixelSize: 15
                    }

                    Label {
                        Layout.fillWidth: true
                        text: modelData.label
                        color: Theme.subtext
                    }

                    Label {
                        text: modelData.value
                    }

                }

            }

        }

    }

    // --- Acciones ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        TextButton {
            Layout.fillWidth: true
            icon: Theme.iLock
            text: "Cambiar contraseña"
            onClicked: Profile.changePassword()
        }

        TextButton {
            Layout.fillWidth: true
            icon: Theme.iPower
            text: "Energía"
            onClicked: {
                Profile.open = false;
                PowerMenu.toggle();
            }
        }

    }

}
