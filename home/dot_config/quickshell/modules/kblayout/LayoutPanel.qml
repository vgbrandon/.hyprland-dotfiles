import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.buttons
import qs.components.containers
import qs.services

// Panel de distribuciones de teclado (icono de teclado de la barra): las que tienes,
// con la activa marcada (clic = cambiar a esa), ordenarlas (la primera es la de
// arranque), quitarlas y añadir otras con un buscador. Lógica en services/KeyboardLayout.qml.
BarPopup {
    id: panel

    padding: 14
    spacing: 10

    property bool adding: false
    onVisibleChanged: {
        adding = false;
        if (visible) KeyboardLayout.refresh();
    }
    onAddingChanged: {
        search.text = "";
        if (adding) Qt.callLater(() => search.forceActiveFocus());
    }

    // Resultados del buscador (sin las que ya están)
    readonly property var results: {
        const q = search.text.trim().toLowerCase();
        const list = KeyboardLayout.catalog.filter(c => !KeyboardLayout.has(c));
        if (q === "") return list;
        return list.filter(c => c.name.toLowerCase().includes(q) || c.layout === q || c.short === q
            || c.variant.toLowerCase().includes(q));
    }

    PanelHeader {
        icon: Theme.iKeyboard
        title: "Teclado"
        subtitle: KeyboardLayout.currentName

        // Ver la distribución activa
        CircleButton {
            icon: Theme.iEye
            size: 28
            iconSize: 16
            onClicked: {
                panel.close();
                KeyboardLayout.showMap();
            }
        }
    }

    // --- Distribuciones que tienes ---
    Repeater {
        model: KeyboardLayout.layouts

        LayoutRow {
            required property var modelData
            required property int index
            entry: modelData
            position: index
        }
    }

    // --- Añadir ---
    TextButton {
        visible: !panel.adding
        Layout.alignment: Qt.AlignHCenter
        icon: Theme.iPlus
        text: "Añadir distribución"
        small: true
        onClicked: panel.adding = true
    }

    ColumnLayout {
        visible: panel.adding
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 38
            radius: Design.radiusSm
            color: Theme.surfaceHigh
            border.color: search.activeFocus ? Theme.primary : Theme.surfaceHigh
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 6
                spacing: 10

                Icon {
                    text: Theme.iSearch
                    color: Theme.subtext
                    font.pixelSize: 16
                }
                TextInput {
                    id: search
                    Layout.fillWidth: true
                    color: Theme.text
                    selectionColor: Theme.dot
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                    clip: true
                    Keys.onEscapePressed: panel.adding = false
                    onAccepted: if (panel.results.length > 0) {
                        KeyboardLayout.add(panel.results[0]);
                        panel.adding = false;
                    }

                    Text {
                        visible: search.text === ""
                        text: "Idioma o distribución (español, latam…)"
                        color: Theme.subtext
                        font: search.font
                    }
                }
                CircleButton {
                    icon: Theme.iClose
                    size: 26
                    iconSize: 14
                    onClicked: panel.adding = false
                }
            }
        }

        ListView {
            id: resultsView
            Layout.fillWidth: true
            implicitHeight: Math.min(contentHeight, 260)
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: panel.results

            delegate: Rectangle {
                id: result
                required property var modelData
                width: resultsView.width
                implicitHeight: 34
                radius: Theme.radiusSmall
                color: resultMouse.containsMouse ? Theme.surfaceHigh : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Code {
                        text: result.modelData.short.toUpperCase()
                    }
                    Label {
                        Layout.fillWidth: true
                        text: result.modelData.name
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: resultMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        KeyboardLayout.add(result.modelData);
                        panel.adding = false;
                    }
                }
            }
        }

        Label {
            visible: panel.results.length === 0
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: 6
            text: KeyboardLayout.catalog.length === 0 ? "Cargando…" : "Sin resultados"
            color: Theme.subtext
            font.pixelSize: Theme.fontSize
        }
    }

    // Código corto de la distribución (EN, ES…)
    component Code: Rectangle {
        property alias text: codeLabel.text
        property bool active: false

        implicitWidth: Math.max(32, codeLabel.implicitWidth + 12)
        implicitHeight: 22
        radius: 6
        color: active ? Theme.primary : Theme.surfaceHigh

        Text {
            id: codeLabel
            anchors.centerIn: parent
            color: parent.active ? Theme.primaryFg : Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.DemiBold
        }
    }

    // Una distribución: código, nombre y acciones al pasar el ratón
    component LayoutRow: Rectangle {
        id: row
        required property var entry
        required property int position
        readonly property bool isActive: position === KeyboardLayout.active
        readonly property bool many: KeyboardLayout.layouts.length > 1

        Layout.fillWidth: true
        implicitHeight: 48
        radius: Theme.radiusSmall
        color: isActive ? Theme.surfaceHigh : rowMouse.containsMouse ? Theme.surface : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: row.isActive ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: if (!row.isActive) KeyboardLayout.switchTo(row.position)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 10

            Code {
                text: KeyboardLayout.shortOf(row.entry)
                active: row.isActive
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    Layout.fillWidth: true
                    text: KeyboardLayout.nameOf(row.entry)
                    elide: Text.ElideRight
                }
                Label {
                    visible: row.many && row.position === 0
                    text: "Al arrancar"
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 1
                }
            }

            // Ver, ordenar y quitar (al pasar el ratón; ordenar y quitar, solo con varias)
            Row {
                visible: rowMouse.containsMouse || eyeBtn.hovered || upBtn.hovered || downBtn.hovered || delBtn.hovered
                spacing: 2

                CircleButton {
                    id: eyeBtn
                    icon: Theme.iEye
                    size: 26
                    iconSize: 15
                    onClicked: {
                        panel.close();
                        KeyboardLayout.showMap(row.entry);
                    }
                }

                CircleButton {
                    id: upBtn
                    visible: row.many
                    icon: Theme.iChevronUp
                    size: 26
                    iconSize: 15
                    enabled: row.position > 0
                    onClicked: KeyboardLayout.move(row.position, -1)
                }
                CircleButton {
                    id: downBtn
                    visible: row.many
                    icon: Theme.iChevronDown
                    size: 26
                    iconSize: 15
                    enabled: row.position < KeyboardLayout.layouts.length - 1
                    onClicked: KeyboardLayout.move(row.position, 1)
                }
                CircleButton {
                    id: delBtn
                    visible: row.many
                    icon: Theme.iDelete
                    size: 26
                    iconSize: 14
                    iconColor: hovered ? Theme.error : Theme.subtext
                    onClicked: KeyboardLayout.remove(row.position)
                }
            }
        }
    }
}
