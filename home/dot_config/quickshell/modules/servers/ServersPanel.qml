import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.buttons
import qs.components.containers
import qs.services

// Panel de servidores locales (icono de la barra): cada puerto con su proceso y su
// proyecto, y botones para abrirlo en el navegador, copiar la dirección, abrir el
// proyecto en Zed o detenerlo (segundo clic = forzar). Lógica en services/LocalServers.qml.
BarPopup {
    id: panel

    implicitWidth: 420
    padding: 14
    spacing: 10

    onVisibleChanged: {
        LocalServers.panelOpen = visible;
        if (visible) LocalServers.refresh();
    }

    function shortPath(p) {
        return p.replace(Quickshell.env("HOME"), "~");
    }

    PanelHeader {
        icon: Theme.iServer
        title: "Servidores locales"
        subtitle: LocalServers.servers.length === 0 ? "Ninguno en marcha"
            : LocalServers.servers.length === 1 ? "1 en marcha" : `${LocalServers.servers.length} en marcha`
    }

    // --- Servidores ---
    Repeater {
        model: LocalServers.servers

        ServerRow {
            required property var modelData
            server: modelData
        }
    }

    Label {
        visible: LocalServers.servers.length === 0
        Layout.alignment: Qt.AlignHCenter
        Layout.margins: 8
        text: "Cuando arranques un servidor (npm run dev, una API…) aparecerá aquí."
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        color: Theme.subtext
        font.pixelSize: Theme.fontSize
    }

    // --- Servicios en segundo plano (el de OpenCode) ---
    ColumnLayout {
        visible: LocalServers.services.length > 0
        Layout.fillWidth: true
        spacing: 4

        Label {
            Layout.leftMargin: 4
            Layout.topMargin: 4
            text: "En segundo plano"
            color: Theme.subtext
            font.pixelSize: Theme.fontSize
        }
        Repeater {
            model: LocalServers.services

            RowLayout {
                required property var modelData
                Layout.leftMargin: 4
                spacing: 8
                Text {
                    text: ":" + modelData.port
                    color: Theme.subtext
                    font.family: Theme.monoFont
                    font.pixelSize: Theme.fontSize
                }
                Label {
                    Layout.fillWidth: true
                    text: modelData.name === "opencode" ? "Servicio de OpenCode" : modelData.name
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }

    // Un servidor: puerto, proceso y proyecto, y sus acciones
    component ServerRow: Rectangle {
        id: row
        required property var server
        readonly property bool stopping: LocalServers.stopping[server.pid] === true

        Layout.fillWidth: true
        implicitHeight: rowLayout.implicitHeight + 16
        radius: Theme.radiusSmall
        color: Theme.surface

        RowLayout {
            id: rowLayout
            anchors.fill: parent
            anchors.margins: 8
            anchors.leftMargin: 12
            spacing: 10

            Icon {
                text: row.server.http ? Theme.iWeb : Theme.iDatabase
                color: row.server.http ? Theme.primary : Theme.subtext
                font.pixelSize: 18
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    spacing: 8
                    Text {
                        text: ":" + row.server.port
                        color: Theme.text
                        font.family: Theme.monoFont
                        font.pixelSize: Theme.fontSize + 3
                        font.weight: Font.DemiBold
                    }
                    Label {
                        Layout.fillWidth: true
                        text: row.server.name
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: panel.shortPath(row.server.project || row.server.cwd || row.server.command)
                    elide: Text.ElideMiddle
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 1
                }
            }

            CircleButton {
                visible: row.server.http
                icon: Theme.iOpenNew
                size: 28
                iconSize: 15
                onClicked: {
                    LocalServers.open(row.server);
                    panel.close();
                }
            }
            CircleButton {
                visible: row.server.http
                icon: Theme.iCopy
                size: 28
                iconSize: 14
                onClicked: LocalServers.copy(row.server)
            }
            CircleButton {
                visible: row.server.project !== ""
                icon: Theme.iFolder
                size: 28
                iconSize: 15
                onClicked: {
                    LocalServers.openProject(row.server);
                    panel.close();
                }
            }
            // Detener (segundo clic, si sigue vivo, lo fuerza)
            CircleButton {
                icon: Theme.iStop
                size: 28
                iconSize: 14
                accent: row.stopping
                accentColor: Theme.error
                iconColor: row.stopping ? Theme.panelBg : hovered ? Theme.error : Theme.subtext
                onClicked: LocalServers.stop(row.server)
            }
        }
    }
}
