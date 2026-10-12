import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Ventana del historial del portapapeles (ver Clipboard.qml). Mismo estilo que el lanzador.
//   Enter / clic = pegar · Shift+Enter / clic derecho = solo copiar · Supr = borrar · Esc = cerrar
PanelWindow {
    id: win

    visible: Clipboard.open
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
    WlrLayershell.namespace: "quickshell:clipboard"

    // Se reinicia al cerrar para que al volver a abrir ya esté arriba
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
        onClicked: Clipboard.open = false
    }

    Rectangle {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        // Centrado según su altura máxima, así el buscador no se mueve al filtrar
        readonly property int maxHeight: 24 + 48 + 10 + list.maxHeight + 10 + 32
        y: Math.max(0, Math.round((parent.height - maxHeight) / 2))
        width: 640
        height: content.implicitHeight + 24
        radius: Theme.radius
        color: Theme.surface
        border.color: Theme.surfaceHigh
        border.width: 1

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
                        text: Theme.iClipboard
                        color: Theme.subtext
                        font.pixelSize: 20
                    }

                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        onTextChanged: {
                            Clipboard.query = text;
                            list.currentIndex = 0;
                        }
                        color: Theme.text
                        selectionColor: Theme.dot
                        font.family: Theme.font
                        font.pixelSize: 16
                        clip: true

                        Text {
                            visible: input.text === ""
                            text: "Buscar en el portapapeles…"
                            color: Theme.subtext
                            font: input.font
                        }

                        Keys.onPressed: e => {
                            const entry = Clipboard.results[list.currentIndex];
                            if (e.key === Qt.Key_Escape) {
                                Clipboard.open = false;
                            } else if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab) {
                                list.incrementCurrentIndex();
                            } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) {
                                list.decrementCurrentIndex();
                            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                Clipboard.choose(entry, !(e.modifiers & Qt.ShiftModifier));
                            } else if (e.key === Qt.Key_Delete && entry) {
                                Clipboard.remove(entry);
                            } else {
                                return;
                            }
                            e.accepted = true;
                        }
                    }
                }
            }

            // Entradas
            ListView {
                id: list

                readonly property int maxHeight: 440

                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight, maxHeight)
                visible: count > 0
                clip: true
                spacing: 2
                model: Clipboard.results
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 120
                keyNavigationWraps: true

                highlight: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.surfaceHigh
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index

                    width: list.width
                    height: modelData.image ? 96 : Math.max(44, textLabel.implicitHeight + 20)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 10
                        spacing: 12

                        // Texto: hasta 2 líneas
                        Label {
                            id: textLabel
                            visible: !row.modelData.image
                            Layout.fillWidth: true
                            text: row.modelData.text
                            wrapMode: Text.WrapAnywhere
                            maximumLineCount: 2
                            textFormat: Text.PlainText
                            font.pixelSize: Theme.fontSize + 1
                        }

                        // Imagen: miniatura y tamaño
                        Rectangle {
                            visible: row.modelData.image
                            Layout.preferredWidth: 136
                            Layout.preferredHeight: 76
                            radius: 8
                            color: Theme.surfaceHigh
                            clip: true

                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: row.modelData.image && Clipboard.thumbsRev > 0
                                    ? `file://${Clipboard.thumbDir}/${row.modelData.id}` : ""
                                sourceSize.width: 272
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                cache: false
                            }
                        }
                        ColumnLayout {
                            visible: row.modelData.image
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: "Imagen"
                            }
                            Label {
                                text: row.modelData.info
                                color: Theme.subtext
                                font.pixelSize: Theme.fontSize
                            }
                        }

                        // Borrar (al pasar el ratón o en la seleccionada)
                        Rectangle {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: 14
                            opacity: rowMouse.containsMouse || delMouse.containsMouse ? 1 : 0
                            color: delMouse.containsMouse ? Theme.error : "transparent"

                            Icon {
                                anchors.centerIn: parent
                                text: Theme.iClose
                                font.pixelSize: 14
                                color: delMouse.containsMouse ? Theme.panelBg : Theme.subtext
                            }
                            MouseArea {
                                id: delMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Clipboard.remove(row.modelData)
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        z: -1
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = row.index
                        onClicked: e => Clipboard.choose(row.modelData, e.button === Qt.LeftButton)
                    }
                }
            }

            Label {
                visible: list.count === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                text: !Clipboard.available ? "Falta instalar cliphist"
                    : Clipboard.entries.length === 0 ? "El portapapeles está vacío" : "Sin resultados"
                color: Theme.subtext
            }

            // Pie: ayuda y borrar todo
            RowLayout {
                Layout.leftMargin: 8
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    text: "Enter: pegar  ·  Shift+Enter: copiar  ·  Supr: borrar"
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                }
                Rectangle {
                    implicitWidth: clearLabel.implicitWidth + 24
                    implicitHeight: 30
                    radius: height / 2
                    opacity: Clipboard.entries.length > 0 ? 1 : 0.4
                    color: clearMouse.containsMouse && Clipboard.entries.length > 0 ? Theme.surfaceHigh : "transparent"

                    Label {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Borrar todo"
                        font.pixelSize: Theme.fontSize
                    }
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Clipboard.entries.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (Clipboard.entries.length > 0) Clipboard.clear()
                    }
                }
            }
        }
    }
}
