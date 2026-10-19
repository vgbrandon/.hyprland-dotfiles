import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.containers
import qs.components.design
import qs.services

// Ventana de atajos (Super + F1): los de Hyprland agrupados, con buscador. Se leen en
// vivo al abrir, así que un atajo nuevo en hyprland.lua (con su descripción) sale solo.
// Lógica en services/Shortcuts.qml.
OverlayWindow {
    id: win

    open: Shortcuts.open
    onCloseRequested: Shortcuts.open = false
    namespace: "quickshell:shortcuts"
    cardWidth: 820
    padding: 16
    spacing: 12

    readonly property var icons: ({
        Aplicaciones: Theme.iList, Herramientas: Theme.iPicker, Sistema: Theme.iPower,
        Ventanas: Theme.iWindow, Escritorios: Theme.iMonitor, Multimedia: Theme.iMusic
    })

    // Grupos filtrados por la búsqueda (en la descripción, el grupo o las teclas)
    readonly property var shown: {
        const q = search.text.trim().toLowerCase();
        if (q === "") return Shortcuts.groups;
        return Shortcuts.groups.map(g => ({
            name: g.name,
            items: g.items.filter(it => (g.name + " " + it.text + " " + it.combos.map(c => c.join(" ")).join(" ")).toLowerCase().includes(q))
        })).filter(g => g.items.length > 0);
    }

    onVisibleChanged: {
        if (visible) search.focusInput();
        else search.text = "";
    }

    // --- Cabecera y buscador ---
    RowLayout {
        spacing: 12

        Icon {
            text: Theme.iKeyboard
            font.pixelSize: 22
        }
        Label {
            text: "Atajos de teclado"
            font.pixelSize: 17
        }
        Field {
            id: search
            big: true
            Layout.fillWidth: true
            icon: Theme.iSearch
            placeholder: "Buscar un atajo…"
            onKeyPressed: e => {
                if (e.key === Qt.Key_Escape) {
                    if (search.text !== "") search.text = "";
                    else Shortcuts.open = false;
                    e.accepted = true;
                }
            }
        }
    }

    // --- Grupos en dos columnas (se desplaza si no cabe) ---
    Flickable {
        Layout.fillWidth: true
        implicitHeight: Math.min(columns.implicitHeight, win.height * 0.7)
        contentHeight: columns.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        GridLayout {
            id: columns
            width: parent.width
            columns: 2
            rowSpacing: 12
            columnSpacing: 12

            Repeater {
                model: win.shown

                Rectangle {
                    id: group
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 10
                    Layout.alignment: Qt.AlignTop
                    implicitHeight: groupColumn.implicitHeight + 20
                    radius: Theme.radiusSmall
                    color: Theme.surface

                    ColumnLayout {
                        id: groupColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        anchors.leftMargin: 14
                        anchors.rightMargin: 12
                        spacing: 6

                        RowLayout {
                            spacing: 8
                            Icon {
                                text: win.icons[group.modelData.name] ?? Theme.iKeyboard
                                color: Theme.primary
                                font.pixelSize: 15
                            }
                            Label {
                                text: group.modelData.name
                                color: Theme.primary
                                font.weight: Font.DemiBold
                            }
                        }

                        Repeater {
                            model: group.modelData.items

                            RowLayout {
                                id: row
                                required property var modelData
                                spacing: 8

                                Label {
                                    Layout.fillWidth: true
                                    text: row.modelData.text
                                    font.pixelSize: Theme.fontSize + 1
                                }
                                // Una o varias combinaciones ("o" entre ellas)
                                Repeater {
                                    model: row.modelData.combos

                                    RowLayout {
                                        id: combo
                                        required property var modelData
                                        required property int index
                                        spacing: 3

                                        Label {
                                            visible: combo.index > 0
                                            text: "o"
                                            color: Theme.subtext
                                            font.pixelSize: Theme.fontSize - 1
                                        }
                                        Repeater {
                                            model: combo.modelData

                                            Rectangle {
                                                required property string modelData
                                                implicitWidth: keyLabel.implicitWidth + 12
                                                implicitHeight: 22
                                                radius: 6
                                                color: Theme.surfaceHigh

                                                Text {
                                                    id: keyLabel
                                                    anchors.centerIn: parent
                                                    text: parent.modelData
                                                    color: Theme.text
                                                    font.family: Theme.font
                                                    font.pixelSize: Theme.fontSize - 1
                                                    font.weight: Font.DemiBold
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Label {
        visible: win.shown.length === 0
        Layout.alignment: Qt.AlignHCenter
        Layout.margins: 20
        text: Shortcuts.groups.length === 0 ? "Cargando…" : "Ningún atajo coincide"
        color: Theme.subtext
    }
}
