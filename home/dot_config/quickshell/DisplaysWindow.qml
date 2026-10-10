import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Ventana del módulo de pantallas (la lógica está en Displays.qml): esquema de los
// monitores para arrastrarlos y, debajo, los ajustes del monitor elegido.
PanelWindow {
    id: win

    visible: Displays.open
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
    WlrLayershell.keyboardFocus: Displays.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:displays"

    // Clic fuera de la tarjeta = cerrar (no mientras se confirma)
    MouseArea {
        anchors.fill: parent
        onClicked: Displays.close()
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: 760
        height: content.implicitHeight + 32
        radius: Theme.radius
        color: Theme.panelBg
        border.color: Theme.surfaceHigh
        border.width: 1

        opacity: Displays.open ? 1 : 0
        scale: Displays.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        // Evita que el clic llegue al fondo
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: keys
            focus: Displays.open
            Keys.onEscapePressed: Displays.close()
        }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 14

            // --- Cabecera ---
            RowLayout {
                Layout.leftMargin: 4
                spacing: 10

                Icon {
                    text: Theme.iMonitor
                    color: Theme.primary
                    font.pixelSize: 20
                }
                Label {
                    Layout.fillWidth: true
                    text: "Pantallas"
                    font.pixelSize: 16
                }
                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    color: closeMouse.containsMouse ? Theme.surfaceHigh : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        text: Theme.iClose
                        color: Theme.subtext
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Displays.close()
                    }
                }
            }

            // --- Monitores (pestañas; también los desactivados) ---
            RowLayout {
                spacing: 6

                Repeater {
                    model: Displays.edits

                    Rectangle {
                        id: tab
                        required property var modelData
                        required property int index
                        readonly property bool selected: Displays.selected === index

                        implicitWidth: tabRow.implicitWidth + 24
                        implicitHeight: 32
                        radius: height / 2
                        color: selected ? Theme.primary : tabMouse.containsMouse ? Theme.surfaceHigh : Theme.surface

                        RowLayout {
                            id: tabRow
                            anchors.centerIn: parent
                            spacing: 6

                            Icon {
                                visible: tab.modelData.name === Displays.primary
                                text: Theme.iStar
                                color: tab.selected ? Theme.primaryFg : Theme.warning
                                font.pixelSize: 14
                            }
                            Label {
                                text: tab.modelData.name
                                color: tab.selected ? Theme.primaryFg : tab.modelData.enabled ? Theme.text : Theme.subtext
                            }
                        }
                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Displays.selected = tab.index
                        }
                    }
                }
            }

            // --- Esquema: arrastrar para colocar (se pega a los bordes al soltar) ---
            Rectangle {
                id: layoutArea

                Layout.fillWidth: true
                implicitHeight: 240
                radius: Theme.radiusSmall
                color: Theme.surface

                // Caja que ocupan los monitores encendidos y escala para que quepan
                readonly property var enabledEdits: Displays.edits.filter(e => e.enabled)
                readonly property var box: {
                    const on = enabledEdits;
                    if (on.length === 0) return { x: 0, y: 0, w: 1, h: 1 };
                    const sizes = on.map(e => Displays.logicalSize(e));
                    const minX = Math.min(...on.map(e => e.x)), minY = Math.min(...on.map(e => e.y));
                    const maxX = Math.max(...on.map((e, i) => e.x + sizes[i].w));
                    const maxY = Math.max(...on.map((e, i) => e.y + sizes[i].h));
                    return { x: minX, y: minY, w: maxX - minX, h: maxY - minY };
                }
                // Mientras se arrastra, la escala y el origen no cambian
                property var frozen: null
                readonly property var view: frozen ?? {
                    f: Math.min((width - 48) / box.w, (height - 48) / box.h),
                    x: box.x, y: box.y,
                    ox: (width - box.w * Math.min((width - 48) / box.w, (height - 48) / box.h)) / 2,
                    oy: (height - box.h * Math.min((width - 48) / box.w, (height - 48) / box.h)) / 2
                }

                Label {
                    anchors.centerIn: parent
                    visible: layoutArea.enabledEdits.length === 0
                    text: "Ningún monitor encendido"
                    color: Theme.subtext
                }

                Repeater {
                    model: Displays.edits

                    Rectangle {
                        id: mon
                        required property var modelData
                        required property int index
                        readonly property var size: Displays.logicalSize(modelData)
                        readonly property bool selected: Displays.selected === index

                        visible: modelData.enabled
                        // Posición según la edición, salvo mientras se arrastra
                        x: dragArea.drag.active ? x : layoutArea.view.ox + (modelData.x - layoutArea.view.x) * layoutArea.view.f
                        y: dragArea.drag.active ? y : layoutArea.view.oy + (modelData.y - layoutArea.view.y) * layoutArea.view.f
                        width: size.w * layoutArea.view.f
                        height: size.h * layoutArea.view.f
                        radius: Theme.radiusSmall
                        color: selected ? Theme.withAlpha(Theme.primary, 0.25) : Theme.surfaceHigh
                        border.color: selected ? Theme.primary : Theme.dot
                        border.width: selected ? 2 : 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 4
                                Icon {
                                    visible: mon.modelData.name === Displays.primary
                                    text: Theme.iStar
                                    color: Theme.warning
                                    font.pixelSize: 13
                                }
                                Label {
                                    text: mon.modelData.name
                                }
                            }
                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: `${mon.modelData.width}×${mon.modelData.height}`
                                color: Theme.subtext
                                font.pixelSize: Theme.fontSize
                            }
                        }

                        MouseArea {
                            id: dragArea

                            anchors.fill: parent
                            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            drag.target: mon
                            drag.threshold: 4
                            onPressed: {
                                Displays.selected = mon.index;
                                layoutArea.frozen = layoutArea.view;
                            }
                            onReleased: {
                                const v = layoutArea.frozen ?? layoutArea.view;
                                if (mon.x !== v.ox + (mon.modelData.x - v.x) * v.f || mon.y !== v.oy + (mon.modelData.y - v.y) * v.f) {
                                    Displays.update(mon.index, {
                                        x: Math.round((mon.x - v.ox) / v.f + v.x),
                                        y: Math.round((mon.y - v.oy) / v.f + v.y)
                                    });
                                    // Imán: ~12 px en pantalla
                                    Displays.snap(mon.index, 12 / v.f);
                                }
                                layoutArea.frozen = null;
                            }
                        }
                    }
                }
            }

            // --- Ajustes del monitor elegido ---
            ColumnLayout {
                visible: Displays.selectedEdit !== null
                Layout.fillWidth: true
                spacing: 12

                RowLayout {
                    Layout.leftMargin: 4
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label {
                            text: Displays.selectedEdit?.description ?? ""
                            font.pixelSize: 15
                        }
                        Label {
                            text: Displays.selectedEdit?.name ?? ""
                            color: Theme.subtext
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    // Principal: lo usa la pantalla de inicio de sesión
                    Rectangle {
                        id: primaryButton
                        readonly property bool isPrimary: Displays.selectedEdit?.name === Displays.primary
                        readonly property bool chosen: Displays.selectedEdit?.name === Config.primaryMonitor

                        implicitWidth: primaryRow.implicitWidth + 24
                        implicitHeight: 32
                        radius: height / 2
                        color: chosen ? Theme.primary : primaryMouse.containsMouse ? Theme.surfaceHigh : Theme.surface

                        RowLayout {
                            id: primaryRow
                            anchors.centerIn: parent
                            spacing: 6
                            Icon {
                                text: primaryButton.isPrimary ? Theme.iStar : Theme.iStarOutline
                                color: primaryButton.chosen ? Theme.primaryFg : primaryButton.isPrimary ? Theme.warning : Theme.subtext
                                font.pixelSize: 15
                            }
                            Label {
                                text: primaryButton.chosen ? "Principal" : primaryButton.isPrimary ? "Principal (automático)" : "Hacer principal"
                                color: primaryButton.chosen ? Theme.primaryFg : Theme.text
                            }
                        }
                        MouseArea {
                            id: primaryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            // Clic en el elegido = volver a automático
                            onClicked: Config.setPrimaryMonitor(primaryButton.chosen ? "" : Displays.selectedEdit.name)
                        }
                    }

                    Label {
                        text: "Activado"
                    }
                    Switch {
                        checked: Displays.selectedEdit?.enabled ?? false
                        onToggled: Displays.update(Displays.selected, { enabled: !Displays.selectedEdit.enabled })
                    }
                }

                // Resolución y frecuencia: flechas para cambiar
                RowLayout {
                    enabled: Displays.selectedEdit?.enabled ?? false
                    opacity: enabled ? 1 : 0.4
                    spacing: 12

                    Cycler {
                        Layout.fillWidth: true
                        label: "Resolución"
                        readonly property var list: Displays.selectedEdit ? Displays.resolutions(Displays.selectedEdit) : []
                        readonly property string value: Displays.selectedEdit ? `${Displays.selectedEdit.width}x${Displays.selectedEdit.height}` : ""
                        text: value.replace("x", " × ")
                        onStep: d => {
                            const n = list.indexOf(value);
                            const next = list[Math.max(0, Math.min(list.length - 1, n + d))];
                            if (!next || next === value) return;
                            const [w, h] = next.split("x").map(Number);
                            // La frecuencia más alta de esa resolución
                            const r = Displays.rates(Displays.selectedEdit, next)[0];
                            Displays.update(Displays.selected, { width: w, height: h, rate: r });
                        }
                    }
                    Cycler {
                        Layout.fillWidth: true
                        label: "Frecuencia"
                        readonly property var list: Displays.selectedEdit ? Displays.rates(Displays.selectedEdit, `${Displays.selectedEdit.width}x${Displays.selectedEdit.height}`) : []
                        text: Displays.selectedEdit ? `${Number(Displays.selectedEdit.rate).toFixed(2)} Hz` : ""
                        onStep: d => {
                            const n = list.indexOf(Displays.selectedEdit.rate);
                            const next = list[Math.max(0, Math.min(list.length - 1, n + d))];
                            if (next && next !== Displays.selectedEdit.rate) Displays.update(Displays.selected, { rate: next });
                        }
                    }
                }

                // Escala, rotación y VRR
                RowLayout {
                    enabled: Displays.selectedEdit?.enabled ?? false
                    opacity: enabled ? 1 : 0.4
                    spacing: 18

                    Chips {
                        label: "Escala"
                        options: [1, 1.25, 1.5, 1.75, 2]
                        format: v => `${Math.round(v * 100)} %`
                        value: Displays.selectedEdit?.scale ?? 1
                        onPicked: v => Displays.update(Displays.selected, { scale: v })
                    }
                    Chips {
                        label: "Rotación"
                        options: [0, 1, 2, 3]
                        format: v => `${v * 90}°`
                        value: Displays.selectedEdit?.transform ?? 0
                        onPicked: v => {
                            Displays.update(Displays.selected, { transform: v });
                            Displays.normalize();
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: "VRR"
                    }
                    Switch {
                        checked: Displays.selectedEdit?.vrr ?? false
                        onToggled: Displays.update(Displays.selected, { vrr: !Displays.selectedEdit.vrr })
                    }
                }
            }

            // --- Pie: descartar / aplicar ---
            RowLayout {
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    text: !Displays.edits.some(e => e.enabled) ? "Deja al menos un monitor encendido"
                        : Displays.dirty ? "Cambios sin aplicar" : "La estrella marca el monitor principal (pantalla de inicio de sesión)"
                    color: !Displays.edits.some(e => e.enabled) ? Theme.error : Theme.subtext
                    font.pixelSize: Theme.fontSize
                }
                Button {
                    visible: Displays.dirty
                    text: "Descartar"
                    onClicked: Displays.discard()
                }
                Button {
                    text: "Aplicar"
                    accent: true
                    enabled: Displays.dirty && Displays.edits.some(e => e.enabled)
                    onClicked: Displays.apply()
                }
            }
        }

        // --- Confirmación tras aplicar (vuelve atrás sola si no se responde) ---
        Rectangle {
            anchors.fill: parent
            visible: Displays.confirming
            radius: Theme.radius
            color: Theme.withAlpha(Theme.panelBg, 0.94)

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 14

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "¿Mantener esta configuración?"
                    font.pixelSize: 18
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: `Se volverá a la anterior en ${Displays.countdown} s`
                    color: Theme.subtext
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Button {
                        text: "Revertir"
                        onClicked: Displays.revert()
                    }
                    Button {
                        text: "Mantener"
                        accent: true
                        onClicked: Displays.keep()
                    }
                }
            }
        }
    }

    // --- Pequeños componentes de esta ventana ---

    // Botón de texto (accent = color principal)
    component Button: Rectangle {
        id: button
        property string text
        property bool accent: false
        signal clicked()

        implicitWidth: buttonLabel.implicitWidth + 32
        implicitHeight: 36
        radius: height / 2
        opacity: enabled ? 1 : 0.4
        color: accent ? (buttonMouse.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary)
            : buttonMouse.containsMouse ? Theme.surfaceHigh : Theme.surface

        Label {
            id: buttonLabel
            anchors.centerIn: parent
            text: button.text
            color: button.accent ? Theme.primaryFg : Theme.text
        }
        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (button.enabled) button.clicked()
        }
    }

    // Valor con flechas a los lados (‹ 1920 × 1080 ›)
    component Cycler: ColumnLayout {
        id: cycler
        property string label
        property string text
        signal step(int d)

        spacing: 4

        Label {
            Layout.leftMargin: 4
            text: cycler.label
            color: Theme.subtext
            font.pixelSize: Theme.fontSize
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 38
            radius: height / 2
            color: Theme.surface

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6

                Repeater {
                    model: [-1, 0, 1]

                    Item {
                        id: slot
                        required property int modelData

                        Layout.fillWidth: modelData === 0
                        implicitWidth: modelData === 0 ? valueLabel.implicitWidth : 28
                        implicitHeight: 28

                        Label {
                            id: valueLabel
                            anchors.centerIn: parent
                            visible: slot.modelData === 0
                            text: cycler.text
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: slot.modelData !== 0
                            radius: 14
                            color: arrowMouse.containsMouse ? Theme.surfaceHigh : "transparent"

                            Icon {
                                anchors.centerIn: parent
                                text: slot.modelData < 0 ? Theme.iChevronLeft : Theme.iChevronRight
                                color: Theme.subtext
                            }
                            MouseArea {
                                id: arrowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                // Izquierda = mayor (las listas van de mayor a menor)
                                onClicked: cycler.step(slot.modelData < 0 ? -1 : 1)
                            }
                        }
                    }
                }
            }
        }
    }

    // Fila de opciones (la elegida resaltada)
    component Chips: ColumnLayout {
        id: chips
        property string label
        property var options: []
        property var format: v => String(v)
        property var value
        signal picked(var v)

        spacing: 4

        Label {
            Layout.leftMargin: 4
            text: chips.label
            color: Theme.subtext
            font.pixelSize: Theme.fontSize
        }
        Row {
            spacing: 4

            Repeater {
                model: chips.options

                Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool on: Math.abs(Number(chips.value) - Number(modelData)) < 0.001

                    width: chipLabel.implicitWidth + 20
                    height: 32
                    radius: height / 2
                    color: on ? Theme.primary : chipMouse.containsMouse ? Theme.surfaceHigh : Theme.surface

                    Label {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: chips.format(chip.modelData)
                        color: chip.on ? Theme.primaryFg : Theme.text
                    }
                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: chips.picked(chip.modelData)
                    }
                }
            }
        }
    }
}
