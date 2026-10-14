import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.buttons
import qs.components.containers
import qs.services

// Panel de GitHub (icono de la barra): la cuenta con la que están gh y git, otras
// cuentas guardadas, añadir una (código de dispositivo) y cerrar sesión. Lógica en
// services/GitHub.qml. Al abrir GitHub en el navegador el panel se cierra, pero el
// inicio de sesión sigue esperando: al volver a abrirlo, el código sigue ahí.
BarPopup {
    id: win

    implicitWidth: 400
    padding: 14
    spacing: 12

    // Cerrar sesión pide un segundo clic
    property string confirmLogout: ""
    onVisibleChanged: {
        confirmLogout = "";
        if (visible) {
            GitHub.resetWindow();
            GitHub.refresh();
        }
    }

    // --- Cabecera ---
    RowLayout {
        Layout.leftMargin: 4
        spacing: 10

        Icon {
            text: Theme.iGithub
            font.pixelSize: 22
        }
        Label {
            Layout.fillWidth: true
            text: "GitHub"
            font.pixelSize: 16
        }
        CircleButton {
            icon: Theme.iRefresh
            visible: GitHub.loggedIn && !GitHub.loggingIn
            onClicked: GitHub.refresh()
        }
    }

    // --- Sin gh ---
    Label {
        visible: !GitHub.available
        Layout.fillWidth: true
        text: "Falta instalar GitHub CLI (paquete github-cli)."
        wrapMode: Text.Wrap
        color: Theme.subtext
    }

    // --- Cuenta activa ---
    Rectangle {
        visible: GitHub.loggedIn && !GitHub.loggingIn
        Layout.fillWidth: true
        implicitHeight: account.implicitHeight + 28
        radius: Theme.radiusSmall
        color: Theme.surface

        ColumnLayout {
            id: account
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            RowLayout {
                spacing: 14

                Avatar {
                    size: 64
                    source: GitHub.user?.avatar_url ?? ""
                    initial: (GitHub.active?.login ?? "?").charAt(0).toUpperCase()
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Label {
                        Layout.fillWidth: true
                        text: GitHub.user?.name || GitHub.active?.login || ""
                        font.pixelSize: 17
                    }
                    Label {
                        Layout.fillWidth: true
                        text: "@" + (GitHub.active?.login ?? "")
                        color: Theme.subtext
                    }
                    Label {
                        visible: (GitHub.user?.bio ?? "") !== ""
                        Layout.fillWidth: true
                        text: GitHub.user?.bio ?? ""
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize
                    }
                }
            }

            // Repositorios, seguidores y seguidos
            RowLayout {
                spacing: 8

                Repeater {
                    model: [
                        { label: "Repositorios", value: GitHub.user?.public_repos },
                        { label: "Seguidores", value: GitHub.user?.followers },
                        { label: "Siguiendo", value: GitHub.user?.following }
                    ]

                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 52
                        radius: Theme.radiusSmall
                        color: Theme.panelBg

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0
                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.value ?? "–"
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                            }
                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                color: Theme.subtext
                                font.pixelSize: Theme.fontSize - 1
                            }
                        }
                    }
                }
            }

            // Permisos del token
            RowLayout {
                spacing: 8
                Icon {
                    text: Theme.iShield
                    color: Theme.subtext
                    font.pixelSize: 14
                }
                Label {
                    Layout.fillWidth: true
                    text: "Permisos: " + (GitHub.active?.scopes ?? "")
                    elide: Text.ElideRight
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }

    // --- Actividad del último año y detalle de un día ---
    Activity {
        visible: GitHub.loggedIn && !GitHub.loggingIn
        Layout.fillWidth: true
    }

    // --- Otras cuentas guardadas (clic = usar esa) ---
    ColumnLayout {
        visible: GitHub.accounts.length > 1 && !GitHub.loggingIn
        Layout.fillWidth: true
        spacing: 4

        Label {
            Layout.leftMargin: 4
            text: "Otras cuentas"
            color: Theme.subtext
            font.pixelSize: Theme.fontSize
        }
        Repeater {
            model: GitHub.accounts.filter(a => !a.active)

            Rectangle {
                id: other
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Theme.radiusSmall
                color: otherMouse.containsMouse ? Theme.surfaceHigh : Theme.surface

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10
                    Icon {
                        text: Theme.iGithub
                        color: Theme.subtext
                    }
                    Label {
                        Layout.fillWidth: true
                        text: "@" + other.modelData.login
                    }
                    Label {
                        text: "Usar esta"
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize
                    }
                }
                MouseArea {
                    id: otherMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: GitHub.switchTo(other.modelData.login)
                }
            }
        }
    }

    // --- Iniciar sesión ---
    ColumnLayout {
        // Mientras se comprueba la sesión por primera vez no se ofrece iniciarla
        visible: GitHub.available && (GitHub.loggingIn || (!GitHub.loggedIn && !(GitHub.loading && GitHub.accounts.length === 0)))
        Layout.fillWidth: true
        spacing: 12

        // Antes de empezar
        ColumnLayout {
            visible: !GitHub.loggingIn
            Layout.fillWidth: true
            spacing: 10

            Label {
                Layout.fillWidth: true
                text: "Inicia sesión para que gh y git usen tu cuenta de GitHub."
                wrapMode: Text.Wrap
                color: Theme.subtext
            }
            TextButton {
                Layout.fillWidth: true
                accent: true
                icon: Theme.iGithub
                text: "Iniciar sesión con GitHub"
                onClicked: GitHub.login()
            }
        }

        // Esperando la autorización: el código y el botón para abrir la página
        ColumnLayout {
            visible: GitHub.loggingIn
            Layout.fillWidth: true
            spacing: 10

            Label {
                Layout.fillWidth: true
                text: "Abre GitHub, pega este código y autoriza el acceso:"
                wrapMode: Text.Wrap
                color: Theme.subtext
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                radius: Theme.radiusSmall
                color: Theme.surface

                Text {
                    anchors.centerIn: parent
                    text: GitHub.deviceCode || "…"
                    color: Theme.text
                    font.family: Theme.monoFont
                    font.pixelSize: 30
                    font.weight: Font.DemiBold
                    font.letterSpacing: 3
                }
            }
            Label {
                visible: GitHub.deviceCode !== ""
                Layout.alignment: Qt.AlignHCenter
                text: "Ya está copiado en el portapapeles"
                color: Theme.subtext
                font.pixelSize: Theme.fontSize
            }
            RowLayout {
                spacing: 8
                TextButton {
                    Layout.fillWidth: true
                    accent: true
                    enabled: GitHub.deviceCode !== ""
                    icon: Theme.iChevronRight
                    text: "Abrir GitHub"
                    onClicked: GitHub.openDevicePage()
                }
                TextButton {
                    Layout.fillWidth: true
                    text: "Cancelar"
                    onClicked: GitHub.cancelLogin()
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                Icon {
                    id: waitIcon
                    text: Theme.iRefresh
                    color: Theme.subtext
                    font.pixelSize: 13
                    RotationAnimation on rotation {
                        running: GitHub.loggingIn
                        from: 0
                        to: 360
                        duration: 1200
                        loops: Animation.Infinite
                    }
                }
                Label {
                    text: "Esperando la autorización…"
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }

    // --- Error ---
    Label {
        visible: GitHub.error !== ""
        Layout.fillWidth: true
        text: GitHub.error
        wrapMode: Text.Wrap
        color: Theme.error
        font.pixelSize: Theme.fontSize
    }

    // --- Acciones ---
    RowLayout {
        visible: GitHub.loggedIn && !GitHub.loggingIn
        Layout.fillWidth: true
        spacing: 8

        TextButton {
            Layout.fillWidth: true
            icon: Theme.iChevronRight
            text: "Ver perfil"
            onClicked: {
                Qt.openUrlExternally(GitHub.user?.html_url ?? `https://github.com/${GitHub.active.login}`);
                win.close();
            }
        }
        TextButton {
            Layout.fillWidth: true
            icon: Theme.iPlus
            text: "Añadir cuenta"
            onClicked: GitHub.login()
        }
        TextButton {
            Layout.fillWidth: true
            accent: win.confirmLogout !== ""
            icon: Theme.iLogout
            text: win.confirmLogout !== "" ? "¿Seguro?" : "Cerrar sesión"
            onClicked: {
                if (win.confirmLogout !== "") {
                    GitHub.logout(win.confirmLogout);
                    win.confirmLogout = "";
                } else {
                    win.confirmLogout = GitHub.active.login;
                }
            }
        }
    }
}
