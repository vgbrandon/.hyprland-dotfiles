import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.containers
import qs.components.design
import qs.services

// Editor de iconos (Ajustes → Ajustar iconos): para centrar a ojo los iconos del pack
// propio (Velure Icons) en su caja. A la izquierda, los iconos en cajas como las de la barra; a la derecha, el
// elegido ampliado ×12 píxel a píxel, con la rejilla y la cruz del centro de la caja.
// Las flechas lo mueven de píxel en píxel; se guarda al momento (services/IconOffsets.qml)
// y se aplica en toda la shell a ese tamaño.
//   quickshell ipc call iconeditor toggle
OverlayWindow {
    id: win

    open: IconOffsets.editorOpen
    onCloseRequested: IconOffsets.editorOpen = false
    namespace: "quickshell:iconeditor"
    cardWidth: 860
    padding: 18
    spacing: 14
    // Centrada siempre igual: si la tarjeta se recolocara al cambiar un texto, la vista
    // ampliada saltaría y no se vería bien el paso de un píxel
    centerHeight: 620

    // Los iconos del pack propio (Velure Icons, caracteres U+100000…), sacados de Theme:
    // al añadir uno nuevo, aparece aquí solo. Se calcula una vez al crear la ventana (si
    // fuera un enlace, recorrer Theme avisaría de propiedades no enlazables).
    property var names: []
    Component.onCompleted: {
        const out = [];
        for (const key in Theme) {
            if (!/^i[A-Z]/.test(key)) continue;
            const v = Theme[key];
            if (typeof v === "string" && (v.codePointAt(0) ?? 0) >= 0x100000) out.push(key);
        }
        names = out.sort();
    }
    property string selected: "iBitwarden"
    readonly property string glyph: Theme[selected] ?? ""
    // Tamaño de los iconos de la barra (15 en la barra lateral compacta)
    property int iconSize: 16
    readonly property int box: iconSize === 16 ? 28 : 24
    readonly property var offset: IconOffsets.of(glyph, iconSize)
    readonly property int zoom: 12

    function move(dx, dy) {
        IconOffsets.set(glyph, iconSize, offset.x + dx, offset.y + dy);
    }

    onVisibleChanged: if (visible) keys.forceActiveFocus()

    Item {
        id: keys
        Layout.preferredHeight: 0
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Left) win.move(-1, 0);
            else if (e.key === Qt.Key_Right) win.move(1, 0);
            else if (e.key === Qt.Key_Up) win.move(0, -1);
            else if (e.key === Qt.Key_Down) win.move(0, 1);
            else if (e.key === Qt.Key_R) IconOffsets.set(win.glyph, win.iconSize, 0, 0);
            else if (e.key === Qt.Key_S && (e.modifiers & Qt.ControlModifier)) IconOffsets.save();
            else if (e.key === Qt.Key_Escape) IconOffsets.editorOpen = false;
            else return;
            e.accepted = true;
        }
    }

    // --- Cabecera ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Icon {
            text: Theme.iSettings
            font.pixelSize: 20
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Txt {
                text: "Ajustar iconos de Velure"
                textStyle: Design.headline
            }
            Txt {
                Layout.fillWidth: true
                // Alto fijo de dos líneas, cambie el texto o no
                Layout.preferredHeight: 2 * Design.caption.size * 1.4
                verticalAlignment: Text.AlignTop
                text: IconOffsets.dirty ? "Cambios sin guardar: se ven ya en la barra; Guardar los conserva y cerrar los descarta."
                    : "Elige un icono y muévelo con las flechas hasta que quede centrado en la cruz. Se ve al momento en la barra."
                textStyle: Design.caption
                color: Design.onSurfaceVariant
                wrapMode: Text.Wrap
            }
        }
        Segmented {
            implicitWidth: 200
            options: ["16 px", "15 px (compacta)"]
            current: win.iconSize === 16 ? 0 : 1
            follow: false
            onSelected: i => win.iconSize = i === 0 ? 16 : 15
        }
        IconBtn {
            icon: Theme.iClose
            onClicked: IconOffsets.editorOpen = false
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 20

        // --- Los iconos, en cajas como las de la barra ---
        Flow {
            Layout.preferredWidth: 380
            Layout.alignment: Qt.AlignTop
            spacing: 6

            Repeater {
                model: win.names

                Rectangle {
                    id: tile
                    required property string modelData
                    readonly property string glyph: Theme[modelData] ?? ""
                    readonly property var off: IconOffsets.of(glyph, win.iconSize)
                    readonly property bool chosen: win.selected === modelData

                    width: win.box + 8
                    height: win.box + 8
                    radius: Design.radiusSm + 2
                    color: "transparent"
                    border.width: chosen ? 2 : 0
                    border.color: Design.accent

                    IconBtn {
                        anchors.centerIn: parent
                        size: win.box
                        iconSize: win.iconSize
                        icon: tile.glyph
                        color: Design.hoverLayer
                        onClicked: win.selected = tile.modelData
                    }
                    // Marca: tiene ajuste
                    Rectangle {
                        visible: tile.off.x !== 0 || tile.off.y !== 0
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 2
                        width: 6
                        height: 6
                        radius: 3
                        color: Design.accent
                    }
                }
            }
        }

        // --- El elegido, ampliado ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: win.box * win.zoom
                implicitHeight: win.box * win.zoom

                // La caja de verdad (a tamaño real), que se amplía sin suavizar
                Rectangle {
                    id: source
                    width: win.box
                    height: win.box
                    color: Design.background
                    Rectangle {
                        anchors.fill: parent
                        radius: Design.radiusSm
                        color: Design.hoverLayer
                    }
                    IconBtn {
                        anchors.fill: parent
                        size: win.box
                        iconSize: win.iconSize
                        icon: win.glyph
                        enabled: false
                        opacity: 1
                    }
                }
                ShaderEffectSource {
                    anchors.fill: parent
                    sourceItem: source
                    hideSource: true
                    smooth: false
                    live: true
                }

                // Rejilla de píxeles y cruz del centro de la caja
                Canvas {
                    id: grid
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const z = win.zoom, n = win.box;
                        ctx.strokeStyle = "rgba(255,255,255,0.07)";
                        ctx.lineWidth = 1;
                        for (let i = 1; i < n; i++) {
                            ctx.beginPath(); ctx.moveTo(i * z + 0.5, 0); ctx.lineTo(i * z + 0.5, n * z); ctx.stroke();
                            ctx.beginPath(); ctx.moveTo(0, i * z + 0.5); ctx.lineTo(n * z, i * z + 0.5); ctx.stroke();
                        }
                        const c = Design.accent;
                        ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 0.8);
                        ctx.lineWidth = 2;
                        const m = n / 2 * z;
                        ctx.beginPath(); ctx.moveTo(m, 0); ctx.lineTo(m, n * z); ctx.stroke();
                        ctx.beginPath(); ctx.moveTo(0, m); ctx.lineTo(n * z, m); ctx.stroke();
                    }
                    Connections {
                        target: win
                        function onBoxChanged() { grid.requestPaint(); }
                    }
                }
            }

            // Nombre, ajuste y controles
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14

                ColumnLayout {
                    spacing: 0
                    Txt {
                        text: win.selected
                        textStyle: Design.label
                    }
                    Txt {
                        text: `x ${win.offset.x > 0 ? "+" : ""}${win.offset.x} px · y ${win.offset.y > 0 ? "+" : ""}${win.offset.y} px`
                        textStyle: Design.caption
                        color: Design.onSurfaceVariant
                        font.features: { "tnum": 1 }
                    }
                }
                GridLayout {
                    columns: 3
                    rowSpacing: 2
                    columnSpacing: 2
                    Item { implicitWidth: 1; implicitHeight: 1 }
                    IconBtn { icon: Theme.iArrowUp; onClicked: win.move(0, -1) }
                    Item { implicitWidth: 1; implicitHeight: 1 }
                    IconBtn { icon: Theme.iChevronLeft; onClicked: win.move(-1, 0) }
                    IconBtn { icon: Theme.iRestore; onClicked: IconOffsets.set(win.glyph, win.iconSize, 0, 0) }
                    IconBtn { icon: Theme.iChevronRight; onClicked: win.move(1, 0) }
                    Item { implicitWidth: 1; implicitHeight: 1 }
                    IconBtn { icon: Theme.iArrowDown; onClicked: win.move(0, 1) }
                    Item { implicitWidth: 1; implicitHeight: 1 }
                }
            }
            // Guardar o descartar
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                Btn {
                    kind: "outline"
                    text: "Descartar"
                    enabled: IconOffsets.dirty
                    onClicked: IconOffsets.discard()
                }
                Btn {
                    kind: "filled"
                    icon: Theme.iCheck
                    text: "Guardar"
                    enabled: IconOffsets.dirty
                    onClicked: IconOffsets.save()
                }
            }
            Txt {
                Layout.alignment: Qt.AlignHCenter
                text: "Flechas: mover 1 px · R: quitar el ajuste · Ctrl + S: guardar · Esc: cerrar"
                textStyle: Design.caption
                color: Design.muted
            }
        }
    }
}
