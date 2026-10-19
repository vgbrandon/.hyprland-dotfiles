import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.containers
import qs.components.design
import qs.services

// Mapa de una distribución de teclado: un teclado dibujado con lo que escribe cada tecla
// (normal, Mayús y AltGr). Arriba, una opción por cada distribución que tienes. Se abre
// desde el panel de teclado (icono del ojo) o con quickshell ipc call kblayout map.
// Teclado ANSI para las de EE. UU. e ISO (con la tecla < > y el Intro alto) para el resto.
OverlayWindow {
    id: win

    open: KeyboardLayout.mapOpen
    onCloseRequested: KeyboardLayout.mapOpen = false
    namespace: "quickshell:kblayout-map"
    padding: 20
    spacing: 16

    readonly property real unit: 46
    readonly property var shown: KeyboardLayout.mapLayout
    readonly property bool iso: shown !== null && shown.layout !== "us"

    // Filas: [código, nombre, ancho en teclas]
    readonly property var rows: [
        [["TLDE"], ["AE01"], ["AE02"], ["AE03"], ["AE04"], ["AE05"], ["AE06"], ["AE07"], ["AE08"], ["AE09"], ["AE10"], ["AE11"], ["AE12"], ["", "Retroceso", 2]],
        [["", "Tab", 1.5], ["AD01"], ["AD02"], ["AD03"], ["AD04"], ["AD05"], ["AD06"], ["AD07"], ["AD08"], ["AD09"], ["AD10"], ["AD11"], ["AD12"],
            iso ? ["", "Intro", 1.5] : ["BKSL", "", 1.5]],
        [["", "Bloq Mayús", 1.75], ["AC01"], ["AC02"], ["AC03"], ["AC04"], ["AC05"], ["AC06"], ["AC07"], ["AC08"], ["AC09"], ["AC10"], ["AC11"]]
            .concat(iso ? [["BKSL"], ["", "", 1.25, true]] : [["", "Intro", 2.25]]),
        (iso ? [["", "Mayús", 1.25], ["LSGT"]] : [["", "Mayús", 2.25]])
            .concat([["AB01"], ["AB02"], ["AB03"], ["AB04"], ["AB05"], ["AB06"], ["AB07"], ["AB08"], ["AB09"], ["AB10"], ["", "Mayús", 2.75]]),
        [["", "Ctrl", 1.25], ["", "Super", 1.25], ["", "Alt", 1.25], ["", "", 6.25], ["", "AltGr", 1.25], ["", "Super", 1.25], ["", "Menú", 1.25], ["", "Ctrl", 1.25]]
    ]

    // Cabecera: nombre y una opción por distribución
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Icon {
            text: Theme.iKeyboard
            font.pixelSize: 22
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Txt {
                text: win.shown ? KeyboardLayout.nameOf(win.shown) : ""
                textStyle: Design.title
            }
            Txt {
                text: win.shown ? (win.shown.variant ? `${win.shown.layout} · ${win.shown.variant}` : win.shown.layout) : ""
                textStyle: Design.caption
                color: Design.onSurfaceVariant
            }
        }
        Repeater {
            model: KeyboardLayout.layouts
            Chip {
                required property var modelData
                text: KeyboardLayout.shortOf(modelData)
                selected: win.shown !== null && modelData.layout === win.shown.layout && modelData.variant === win.shown.variant
                onClicked: KeyboardLayout.mapLayout = modelData
            }
        }
    }

    // El teclado
    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 15 * win.unit + 20
        implicitHeight: 5 * win.unit + 20
        radius: Design.radiusMd
        color: Design.surface0
        border.color: Design.outlineVariant

        Column {
            anchors.centerIn: parent
            spacing: 0

            Repeater {
                model: win.rows

                Row {
                    id: keyRow
                    required property var modelData
                    required property int index
                    spacing: 4
                    height: win.unit
                    leftPadding: 2

                    Repeater {
                        model: keyRow.modelData

                        LayoutKey {
                            required property var modelData
                            code: modelData[0]
                            label: modelData[1] ?? ""
                            units: modelData[2] ?? 1
                            ghost: modelData[3] ?? false
                            unit: win.unit
                            width: units * win.unit - 4
                            // El Intro ISO ocupa dos filas: el de arriba baja hasta la siguiente
                            height: label === "Intro" && win.iso ? 2 * win.unit - 4 : win.unit - 4
                            z: label === "Intro" ? 1 : 0
                        }
                    }
                }
            }
        }
    }

    // Leyenda
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 20
        Txt {
            text: "Arriba: con Mayús · Abajo: sola"
            textStyle: Design.caption
            color: Design.onSurfaceVariant
        }
        Txt {
            text: "En color: con AltGr (arriba, AltGr + Mayús)"
            textStyle: Design.caption
            color: Design.accent
        }
        Txt {
            text: Object.keys(KeyboardLayout.mapKeys).length === 0 ? "Cargando…" : ""
            textStyle: Design.caption
            color: Design.muted
        }
    }
}
