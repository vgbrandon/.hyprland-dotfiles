pragma Singleton

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// Lanzador de aplicaciones. Se abre con: quickshell ipc call launcher toggle
Singleton {
    id: root

    property bool open: false
    property string query: ""
    // Veces que se abrió cada app ({ id: número }), guardado en disco
    property var usage: ({})

    // Más usadas primero; a igualdad, orden alfabético
    readonly property var apps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => (usage[b.id] ?? 0) - (usage[a.id] ?? 0) || a.name.localeCompare(b.name))

    // Coincidencias ordenadas: empieza por > palabra empieza por > contiene > otros campos.
    // Dentro de cada nivel se mantiene el orden por uso (sort estable).
    readonly property var results: {
        const q = query.trim().toLowerCase();
        if (q === "") return apps;
        const score = a => {
            const name = a.name.toLowerCase();
            if (name.startsWith(q)) return 4;
            if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 3;
            if (name.includes(q)) return 2;
            const extra = [a.genericName, a.comment, a.id, ...(a.keywords ?? [])].join(" ").toLowerCase();
            return extra.includes(q) ? 1 : 0;
        };
        return apps.map(a => ({ a, s: score(a) }))
            .filter(x => x.s > 0)
            .sort((x, y) => y.s - x.s)
            .map(x => x.a);
    }

    function toggle() {
        open = !open;
    }

    function launch(entry) {
        if (!entry) return;
        entry.execute();
        open = false;
        // Se actualiza después de cerrar para que el reordenamiento no se vea
        const u = Object.assign({}, usage);
        u[entry.id] = (u[entry.id] ?? 0) + 1;
        usage = u;
        usageFile.setText(JSON.stringify(u));
    }

    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher-usage.json")
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {
                root.usage = {};
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }

    PanelWindow {
        id: win

        visible: root.open
        screen: Quickshell.screens.find(s => Hyprland.monitorFor(s) === Hyprland.focusedMonitor) ?? Quickshell.screens[0]
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: Qt.rgba(0, 0, 0, 0.35)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:launcher"

        // Se reinicia al cerrar (no al abrir) para que al volver a abrir ya esté arriba
        onVisibleChanged: {
            if (visible) {
                input.forceActiveFocus();
            } else {
                input.text = "";
                list.currentIndex = 0;
                list.positionViewAtBeginning();
            }
        }

        // Clic fuera de la tarjeta = cerrar
        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }

        Rectangle {
            id: card

            anchors.horizontalCenter: parent.horizontalCenter
            // Centrado según su altura máxima (7 resultados), así el buscador
            // no se mueve al filtrar
            readonly property int maxHeight: 24 + 48 + 10 + 7 * 52
            y: Math.max(0, Math.round((parent.height - maxHeight) / 2))
            width: 600
            height: content.implicitHeight + 24
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

            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // Buscador
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: height / 2
                    color: Theme.surfaceHigh

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 12

                        Icon {
                            text: Theme.iSearch
                            color: Theme.subtext
                            font.pixelSize: 20
                        }

                        TextInput {
                            id: input
                            Layout.fillWidth: true
                            onTextChanged: {
                                root.query = text;
                                list.currentIndex = 0;
                            }
                            color: Theme.text
                            selectionColor: Theme.dot
                            font.family: Theme.font
                            font.pixelSize: 16
                            clip: true

                            Text {
                                visible: input.text === ""
                                text: "Buscar aplicaciones…"
                                color: Theme.subtext
                                font: input.font
                            }

                            Keys.onPressed: e => {
                                if (e.key === Qt.Key_Escape) {
                                    root.open = false;
                                } else if (e.key === Qt.Key_Down || (e.key === Qt.Key_Tab)) {
                                    list.incrementCurrentIndex();
                                } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) {
                                    list.decrementCurrentIndex();
                                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                    root.launch(root.results[list.currentIndex]);
                                } else {
                                    return;
                                }
                                e.accepted = true;
                            }
                        }
                    }
                }

                // Resultados
                ListView {
                    id: list

                    readonly property int rowHeight: 52

                    Layout.fillWidth: true
                    implicitHeight: Math.min(count, 7) * rowHeight
                    visible: count > 0
                    clip: true
                    model: root.results
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 120
                    keyNavigationWraps: true

                    highlight: Rectangle {
                        radius: Theme.radiusSmall
                        color: Theme.surfaceHigh
                    }

                    delegate: Item {
                        id: row
                        required property DesktopEntry modelData
                        required property int index

                        width: list.width
                        height: list.rowHeight

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 14

                            Item {
                                implicitWidth: 30
                                implicitHeight: 30

                                IconImage {
                                    id: appIcon
                                    anchors.fill: parent
                                    source: Quickshell.iconPath(row.modelData.icon, true) || Quickshell.iconPath("application-x-executable", true)
                                }
                                // Si el tema no tiene icono, muestra la inicial
                                Rectangle {
                                    anchors.fill: parent
                                    visible: appIcon.source == ""
                                    radius: 10
                                    color: Theme.surfaceHigh

                                    Label {
                                        anchors.centerIn: parent
                                        text: row.modelData.name.charAt(0).toUpperCase()
                                        color: Theme.subtext
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Label {
                                    Layout.fillWidth: true
                                    text: row.modelData.name
                                }
                                Label {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: row.modelData.comment || row.modelData.genericName
                                    color: Theme.subtext
                                    font.pixelSize: Theme.fontSize
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: list.currentIndex = row.index
                            onClicked: root.launch(row.modelData)
                        }
                    }
                }

                Label {
                    visible: list.count === 0
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 6
                    text: "Sin resultados"
                    color: Theme.subtext
                }
            }
        }
    }
}
