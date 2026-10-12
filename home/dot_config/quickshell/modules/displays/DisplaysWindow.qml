import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components.base
import qs.components.buttons
import qs.components.containers
import qs.components.controls
import qs.services

// Ventana del módulo de pantallas (la lógica está en services/Displays.qml): esquema
// de los monitores para arrastrarlos y, debajo, los ajustes del monitor elegido.
//   quickshell ipc call displays toggle
OverlayWindow {
    id: win

    open: Displays.open
    // No se cierra mientras se confirma (lo comprueba Displays.close)
    onCloseRequested: Displays.close()
    namespace: "quickshell:displays"
    focusMode: WlrKeyboardFocus.OnDemand
    cardWidth: 760

    Item {
        Layout.fillWidth: true
        implicitHeight: content.implicitHeight

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 14

            // --- Cabecera ---
            PanelHeader {
                icon: Theme.iMonitor
                iconColor: Theme.primary
                title: "Pantallas"

                CircleButton {
                    icon: Theme.iClose
                    iconColor: Theme.subtext
                    onClicked: Displays.close()
                }
            }

            // --- Monitores (pestañas; también los desactivados) ---
            RowLayout {
                spacing: 6

                Repeater {
                    model: Displays.edits

                    Chip {
                        required property var modelData
                        required property int index

                        selected: Displays.selected === index
                        icon: modelData.name === Displays.primary ? Theme.iStar : ""
                        iconColor: selected ? Theme.primaryFg : Theme.warning
                        text: modelData.name
                        textColor: selected ? Theme.primaryFg : modelData.enabled ? Theme.text : Theme.subtext
                        onClicked: Displays.selected = index
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

                    // Principal: lo usa la pantalla de inicio de sesión. Clic en el elegido = automático
                    Chip {
                        readonly property bool isPrimary: Displays.selectedEdit?.name === Displays.primary

                        selected: Displays.selectedEdit?.name === Config.primaryMonitor
                        icon: isPrimary ? Theme.iStar : Theme.iStarOutline
                        iconColor: selected ? Theme.primaryFg : isPrimary ? Theme.warning : Theme.subtext
                        text: selected ? "Principal" : isPrimary ? "Principal (automático)" : "Hacer principal"
                        onClicked: Config.setPrimaryMonitor(selected ? "" : Displays.selectedEdit.name)
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

                TextButton {
                    visible: Displays.dirty
                    text: "Descartar"
                    onClicked: Displays.discard()
                }

                TextButton {
                    text: "Aplicar"
                    accent: true
                    enabled: Displays.dirty && Displays.edits.some(e => e.enabled)
                    onClicked: Displays.apply()
                }
            }
        }

        // --- Confirmación tras aplicar (vuelve atrás sola si no se responde) ---
        // Tapa toda la tarjeta, margen incluido
        Rectangle {
            anchors.fill: parent
            anchors.margins: -16
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

                    TextButton {
                        text: "Revertir"
                        onClicked: Displays.revert()
                    }
                    TextButton {
                        text: "Mantener"
                        accent: true
                        onClicked: Displays.keep()
                    }
                }
            }
        }
    }
}
