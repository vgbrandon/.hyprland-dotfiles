import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components.base
import qs.components.containers
import qs.components.design
import qs.services

// Lanzador como paleta de comandos (diseño Prisma): buscador y una lista con las
// aplicaciones y las acciones de la shell, cada acción con su atajo a la derecha. La
// lógica está en services/Launcher.qml.
//   Flechas, Tab o Ctrl + j/k (n/p) = moverse; Enter = abrir o hacer; Esc = cerrar
//   quickshell ipc call launcher toggle
OverlayWindow {
    id: win

    open: Launcher.open
    onCloseRequested: Launcher.open = false
    namespace: "quickshell:launcher"
    cardWidth: 720
    padding: 10
    spacing: 6
    // Centrada según su altura máxima: el buscador no se mueve al filtrar
    centerHeight: 44 + 6 + 2 * 28 + 12 * 42 + 20

    // Se reinicia al cerrar (no al abrir) para que al volver a abrir ya esté arriba
    onVisibleChanged: {
        if (visible) {
            input.focusInput();
        } else {
            input.text = "";
            list.currentIndex = firstSelectable();
        }
    }

    // Moverse saltando los títulos de grupo
    function firstSelectable() {
        return Launcher.items.findIndex(i => i.kind !== "header");
    }
    function step(d) {
        const items = Launcher.items;
        if (items.length === 0) return;
        let i = list.currentIndex;
        for (let n = 0; n < items.length; n++) {
            i = (i + d + items.length) % items.length;
            if (items[i].kind !== "header") {
                list.currentIndex = i;
                return;
            }
        }
    }

    // Buscador
    Field {
        id: input
        big: true
        Layout.fillWidth: true
        icon: Theme.iSearch
        placeholder: "Escribe una aplicación o una acción…"
        onTextChanged: Launcher.query = text
        onKeyPressed: e => {
            const ctrl = e.modifiers & Qt.ControlModifier;
            if (e.key === Qt.Key_Escape) Launcher.open = false;
            else if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab || ctrl && (e.key === Qt.Key_J || e.key === Qt.Key_N)) win.step(1);
            else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab || ctrl && (e.key === Qt.Key_K || e.key === Qt.Key_P)) win.step(-1);
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) Launcher.activate(Launcher.items[list.currentIndex]);
            else return;
            e.accepted = true;
        }
    }

    // Resultados: aplicaciones y acciones, con su título de grupo
    ListView {
        id: list

        Layout.fillWidth: true
        implicitHeight: contentHeight
        visible: count > 0
        interactive: false
        model: Launcher.items
        currentIndex: 1
        // Sin recuadro móvil: cada fila pinta su fondo si está seleccionada
        highlightFollowsCurrentItem: false
        // Última posición del ratón (global). Tras cada cambio de resultados se "rearma":
        // la primera posición que llegue solo se anota (el puntero puede estar quieto
        // sobre las filas recién creadas)
        property point lastMouse: Qt.point(-2, -2)
        // Al cambiar los resultados (cada tecla): siempre la primera fila, que es el mejor
        // resultado. Solo se mueve con el teclado o el ratón.
        onModelChanged: {
            currentIndex = win.firstSelectable();
            lastMouse = Qt.point(-2, -2);
        }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool header: modelData.kind === "header"
            readonly property bool isApp: modelData.kind === "app"
            readonly property bool selected: ListView.isCurrentItem
            readonly property string hint: isApp ? "" : Launcher.hintFor(modelData.action ?? {})

            width: list.width
            height: header ? 28 : 42

            // Fondo de la seleccionada (sin animación: no parpadea al escribir)
            Rectangle {
                visible: row.selected && !row.header
                anchors.fill: parent
                radius: Design.radiusSm
                color: Design.tonal
            }

            // Título de grupo
            Txt {
                visible: row.header
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: 10
                anchors.bottomMargin: 4
                text: row.modelData.title ?? ""
                textStyle: Design.caption
                color: Design.onSurfaceVariant
            }

            RowLayout {
                visible: !row.header
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: 12

                // Icono: el de la app, o el de la acción en un cuadrado tonal
                Item {
                    implicitWidth: 26
                    implicitHeight: 26

                    IconImage {
                        id: appIcon
                        visible: row.isApp
                        anchors.fill: parent
                        source: row.isApp ? (Quickshell.iconPath(row.modelData.entry.icon, true) || Quickshell.iconPath("application-x-executable", true)) : ""
                    }
                    Rectangle {
                        visible: !row.isApp || appIcon.source.toString() === ""
                        anchors.fill: parent
                        radius: Design.radiusSm
                        color: row.selected ? Design.alpha(Design.onTonal, 0.15) : Design.tonal

                        Icon {
                            anchors.centerIn: parent
                            visible: !row.isApp
                            text: row.modelData.action?.icon ?? ""
                            color: Design.onTonal
                            font.pixelSize: 15
                        }
                        Txt {
                            anchors.centerIn: parent
                            visible: row.isApp
                            text: (row.modelData.entry?.name ?? "").charAt(0).toUpperCase()
                            textStyle: Design.label
                            color: Design.onTonal
                        }
                    }
                }

                Txt {
                    Layout.fillWidth: true
                    text: row.isApp ? row.modelData.entry?.name ?? "" : row.modelData.action?.title ?? ""
                    color: row.selected ? Design.onTonal : Design.onSurface
                }

                // Atajo de la acción, en teclas
                Rectangle {
                    visible: row.hint !== ""
                    implicitWidth: hintText.implicitWidth + 14
                    implicitHeight: 22
                    radius: Design.radiusXs
                    color: row.selected ? Design.alpha(Design.onTonal, 0.12) : Design.surface2
                    border.color: Design.border

                    Txt {
                        id: hintText
                        anchors.centerIn: parent
                        text: row.hint
                        textStyle: Design.caption
                        color: row.selected ? Design.onTonal : Design.onSurfaceVariant
                    }
                }
                // Sin atajo: qué es (o qué hace Enter, en la seleccionada)
                Txt {
                    visible: row.hint === ""
                    text: row.selected ? (row.isApp ? "Abrir  ↵" : "Hacer  ↵") : row.isApp ? "Aplicación" : "Acción"
                    textStyle: Design.caption
                    color: row.selected ? Design.onTonal : Design.muted
                }
            }

            MouseArea {
                visible: !row.header
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                // Solo si el ratón se mueve de verdad: al escribir, las filas se recrean
                // bajo el puntero quieto y, si no, la de debajo se seleccionaría sola
                onPositionChanged: mouse => {
                    const p = mapToGlobal(mouse.x, mouse.y);
                    if (list.lastMouse.x === -2) {
                        list.lastMouse = p;
                        return;
                    }
                    if (p.x === list.lastMouse.x && p.y === list.lastMouse.y) return;
                    list.lastMouse = p;
                    if (list.currentIndex === row.index) return;
                    list.currentIndex = row.index;
                }
                onClicked: Launcher.activate(row.modelData)
            }
        }
    }

    Txt {
        visible: list.count === 0
        Layout.alignment: Qt.AlignHCenter
        Layout.margins: 12
        text: "Sin resultados"
        color: Design.onSurfaceVariant
    }
}
