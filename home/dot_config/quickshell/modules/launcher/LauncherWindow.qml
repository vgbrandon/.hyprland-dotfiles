import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components.base
import qs.components.containers
import qs.services

// Ventana del lanzador (la lógica está en services/Launcher.qml)
//   quickshell ipc call launcher toggle
OverlayWindow {
    id: win

    open: Launcher.open
    onCloseRequested: Launcher.open = false
    namespace: "quickshell:launcher"
    cardWidth: 600
    cardColor: Theme.surface
    padding: 12
    spacing: 10
    // Centrada según su altura máxima (7 resultados): el buscador no se mueve al filtrar
    centerHeight: 24 + 48 + 10 + 7 * list.rowHeight

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

    // Buscador
    SearchField {
        id: input
        icon: Theme.iSearch
        placeholder: "Buscar aplicaciones…"
        onTextChanged: {
            Launcher.query = text;
            list.currentIndex = 0;
        }
        onKeyPressed: e => {
            if (e.key === Qt.Key_Escape) {
                Launcher.open = false;
            } else if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab) {
                list.incrementCurrentIndex();
            } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) {
                list.decrementCurrentIndex();
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                Launcher.launch(Launcher.results[list.currentIndex]);
            } else {
                return;
            }
            e.accepted = true;
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
        model: Launcher.results
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
                        visible: appIcon.source.toString() === ""
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
                onClicked: Launcher.launch(row.modelData)
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
