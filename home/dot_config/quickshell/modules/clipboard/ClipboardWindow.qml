import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.buttons
import qs.components.containers
import qs.components.design
import qs.services

// Ventana del historial del portapapeles (la lógica está en services/Clipboard.qml).
// Mismo estilo que el lanzador.
//   Enter / clic = pegar · Shift+Enter / clic derecho = solo copiar · Supr = borrar · Esc = cerrar
OverlayWindow {
    id: win

    open: Clipboard.open
    onCloseRequested: Clipboard.open = false
    namespace: "quickshell:clipboard"
    cardWidth: 640
    cardColor: Theme.surface
    padding: 12
    spacing: 10
    // Centrada según su altura máxima: el buscador no se mueve al filtrar
    centerHeight: 24 + 48 + 10 + list.maxHeight + 10 + 32

    // Se reinicia al cerrar para que al volver a abrir ya esté arriba
    onVisibleChanged: {
        if (visible) {
            input.focusInput();
        } else {
            input.text = "";
            list.currentIndex = 0;
            list.positionViewAtBeginning();
        }
    }

    // Buscador
    Field {
        id: input
        big: true
        Layout.fillWidth: true
        icon: Theme.iClipboard
        placeholder: "Buscar en el portapapeles…"
        onTextChanged: {
            Clipboard.query = text;
            list.currentIndex = 0;
        }
        onKeyPressed: e => {
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

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onEntered: list.currentIndex = row.index
                onClicked: e => Clipboard.choose(row.modelData, e.button === Qt.LeftButton)
            }

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

                // Borrar (al pasar el ratón)
                CircleButton {
                    id: deleteButton
                    opacity: rowMouse.containsMouse || hovered ? 1 : 0
                    icon: Theme.iClose
                    size: 28
                    iconSize: 14
                    hoverColor: Theme.error
                    iconColor: hovered ? Theme.panelBg : Theme.subtext
                    onClicked: Clipboard.remove(row.modelData)
                }
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
        TextButton {
            text: "Borrar todo"
            small: true
            flat: true
            enabled: Clipboard.entries.length > 0
            onClicked: Clipboard.clear()
        }
    }
}
