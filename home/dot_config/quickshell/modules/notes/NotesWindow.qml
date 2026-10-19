import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.containers
import qs.components.design
import qs.services

// Notas simples (Super + N), con el diseño Prisma: a la izquierda la lista con buscador
// y "nueva"; a la derecha la nota: título (renombra el archivo), el texto y borrar. Se
// guarda sola. Las notas son .txt en ~/Notas (services/Notes.qml).
//   quickshell ipc call notes toggle | create
OverlayWindow {
    id: win

    open: Notes.open
    onCloseRequested: Notes.open = false
    namespace: "quickshell:notes"
    cardWidth: 1040
    padding: 14

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(() => editor.forceActiveFocus());
        } else {
            search.text = "";
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 620
        spacing: 14

        // --- Lista ---
        ColumnLayout {
            Layout.preferredWidth: 270
            Layout.maximumWidth: 270
            Layout.fillHeight: true
            spacing: 8

            RowLayout {
                spacing: 8
                Icon {
                    Layout.leftMargin: 4
                    text: Theme.iNote
                    font.pixelSize: 20
                }
                Txt {
                    Layout.fillWidth: true
                    text: "Notas"
                    textStyle: Design.headline
                }
                IconBtn {
                    icon: Theme.iPlus
                    kind: "tonal"
                    onClicked: {
                        Notes.create();
                        title.forceActiveFocus();
                        title.selectAll();
                    }
                }
            }
            Field {
                id: search
                Layout.fillWidth: true
                icon: Theme.iSearch
                placeholder: "Buscar en las notas…"
                onTextChanged: Notes.query = text
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                model: Notes.shown

                delegate: Rectangle {
                    id: item
                    required property var modelData
                    readonly property bool active: modelData.path === Notes.current

                    width: list.width
                    height: 46
                    radius: Design.radiusSm
                    color: active ? Design.tonal : itemMouse.containsMouse ? Design.hoverLayer : "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 0
                        Txt {
                            Layout.fillWidth: true
                            text: item.modelData.title
                            color: item.active ? Design.onTonal : Design.onSurface
                        }
                        Txt {
                            Layout.fillWidth: true
                            text: Qt.locale("es_ES").toString(new Date(item.modelData.modified), "d MMM yyyy · HH:mm")
                            textStyle: Design.caption
                            color: item.active ? Design.alpha(Design.onTonal, 0.75) : Design.onSurfaceVariant
                        }
                    }
                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notes.select(item.modelData.path)
                    }
                }
            }

            Txt {
                visible: list.count === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 20
                text: Notes.notes.length === 0 ? "Aún no hay notas" : "Sin resultados"
                color: Design.onSurfaceVariant
            }
        }

        Rectangle {
            Layout.fillHeight: true
            implicitWidth: 1
            color: Design.outlineVariant
        }

        // --- Nota ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            visible: Notes.current !== ""

            RowLayout {
                spacing: 6

                // Título (= nombre del archivo; Enter o salir del campo lo renombra)
                TextInput {
                    id: title
                    Layout.fillWidth: true
                    text: Notes.currentTitle
                    color: Design.onSurface
                    selectionColor: Design.alpha(Design.accent, 0.4)
                    font.family: Design.font
                    font.pixelSize: Design.title.size
                    font.weight: Design.title.weight
                    clip: true
                    onAccepted: {
                        Notes.rename(text);
                        editor.forceActiveFocus();
                    }
                    onActiveFocusChanged: if (!activeFocus) Notes.rename(text)
                }
                IconBtn {
                    icon: Theme.iDelete
                    iconColor: confirmDelete.running ? Design.error : Design.onSurfaceVariant
                    // Segundo clic (en 3 s) = borrar (va a la papelera)
                    onClicked: {
                        if (confirmDelete.running) {
                            confirmDelete.stop();
                            Notes.remove();
                        } else {
                            confirmDelete.start();
                        }
                    }
                    Timer {
                        id: confirmDelete
                        interval: 3000
                    }
                }
            }
            Txt {
                Layout.topMargin: -6
                text: confirmDelete.running ? "Pulsa otra vez para borrarla (va a la papelera)"
                    : Notes.current.replace(Quickshell.env("HOME"), "~")
                textStyle: Design.caption
                color: confirmDelete.running ? Design.error : Design.muted
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Design.radiusMd
                color: Design.surface0
                border.color: editor.activeFocus ? Design.alpha(Design.accent, 0.5) : Design.outlineVariant

                // El texto
                Flickable {
                    id: editFlick
                    anchors.fill: parent
                    anchors.margins: 14
                    contentHeight: editor.contentHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    TextEdit {
                        id: editor
                        width: editFlick.width
                        height: Math.max(editFlick.height, contentHeight)
                        text: Notes.text
                        color: Design.onSurface
                        selectionColor: Design.alpha(Design.accent, 0.4)
                        selectedTextColor: Design.onSurface
                        font.family: Design.font
                        font.pixelSize: 14
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                        onTextChanged: if (activeFocus) Notes.edit(text)
                        // Mantiene el cursor a la vista
                        onCursorRectangleChanged: {
                            const r = cursorRectangle;
                            if (r.y < editFlick.contentY) editFlick.contentY = r.y;
                            else if (r.y + r.height > editFlick.contentY + editFlick.height)
                                editFlick.contentY = r.y + r.height - editFlick.height;
                        }
                        Text {
                            visible: editor.text === ""
                            text: "Escribe aquí…"
                            color: Design.muted
                            font: editor.font
                        }
                    }
                }
            }
        }

        // Sin nota abierta
        ColumnLayout {
            visible: Notes.current === ""
            Layout.fillWidth: true
            Layout.fillHeight: true
            Item { Layout.fillHeight: true }
            Txt {
                Layout.alignment: Qt.AlignHCenter
                text: "Crea una nota con +"
                textStyle: Design.headline
                color: Design.onSurfaceVariant
            }
            Txt {
                Layout.alignment: Qt.AlignHCenter
                text: "Se guardan como archivos de texto en ~/Notas"
                textStyle: Design.caption
                color: Design.muted
            }
            Item { Layout.fillHeight: true }
        }
    }
}
