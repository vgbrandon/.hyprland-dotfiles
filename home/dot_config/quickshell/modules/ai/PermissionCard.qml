import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.services

// El agente pide permiso (editar un archivo, ejecutar un comando…): qué quiere hacer y
// sobre qué, con Permitir una vez / Siempre / Rechazar.
//   PermissionCard { request: req }
Rectangle {
    id: root

    required property var request

    readonly property string action: ({
        edit: "editar", write: "escribir", read: "leer", shell: "ejecutar", bash: "ejecutar",
        webfetch: "abrir", websearch: "buscar en la web", external_directory: "salir de la carpeta del proyecto"
    })[request.action] ?? request.action

    implicitHeight: column.implicitHeight + 20
    radius: Theme.radiusSmall
    color: Theme.withAlpha(Theme.warning, 0.12)
    border.color: Theme.withAlpha(Theme.warning, 0.5)
    border.width: 1

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 10
        anchors.leftMargin: 12
        spacing: 8

        RowLayout {
            spacing: 8

            Icon {
                text: Theme.iShield
                color: Theme.warning
                font.pixelSize: 16
            }
            Label {
                Layout.fillWidth: true
                text: `Quiere ${root.action}`
                font.weight: Font.DemiBold
            }
        }

        // Sobre qué (comandos, archivos…)
        Repeater {
            model: (root.request.resources ?? []).slice(0, 4)

            Text {
                required property string modelData
                Layout.fillWidth: true
                text: modelData
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 4
                elide: Text.ElideRight
                color: Theme.text
                font.family: Theme.monoFont
                font.pixelSize: Theme.fontSize - 1
            }
        }
        Label {
            visible: (root.request.message ?? "") !== ""
            Layout.fillWidth: true
            text: root.request.message ?? ""
            wrapMode: Text.Wrap
            color: Theme.subtext
            font.pixelSize: Theme.fontSize
        }

        RowLayout {
            spacing: 6

            TextButton {
                Layout.fillWidth: true
                small: true
                accent: true
                text: "Permitir"
                onClicked: AI.replyPermission(root.request, "once")
            }
            TextButton {
                Layout.fillWidth: true
                small: true
                text: "Siempre"
                onClicked: AI.replyPermission(root.request, "always")
            }
            TextButton {
                Layout.fillWidth: true
                small: true
                text: "Rechazar"
                onClicked: AI.replyPermission(root.request, "reject")
            }
        }
    }
}
