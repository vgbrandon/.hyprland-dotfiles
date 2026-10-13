import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.components.buttons
import qs.services

// Conversación de la lista: título, carpeta y hace cuánto. Clic = abrirla; lápiz =
// renombrar (Enter guarda, Esc cancela); papelera = borrar (pide un segundo clic).
Rectangle {
    id: root

    required property var session
    signal picked()

    property bool editing: false
    property bool confirmDelete: false
    readonly property bool current: session.id === AI.sessionId
    readonly property bool busy: AI.busySessions[session.id] === true

    function ago(ms) {
        const s = Math.max(0, (Date.now() - ms) / 1000);
        if (s < 60) return "ahora";
        if (s < 3600) return `hace ${Math.floor(s / 60)} min`;
        if (s < 86400) return `hace ${Math.floor(s / 3600)} h`;
        const d = Math.floor(s / 86400);
        return d === 1 ? "ayer" : `hace ${d} días`;
    }

    implicitHeight: 52
    radius: Theme.radiusSmall
    color: current ? Theme.surfaceHigh : mouse.containsMouse ? Theme.surface : "transparent"
    onEditingChanged: if (editing) {
        titleInput.text = session.title ?? "";
        titleInput.forceActiveFocus();
        titleInput.selectAll();
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (!root.editing) root.picked()
        onExited: root.confirmDelete = false
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 6
        spacing: 6

        // Trabajando: punto de color
        Rectangle {
            visible: root.busy
            implicitWidth: 8
            implicitHeight: 8
            radius: 4
            color: Theme.primary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                visible: !root.editing
                Layout.fillWidth: true
                text: root.session.title || "Sin título"
            }
            TextInput {
                id: titleInput
                visible: root.editing
                Layout.fillWidth: true
                color: Theme.text
                selectionColor: Theme.withAlpha(Theme.primary, 0.4)
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 2
                clip: true
                function commit() {
                    if (text.trim() !== "") AI.renameSession(root.session.id, text.trim());
                    root.editing = false;
                }
                Keys.onReturnPressed: commit()
                Keys.onEnterPressed: commit()
                Keys.onEscapePressed: root.editing = false
                onActiveFocusChanged: if (!activeFocus) root.editing = false
            }
            Label {
                Layout.fillWidth: true
                text: `${(root.session.location?.directory ?? "").replace(/^\/home\/[^/]+/, "~")}  ·  ${root.ago(root.session.time.updated)}`
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 1
            }
        }

        CircleButton {
            visible: mouse.containsMouse || hovered || root.editing
            icon: Theme.iPencil
            size: 28
            iconSize: 14
            iconColor: Theme.subtext
            onClicked: root.editing = true
        }
        CircleButton {
            visible: mouse.containsMouse || hovered || root.confirmDelete
            icon: Theme.iDelete
            size: 28
            iconSize: 14
            accent: root.confirmDelete
            accentColor: Theme.error
            iconColor: root.confirmDelete ? Theme.panelBg : Theme.subtext
            onClicked: {
                if (root.confirmDelete) AI.deleteSession(root.session.id);
                else root.confirmDelete = true;
            }
        }
    }
}
