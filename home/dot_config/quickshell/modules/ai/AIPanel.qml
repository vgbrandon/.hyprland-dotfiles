import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.buttons
import qs.components.containers
import qs.services

// Panel del asistente de IA (OpenCode): entra desde la izquierda. Conversación con la
// respuesta en vivo, conversaciones anteriores, modelo y permisos. Lógica en services/AI.qml.
//   Enter = enviar · Shift+Enter = salto de línea · Esc = cerrar
SidePanel {
    id: panel

    open: AI.open
    onCloseRequested: AI.close()
    namespace: "quickshell:ai"
    edge: "left"
    spacing: 8

    // Lista de conversaciones en lugar del chat
    property bool showSessions: false
    // Selector de modelo abierto
    property bool showModels: false
    // Menú ⋯ de la cabecera
    property bool showMenu: false
    // Elegir la carpeta de trabajo
    property bool showFolders: false
    // Menú de adjuntar
    property bool showAttach: false
    // Archivos mencionados con @ (rutas relativas a la carpeta)
    property var mentions: []

    // Sugerencias mientras se escribe: comandos ("/" al principio) o archivos ("@")
    // { kind: "command" | "file", label, detail, value }
    property var suggestions: []
    property int suggestionIndex: 0
    property int mentionStart: -1
    property string suggestQuery: ""
    readonly property var localCommands: [
        { name: "nueva", description: "Empezar una conversación nueva" },
        { name: "compactar", description: "Resumir la conversación para liberar memoria" }
    ]

    function updateSuggestions() {
        const t = input.text, c = input.cursorPosition;
        const before = t.slice(0, c);
        if (t.startsWith("/") && !before.includes(" ") && !before.includes("\n")) {
            const q = before.slice(1).toLowerCase();
            suggestions = localCommands.concat(AI.commands)
                .filter(cmd => cmd.name.toLowerCase().startsWith(q))
                .map(cmd => ({ kind: "command", label: "/" + cmd.name, detail: cmd.description, value: cmd.name }));
            suggestionIndex = 0;
            return;
        }
        const m = before.match(/(^|\s)@([^\s@]*)$/);
        if (m) {
            mentionStart = c - m[2].length - 1;
            const q = m[2];
            if (q === suggestQuery && suggestions.length > 0) return;
            suggestQuery = q;
            if (q === "") {
                suggestions = [];
                return;
            }
            AI.findPaths(q, "file", AI.directory, paths => {
                if (suggestQuery !== q) return;
                // La búsqueda de OpenCode es difusa: si hay rutas que contienen lo escrito,
                // solo esas (primero las que lo tienen en el nombre del archivo)
                const ql = q.toLowerCase();
                const exact = paths.filter(p => p.toLowerCase().includes(ql));
                const list = (exact.length > 0 ? exact : paths)
                    .sort((a, b) => (b.split("/").pop().toLowerCase().includes(ql)) - (a.split("/").pop().toLowerCase().includes(ql)));
                suggestions = list.map(p => ({ kind: "file", label: p.split("/").pop(), detail: p, value: p }));
                suggestionIndex = 0;
            });
            return;
        }
        suggestions = [];
        suggestQuery = "";
    }

    function acceptSuggestion(item) {
        if (!item) return;
        if (item.kind === "command") {
            input.text = "/" + item.value + " ";
        } else {
            const c = input.cursorPosition;
            input.text = input.text.slice(0, mentionStart) + "@" + item.value + " " + input.text.slice(c);
            if (!mentions.includes(item.value)) mentions = mentions.concat([item.value]);
            input.cursorPosition = mentionStart + item.value.length + 2;
        }
        suggestions = [];
        input.cursorPosition = Math.min(input.cursorPosition, input.length);
        if (item.kind === "command") input.cursorPosition = input.length;
    }

    onOpenChanged: {
        showModels = false;
        showMenu = false;
        showFolders = false;
        showAttach = false;
        if (open) focusTimer.restart();
    }
    // Tras el foco del panel (SidePanel lo da a los 50 ms), el cursor va al campo de texto
    Timer {
        id: focusTimer
        interval: 80
        onTriggered: if (!panel.showSessions) input.forceActiveFocus()
    }

    // --- Cabecera ---
    RowLayout {
        Layout.leftMargin: 4
        spacing: 6

        OpenCodeLogo {
            Layout.leftMargin: 2
            Layout.rightMargin: 2
            size: 18
            color: AI.busy ? Theme.primary : Theme.text
        }
        Label {
            Layout.fillWidth: true
            text: panel.showSessions ? "Conversaciones" : AI.title
            font.pixelSize: 16
        }
        CircleButton {
            icon: Theme.iList
            filled: panel.showSessions
            onClicked: {
                panel.showSessions = !panel.showSessions;
                if (panel.showSessions) AI.loadSessions();
            }
        }
        CircleButton {
            icon: Theme.iPlus
            onClicked: {
                AI.newSession();
                panel.showSessions = false;
                input.forceActiveFocus();
            }
        }
        CircleButton {
            icon: Theme.iDots
            filled: panel.showMenu
            onClicked: panel.showMenu = !panel.showMenu
        }
    }

    // --- Menú ⋯ ---
    Rectangle {
        visible: panel.showMenu
        Layout.fillWidth: true
        implicitHeight: menuColumn.implicitHeight + 12
        radius: Theme.radiusSmall
        color: Theme.surface
        border.color: Theme.surfaceHigh
        border.width: 1

        ColumnLayout {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            MenuRow {
                icon: Theme.iFolder
                text: "Carpeta: " + AI.shortPath(AI.directory)
                hint: "Dónde trabaja el agente (cambiarla empieza una conversación nueva)"
                onClicked: {
                    panel.showMenu = false;
                    panel.showFolders = true;
                    AI.loadProjects();
                }
            }
            MenuRow {
                icon: Theme.iCompress
                text: "Compactar conversación"
                hint: "Resume lo hablado para liberar memoria del modelo"
                enabled: AI.sessionId !== "" && !AI.busy
                onClicked: {
                    panel.showMenu = false;
                    AI.compact();
                }
            }
            MenuRow {
                icon: Theme.iShield
                text: AI.askFirst ? "Pedir permiso: activado" : "Pedir permiso: desactivado"
                hint: AI.askFirst ? "Pregunta antes de editar archivos o ejecutar comandos" : "Edita y ejecuta sin preguntar (como OpenCode por defecto)"
                onClicked: AI.setAskFirst(!AI.askFirst)
            }
        }
    }

    // --- Elegir carpeta de trabajo ---
    Rectangle {
        id: folders
        visible: panel.showFolders
        Layout.fillWidth: true
        implicitHeight: folderColumn.implicitHeight + 16
        radius: Theme.radiusSmall
        color: Theme.surface
        border.color: Theme.surfaceHigh
        border.width: 1

        property var found: []

        ColumnLayout {
            id: folderColumn
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            RowLayout {
                Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    text: "Carpeta de trabajo"
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                }
                CircleButton {
                    icon: Theme.iClose
                    size: 24
                    iconSize: 13
                    onClicked: panel.showFolders = false
                }
            }

            // Buscar otra carpeta (dentro de la carpeta personal)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: height / 2
                color: Theme.panelBg

                TextInput {
                    id: folderSearch
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                    onTextChanged: {
                        const q = text.trim();
                        if (q === "") {
                            folders.found = [];
                            return;
                        }
                        AI.findPaths(q, "directory", Quickshell.env("HOME"), paths => {
                            if (folderSearch.text.trim() === q) folders.found = paths;
                        });
                    }
                    Keys.onEscapePressed: panel.showFolders = false

                    Text {
                        visible: folderSearch.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Buscar una carpeta…"
                        color: Theme.subtext
                        font: folderSearch.font
                    }
                }
            }

            Repeater {
                // Resultados de la búsqueda o, sin búsqueda, la personal y las usadas antes
                model: folderSearch.text.trim() !== ""
                    ? folders.found.map(p => Quickshell.env("HOME") + "/" + p.replace(/\/$/, ""))
                    : [Quickshell.env("HOME")].concat(AI.projects.filter(p => p !== Quickshell.env("HOME"))).slice(0, 8)

                Rectangle {
                    id: folderRow
                    required property string modelData
                    readonly property bool current: modelData === AI.directory
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: 8
                    color: folderMouse.containsMouse ? Theme.surfaceHigh : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8
                        Icon {
                            text: Theme.iFolder
                            color: folderRow.current ? Theme.primary : Theme.subtext
                            font.pixelSize: 14
                        }
                        Label {
                            Layout.fillWidth: true
                            text: AI.shortPath(folderRow.modelData)
                            elide: Text.ElideMiddle
                            color: folderRow.current ? Theme.primary : Theme.text
                            font.pixelSize: Theme.fontSize + 1
                        }
                    }
                    MouseArea {
                        id: folderMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!folderRow.current) AI.setDirectory(folderRow.modelData);
                            folderSearch.text = "";
                            panel.showFolders = false;
                            panel.showSessions = false;
                            input.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }

    // --- Error de la última acción ---
    Rectangle {
        visible: AI.error !== "" && !panel.showSessions
        Layout.fillWidth: true
        implicitHeight: errorBanner.implicitHeight + 16
        radius: Theme.radiusSmall
        color: Theme.withAlpha(Theme.error, 0.12)

        RowLayout {
            id: errorBanner
            anchors.fill: parent
            anchors.margins: 8
            anchors.leftMargin: 12
            spacing: 8

            Icon {
                text: Theme.iAlert
                color: Theme.error
                font.pixelSize: 14
            }
            Label {
                Layout.fillWidth: true
                text: AI.error
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSize
            }
            CircleButton {
                icon: Theme.iClose
                size: 24
                iconSize: 13
                onClicked: AI.error = ""
            }
        }
    }

    // --- Estado de la conexión ---
    Rectangle {
        visible: AI.status !== "ready"
        Layout.fillWidth: true
        implicitHeight: statusRow.implicitHeight + 16
        radius: Theme.radiusSmall
        color: AI.status === "error" ? Theme.withAlpha(Theme.error, 0.12) : Theme.surface

        RowLayout {
            id: statusRow
            anchors.fill: parent
            anchors.margins: 8
            anchors.leftMargin: 12
            spacing: 8

            Icon {
                text: AI.status === "error" ? Theme.iAlert : Theme.iRefresh
                color: AI.status === "error" ? Theme.error : Theme.subtext
                font.pixelSize: 14
            }
            Label {
                Layout.fillWidth: true
                text: AI.statusText
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSize
            }
            TextButton {
                visible: AI.status === "error"
                small: true
                text: "Reintentar"
                onClicked: AI.connect()
            }
        }
    }

    // --- Conversaciones anteriores ---
    ListView {
        id: sessionList
        visible: panel.showSessions
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2
        model: AI.sessions
        boundsBehavior: Flickable.StopAtBounds

        delegate: SessionRow {
            required property var modelData
            session: modelData
            width: sessionList.width
            onPicked: {
                AI.loadSession(modelData.id);
                panel.showSessions = false;
            }
        }

        Label {
            visible: sessionList.count === 0
            anchors.centerIn: parent
            text: "Aún no hay conversaciones"
            color: Theme.subtext
        }
    }

    // --- Chat ---
    ListView {
        id: chat
        visible: !panel.showSessions
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 14
        model: ScriptModel { values: AI.messages }
        boundsBehavior: Flickable.StopAtBounds
        // Sigue al final mientras llega la respuesta, salvo que se haya subido a leer
        property bool atEnd: true
        onContentHeightChanged: if (atEnd) Qt.callLater(positionViewAtEnd)
        onMovementEnded: atEnd = contentY >= contentHeight - height - 40
        onCountChanged: {
            atEnd = true;
            Qt.callLater(positionViewAtEnd);
        }

        delegate: Loader {
            id: entry
            required property var modelData
            width: chat.width
            sourceComponent: modelData.kind === "user" ? userBubble
                : modelData.kind === "error" ? errorCard
                : modelData.kind === "note" ? noteLine : assistantBlock

            Component {
                id: userBubble

                Item {
                    implicitHeight: bubble.height

                    HoverHandler { id: bubbleHover }

                    // Deshacer desde este mensaje (al pasar el ratón)
                    CircleButton {
                        visible: (bubbleHover.hovered || hovered) && !AI.busy && entry.modelData.mid.startsWith("msg_")
                        anchors.right: bubble.left
                        anchors.rightMargin: 4
                        anchors.verticalCenter: bubble.verticalCenter
                        icon: Theme.iUndo
                        size: 26
                        iconSize: 14
                        iconColor: Theme.subtext
                        onClicked: AI.stageRevert(entry.modelData.mid)
                    }

                    Rectangle {
                        id: bubble
                        anchors.right: parent.right
                        width: Math.min(parent.width * 0.85, Math.max(userText.implicitWidth, userFiles.implicitWidth) + 24)
                        height: userText.implicitHeight + 16 + (userFiles.visible ? userFiles.implicitHeight + 6 : 0)
                        radius: Theme.radius
                        color: Theme.surfaceHigh

                        TextEdit {
                            id: userText
                            anchors.fill: parent
                            anchors.margins: 8
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            anchors.bottomMargin: userFiles.visible ? userFiles.implicitHeight + 14 : 8
                            text: entry.modelData.text
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            color: Theme.text
                            selectionColor: Theme.withAlpha(Theme.primary, 0.4)
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 1
                        }
                        // Adjuntos del mensaje
                        Flow {
                            id: userFiles
                            visible: entry.modelData.files.length > 0
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.margins: 8
                            anchors.leftMargin: 12
                            width: parent.width - 24
                            spacing: 4
                            Repeater {
                                model: entry.modelData.files
                                Rectangle {
                                    required property string modelData
                                    implicitWidth: fileLabel.implicitWidth + 30
                                    implicitHeight: 22
                                    radius: height / 2
                                    color: Theme.surface
                                    Icon {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Theme.iAttach
                                        color: Theme.subtext
                                        font.pixelSize: 12
                                    }
                                    Label {
                                        id: fileLabel
                                        anchors.left: parent.left
                                        anchors.leftMargin: 22
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData
                                        color: Theme.subtext
                                        font.pixelSize: Theme.fontSize - 1
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: assistantBlock

                ColumnLayout {
                    spacing: 8

                    Repeater {
                        model: entry.modelData.parts

                        Loader {
                            id: partLoader
                            required property var modelData
                            Layout.fillWidth: true
                            sourceComponent: modelData.type === "tool" ? toolPart
                                : modelData.type === "reasoning" ? reasoningPart : textPart

                            Component {
                                id: textPart
                                MarkdownText { text: partLoader.modelData.text }
                            }
                            Component {
                                id: reasoningPart
                                Reasoning { part: partLoader.modelData }
                            }
                            Component {
                                id: toolPart
                                ToolCall { part: partLoader.modelData }
                            }
                        }
                    }
                }
            }

            // Aviso discreto en medio (p. ej. "Conversación compactada")
            Component {
                id: noteLine

                RowLayout {
                    spacing: 10
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Theme.surfaceHigh
                    }
                    Label {
                        text: entry.modelData.text
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 1
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Theme.surfaceHigh
                    }
                }
            }

            Component {
                id: errorCard

                Rectangle {
                    implicitHeight: errorRow.implicitHeight + 16
                    radius: Theme.radiusSmall
                    color: Theme.withAlpha(Theme.error, 0.12)

                    RowLayout {
                        id: errorRow
                        anchors.fill: parent
                        anchors.margins: 8
                        anchors.leftMargin: 12
                        spacing: 8

                        Icon {
                            text: Theme.iAlert
                            color: Theme.error
                            font.pixelSize: 14
                        }
                        Label {
                            Layout.fillWidth: true
                            text: entry.modelData.text
                            wrapMode: Text.Wrap
                            font.pixelSize: Theme.fontSize
                        }
                    }
                }
            }
        }

        // Trabajando sin texto nuevo a la vista: puntos animados al final
        footer: Item {
            width: chat.width
            height: AI.busy ? 30 : 0

            Row {
                visible: AI.busy
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                spacing: 5

                Repeater {
                    model: 3

                    Rectangle {
                        required property int index
                        width: 7
                        height: 7
                        radius: 3.5
                        color: Theme.subtext

                        SequentialAnimation on opacity {
                            running: AI.busy
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 150 }
                            NumberAnimation { to: 0.2; duration: 350 }
                            NumberAnimation { to: 1; duration: 350 }
                            PauseAnimation { duration: (2 - index) * 150 }
                        }
                    }
                }
            }
        }

        // Conversación vacía
        ColumnLayout {
            visible: chat.count === 0 && AI.status === "ready"
            anchors.centerIn: parent
            width: parent.width - 40
            spacing: 8

            OpenCodeLogo {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 6
                size: 40
                color: Theme.subtext
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "¿En qué te ayudo?"
                font.pixelSize: 18
            }
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: `Trabaja en ${AI.directory.replace(Quickshell.env("HOME"), "~")}. Puede leer y editar archivos y ejecutar comandos; te pedirá permiso cuando haga falta.`
                wrapMode: Text.Wrap
                color: Theme.subtext
                font.pixelSize: Theme.fontSize
            }
        }
    }

    // --- Deshacer pendiente de confirmar ---
    Rectangle {
        visible: AI.revertPending !== null && !panel.showSessions
        Layout.fillWidth: true
        implicitHeight: revertColumn.implicitHeight + 20
        radius: Theme.radiusSmall
        color: Theme.withAlpha(Theme.warning, 0.12)
        border.color: Theme.withAlpha(Theme.warning, 0.5)
        border.width: 1

        ColumnLayout {
            id: revertColumn
            anchors.fill: parent
            anchors.margins: 10
            anchors.leftMargin: 12
            spacing: 8

            Label {
                Layout.fillWidth: true
                text: {
                    const n = AI.revertPending?.files?.length ?? 0;
                    return "Se borrará ese mensaje y todo lo que vino después"
                        + (n > 0 ? `, y se desharán los cambios en ${n === 1 ? "1 archivo" : n + " archivos"}.` : ".");
                }
                wrapMode: Text.Wrap
            }
            Repeater {
                model: (AI.revertPending?.files ?? []).slice(0, 6)
                Text {
                    required property var modelData
                    Layout.fillWidth: true
                    text: (modelData.file ?? modelData.path ?? "").replace(/^\/home\/[^/]+/, "~")
                    elide: Text.ElideMiddle
                    color: Theme.subtext
                    font.family: Theme.monoFont
                    font.pixelSize: Theme.fontSize - 1
                }
            }
            RowLayout {
                spacing: 6
                Item { Layout.fillWidth: true }
                TextButton {
                    small: true
                    flat: true
                    text: "Cancelar"
                    onClicked: AI.cancelRevert()
                }
                TextButton {
                    small: true
                    accent: true
                    text: "Deshacer"
                    onClicked: AI.commitRevert()
                }
            }
        }
    }

    // --- Preguntas del agente ---
    Repeater {
        model: panel.showSessions ? [] : AI.forms

        FormCard {
            required property var modelData
            Layout.fillWidth: true
            form: modelData
        }
    }

    // --- Permisos pendientes ---
    Repeater {
        model: panel.showSessions ? [] : AI.permissions

        PermissionCard {
            required property var modelData
            Layout.fillWidth: true
            request: modelData
        }
    }

    // --- Sugerencias: comandos / y archivos @ ---
    Rectangle {
        visible: panel.suggestions.length > 0 && !panel.showSessions
        Layout.fillWidth: true
        implicitHeight: Math.min(suggestionList.contentHeight, 240) + 12
        radius: Theme.radiusSmall
        color: Theme.surface
        border.color: Theme.surfaceHigh
        border.width: 1

        ListView {
            id: suggestionList
            anchors.fill: parent
            anchors.margins: 6
            clip: true
            model: panel.suggestions
            currentIndex: panel.suggestionIndex
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: suggestionRow
                required property var modelData
                required property int index
                width: suggestionList.width
                height: 34
                radius: 8
                color: index === panel.suggestionIndex ? Theme.surfaceHigh : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10
                    Icon {
                        text: suggestionRow.modelData.kind === "command" ? Theme.iSlash : Theme.iAt
                        color: Theme.subtext
                        font.pixelSize: 14
                    }
                    Label {
                        text: suggestionRow.modelData.label
                    }
                    Label {
                        Layout.fillWidth: true
                        text: suggestionRow.modelData.detail
                        elide: suggestionRow.modelData.kind === "file" ? Text.ElideMiddle : Text.ElideRight
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 1
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: panel.suggestionIndex = suggestionRow.index
                    onClicked: {
                        panel.acceptSuggestion(suggestionRow.modelData);
                        input.forceActiveFocus();
                    }
                }
            }
        }
    }

    // --- Adjuntar ---
    Rectangle {
        visible: panel.showAttach && !panel.showSessions
        Layout.fillWidth: true
        implicitHeight: attachColumn.implicitHeight + 12
        radius: Theme.radiusSmall
        color: Theme.surface
        border.color: Theme.surfaceHigh
        border.width: 1

        ColumnLayout {
            id: attachColumn
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            MenuRow {
                icon: Theme.iRegion
                text: "Capturar una zona de la pantalla"
                hint: "Elige con el ratón lo que quieres que vea"
                onClicked: {
                    panel.showAttach = false;
                    AI.captureRegion();
                }
            }
            MenuRow {
                icon: Theme.iImage
                text: "Imagen del portapapeles"
                hint: "También al pegar con Ctrl+V en el campo de texto"
                onClicked: {
                    panel.showAttach = false;
                    AI.pasteImage();
                }
            }
            MenuRow {
                icon: Theme.iAt
                text: "Mencionar un archivo"
                hint: "Escribe @ y parte del nombre en el campo de texto"
                onClicked: {
                    panel.showAttach = false;
                    input.insert(input.cursorPosition, (input.cursorPosition > 0 && !/\s$/.test(input.text.slice(0, input.cursorPosition)) ? " @" : "@"));
                    input.forceActiveFocus();
                }
            }
        }
    }

    // --- Selector de modelo (encima del campo de texto) ---
    Rectangle {
        visible: panel.showModels && !panel.showSessions
        Layout.fillWidth: true
        implicitHeight: Math.min(modelList.contentHeight, 260) + 12
        radius: Theme.radiusSmall
        color: Theme.surface
        border.color: Theme.surfaceHigh
        border.width: 1

        ListView {
            id: modelList
            anchors.fill: parent
            anchors.margins: 6
            clip: true
            model: AI.models
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: modelRow
                required property var modelData
                readonly property bool current: AI.model?.providerID === modelData.providerID && AI.model?.id === modelData.id
                width: modelList.width
                height: 34
                radius: 8
                color: modelMouse.containsMouse ? Theme.surfaceHigh : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Label {
                        Layout.fillWidth: true
                        text: modelRow.modelData.name
                        color: modelRow.current ? Theme.primary : Theme.text
                    }
                    Label {
                        visible: modelRow.modelData.free
                        text: "Gratis"
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 1
                    }
                    Icon {
                        visible: modelRow.current
                        text: Theme.iCheck
                        color: Theme.primary
                        font.pixelSize: 14
                    }
                }
                MouseArea {
                    id: modelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        AI.setModel(modelRow.modelData);
                        panel.showModels = false;
                        input.forceActiveFocus();
                    }
                }
            }
        }
    }

    // --- Campo de texto ---
    Rectangle {
        visible: !panel.showSessions
        Layout.fillWidth: true
        implicitHeight: inputColumn.implicitHeight + 16
        radius: Theme.radius
        color: Theme.surface
        border.color: input.activeFocus ? Theme.withAlpha(Theme.primary, 0.5) : Theme.surfaceHigh
        border.width: 1

        ColumnLayout {
            id: inputColumn
            anchors.fill: parent
            anchors.margins: 8
            anchors.leftMargin: 12
            spacing: 6

            // Adjuntos que se enviarán con el mensaje
            Flow {
                visible: AI.attachments.length > 0
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: AI.attachments

                    Rectangle {
                        id: attachChip
                        required property var modelData
                        implicitWidth: attachRow.implicitWidth + 12
                        implicitHeight: 40
                        radius: 8
                        color: Theme.surfaceHigh

                        RowLayout {
                            id: attachRow
                            anchors.centerIn: parent
                            spacing: 6
                            Image {
                                visible: attachChip.modelData.image
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                source: attachChip.modelData.image ? "file://" + attachChip.modelData.path : ""
                                sourceSize.width: 64
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            Icon {
                                visible: !attachChip.modelData.image
                                text: Theme.iAttach
                                color: Theme.subtext
                                font.pixelSize: 14
                            }
                            Label {
                                text: attachChip.modelData.name
                                font.pixelSize: Theme.fontSize
                            }
                            CircleButton {
                                icon: Theme.iClose
                                size: 20
                                iconSize: 11
                                iconColor: Theme.subtext
                                onClicked: AI.removeAttachment(attachChip.modelData.path)
                            }
                        }
                    }
                }
            }

            // Crece con el texto hasta ~6 líneas; después se desplaza
            Flickable {
                id: inputFlick
                Layout.fillWidth: true
                implicitHeight: Math.min(input.implicitHeight, 140)
                contentHeight: input.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                TextEdit {
                    id: input
                    width: inputFlick.width
                    wrapMode: TextEdit.Wrap
                    color: Theme.text
                    selectionColor: Theme.withAlpha(Theme.primary, 0.4)
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                    onCursorRectangleChanged: {
                        const r = cursorRectangle;
                        if (r.y < inputFlick.contentY) inputFlick.contentY = r.y;
                        else if (r.y + r.height > inputFlick.contentY + inputFlick.height)
                            inputFlick.contentY = r.y + r.height - inputFlick.height;
                    }

                    Text {
                        visible: input.text === ""
                        text: AI.busy ? "Escribe para añadir algo mientras responde…" : "Pregunta o pide algo…"
                        color: Theme.subtext
                        font: input.font
                    }

                    onTextChanged: panel.updateSuggestions()
                    // Al escribir, el texto cambia antes que la posición del cursor: se mira en ambos
                    onCursorPositionChanged: panel.updateSuggestions()

                    Keys.onPressed: e => {
                        const n = panel.suggestions.length;
                        if (n > 0 && (e.key === Qt.Key_Down || e.key === Qt.Key_Up)) {
                            panel.suggestionIndex = (panel.suggestionIndex + (e.key === Qt.Key_Down ? 1 : n - 1)) % n;
                            e.accepted = true;
                        } else if (n > 0 && (e.key === Qt.Key_Tab || ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && !(e.modifiers & Qt.ShiftModifier)))) {
                            panel.acceptSuggestion(panel.suggestions[panel.suggestionIndex]);
                            e.accepted = true;
                        } else if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && !(e.modifiers & Qt.ShiftModifier)) {
                            panel.sendInput();
                            e.accepted = true;
                        } else if (e.key === Qt.Key_Escape) {
                            if (n > 0) panel.suggestions = [];
                            else if (panel.showModels || panel.showAttach) {
                                panel.showModels = false;
                                panel.showAttach = false;
                            } else AI.close();
                            e.accepted = true;
                        } else if (e.key === Qt.Key_V && (e.modifiers & Qt.ControlModifier)) {
                            // Si lo copiado es una imagen, se adjunta (el texto se pega como siempre)
                            AI.pasteImage(true);
                        }
                    }
                }
            }

            RowLayout {
                spacing: 6

                // Adjuntar (captura, portapapeles, archivo)
                CircleButton {
                    icon: Theme.iAttach
                    size: 28
                    iconSize: 15
                    filled: panel.showAttach
                    iconColor: Theme.subtext
                    onClicked: {
                        panel.showAttach = !panel.showAttach;
                        panel.showModels = false;
                    }
                }

                // Modelo
                Rectangle {
                    implicitWidth: modelChip.implicitWidth + 20
                    implicitHeight: 28
                    radius: height / 2
                    color: chipMouse.containsMouse || panel.showModels ? Theme.surfaceHigh : "transparent"

                    RowLayout {
                        id: modelChip
                        anchors.centerIn: parent
                        spacing: 4

                        Label {
                            text: AI.modelName
                            color: Theme.subtext
                            font.pixelSize: Theme.fontSize
                        }
                        Icon {
                            text: panel.showModels ? Theme.iChevronDown : Theme.iChevronUp
                            color: Theme.subtext
                            font.pixelSize: 13
                        }
                    }
                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            panel.showModels = !panel.showModels;
                            if (panel.showModels) AI.loadModels();
                        }
                    }
                }

                // Agente: Build (actúa) o Plan (solo lee y propone)
                Repeater {
                    model: AI.agents

                    Rectangle {
                        id: agentChip
                        required property var modelData
                        readonly property bool on: AI.agent === modelData.id
                        implicitWidth: agentLabel.implicitWidth + 18
                        implicitHeight: 26
                        radius: height / 2
                        color: on ? Theme.withAlpha(Theme.primary, 0.18) : agentMouse.containsMouse ? Theme.surfaceHigh : "transparent"

                        Label {
                            id: agentLabel
                            anchors.centerIn: parent
                            text: agentChip.modelData.name
                            color: agentChip.on ? Theme.primary : Theme.subtext
                            font.pixelSize: Theme.fontSize
                        }
                        MouseArea {
                            id: agentMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AI.setAgent(agentChip.modelData.id)
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Pedir permiso antes de editar o ejecutar (escudo de color = activado)
                CircleButton {
                    icon: Theme.iShield
                    size: 26
                    iconSize: 14
                    iconColor: AI.askFirst ? Theme.primary : Theme.subtext
                    onClicked: AI.setAskFirst(!AI.askFirst)
                }

                // Tokens usados en la conversación
                Label {
                    visible: AI.usage !== null && AI.sessionId !== "" && text !== "0 tokens"
                    text: {
                        const u = AI.usage;
                        if (!u) return "";
                        const total = (u.input ?? 0) + (u.output ?? 0) + (u.reasoning ?? 0) + (u.cache?.read ?? 0);
                        return total >= 1000 ? `${(total / 1000).toFixed(total >= 10000 ? 0 : 1)}k tokens` : `${total} tokens`;
                    }
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 1
                }

                // Enviar, o detener mientras responde (con texto escrito, envía)
                CircleButton {
                    readonly property bool stopping: AI.busy && input.text.trim() === ""
                    icon: stopping ? Theme.iStop : Theme.iSend
                    size: 32
                    iconSize: 16
                    accent: true
                    enabled: stopping || (input.text.trim() !== "" && AI.status === "ready")
                    onClicked: stopping ? AI.stop() : panel.sendInput()
                }
            }
        }
    }

    // Opción del menú ⋯: icono, texto y una explicación debajo
    component MenuRow: Rectangle {
        id: menuRow
        property string icon
        property string text
        property string hint
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: menuRowColumn.implicitHeight + 12
        radius: 8
        opacity: enabled ? 1 : 0.45
        color: menuRowMouse.containsMouse && enabled ? Theme.surfaceHigh : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Icon {
                text: menuRow.icon
                color: Theme.subtext
                font.pixelSize: 16
            }
            ColumnLayout {
                id: menuRowColumn
                Layout.fillWidth: true
                spacing: 0
                Label {
                    Layout.fillWidth: true
                    text: menuRow.text
                }
                Label {
                    Layout.fillWidth: true
                    text: menuRow.hint
                    wrapMode: Text.Wrap
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 1
                }
            }
        }
        MouseArea {
            id: menuRowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: menuRow.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (menuRow.enabled) menuRow.clicked()
        }
    }

    function sendInput() {
        const text = input.text.trim();
        if (text === "") return;
        const cmd = text.match(/^\/(\S+)\s*([\s\S]*)$/);
        if (cmd && cmd[1] === "nueva") {
            AI.newSession();
        } else if (cmd && cmd[1] === "compactar") {
            AI.compact();
        } else if (cmd && AI.commands.some(c => c.name === cmd[1])) {
            AI.runCommand(cmd[1], cmd[2]);
        } else {
            AI.send(text, mentions);
        }
        input.text = "";
        mentions = [];
        suggestions = [];
        showModels = false;
        showAttach = false;
        chat.atEnd = true;
    }
}
