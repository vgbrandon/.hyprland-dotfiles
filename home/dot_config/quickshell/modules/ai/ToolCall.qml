import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.services

// Herramienta que usó el agente (ejecutar un comando, leer o editar un archivo…): una
// línea con lo que hizo y su estado; clic = ver la entrada y el resultado.
//   ToolCall { part: p }
Rectangle {
    id: root

    required property var part
    property bool expanded: false

    readonly property var input: part.input ?? {}
    // Lo más descriptivo de la entrada: el comando, el archivo, el patrón…
    readonly property string summary: {
        const i = input;
        const v = i.command ?? i.filePath ?? i.file_path ?? i.path ?? i.pattern ?? i.url ?? i.query ?? i.description ?? "";
        return String(v).split("\n")[0];
    }
    readonly property string label: ({
        shell: "Ejecutó", bash: "Ejecutó", read: "Leyó", write: "Escribió", edit: "Editó", patch: "Editó",
        glob: "Buscó archivos", grep: "Buscó", list: "Listó", webfetch: "Abrió", websearch: "Buscó en la web",
        todowrite: "Actualizó tareas", task: "Delegó", question: "Preguntó"
    })[part.name] ?? part.name

    implicitHeight: column.implicitHeight + 12
    radius: Theme.radiusSmall
    color: mouse.containsMouse && !expanded ? Theme.surface : Theme.withAlpha(Theme.surface, 0.6)

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 6
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 6

        RowLayout {
            spacing: 8

            // Estado: girando mientras corre, ✓ o ⚠ al terminar
            Icon {
                id: statusIcon
                text: root.part.status === "completed" ? Theme.iCheck
                    : root.part.status === "error" ? Theme.iAlert : Theme.iRefresh
                color: root.part.status === "error" ? Theme.error
                    : root.part.status === "completed" ? Theme.subtext : Theme.primary
                font.pixelSize: 14
                RotationAnimation on rotation {
                    running: root.part.status === "pending" || root.part.status === "running"
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) statusIcon.rotation = 0
                }
            }
            Label {
                text: root.label
                color: Theme.subtext
                font.pixelSize: Theme.fontSize
            }
            Text {
                Layout.fillWidth: true
                text: root.summary
                elide: Text.ElideRight
                color: Theme.text
                font.family: Theme.monoFont
                font.pixelSize: Theme.fontSize - 1
            }
            Icon {
                text: root.expanded ? Theme.iChevronUp : Theme.iChevronDown
                color: Theme.subtext
                font.pixelSize: 14
            }
        }

        // Detalle: entrada completa y resultado (recortado)
        Text {
            visible: root.expanded
            Layout.fillWidth: true
            text: JSON.stringify(root.input, null, 2)
            wrapMode: Text.WrapAnywhere
            color: Theme.subtext
            font.family: Theme.monoFont
            font.pixelSize: Theme.fontSize - 2
        }
        Rectangle {
            visible: root.expanded && root.part.output !== ""
            Layout.fillWidth: true
            implicitHeight: output.implicitHeight + 12
            radius: 6
            color: Theme.panelBg

            TextEdit {
                id: output
                anchors.fill: parent
                anchors.margins: 6
                text: {
                    const lines = root.part.output.split("\n");
                    return lines.length > 30 ? lines.slice(0, 30).join("\n") + `\n… (${lines.length - 30} líneas más)` : root.part.output;
                }
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.WrapAnywhere
                color: root.part.status === "error" ? Theme.error : Theme.text
                selectionColor: Theme.withAlpha(Theme.primary, 0.4)
                font.family: Theme.monoFont
                font.pixelSize: Theme.fontSize - 2
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        // Al desplegar, solo la cabecera pliega (para poder seleccionar el resultado)
        anchors.bottomMargin: root.expanded ? parent.height - 30 : 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded
    }
}
