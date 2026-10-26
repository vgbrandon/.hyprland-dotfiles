import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// Guía de estilo del diseño Velure: todos los tokens y los
// componentes de ejemplo juntos, sobre el fondo de pantalla, para decidir el diseño
// antes de aplicarlo. Arriba, una barra de ejemplo. Los ejemplos se pueden usar
// (pasar el ratón, pulsar, encender…). Tokens en services/Design.qml.
//   quickshell ipc call styleguide toggle
FloatingWindow {
    id: win

    visible: Design.guideOpen
    onVisibleChanged: if (!visible) Design.guideOpen = false
    title: "Guía de estilo"
    implicitWidth: 1280
    implicitHeight: 880
    color: Design.background

    // Fondo de pantalla: lo que "desenfocan" los materiales
    Image {
        id: wall
        anchors.fill: parent
        source: Theme.wallpaper !== "" ? "file://" + Theme.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 1920
    }

    // --- Barra de ejemplo (Mica, pegada al borde) ---
    Surface {
        id: bar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        material: "mica"
        backdrop: wall
        radius: 0
        bordered: false
        z: 2

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Design.border
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 4

            IconBtn { icon: Theme.iLogo; size: 28; iconSize: 16 }

            // Escritorios: el activo en contenedor tonal; con ventanas, punto
            Row {
                Layout.leftMargin: 6
                spacing: 2
                Repeater {
                    model: [{ n: 1, w: true }, { n: 2, w: true }, { n: 3, w: false }, { n: 4, w: true }, { n: 5, w: false }]

                    Rectangle {
                        id: ws
                        required property var modelData
                        required property int index
                        readonly property bool active: index === win.activeWs
                        width: active ? 40 : 28
                        height: 24
                        radius: Design.radiusSm - 2
                        color: active ? Design.tonal : wsMouse.containsMouse ? Design.hoverLayer : "transparent"
                        Behavior on width { NumberAnimation { duration: Design.normal; easing.type: Design.easing } }
                        Behavior on color { ColorAnimation { duration: Design.normal } }

                        Txt {
                            anchors.centerIn: parent
                            text: ws.modelData.n
                            textStyle: Design.label
                            color: ws.active ? Design.onTonal : ws.modelData.w ? Design.onSurface : Design.muted
                            font.features: { "tnum": 1 }
                        }
                        MouseArea {
                            id: wsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.activeWs = ws.index
                        }
                    }
                }
            }

            Txt {
                Layout.leftMargin: 12
                Layout.maximumWidth: 260
                text: "Guía de estilo — Velure"
                textStyle: Design.label
                color: Design.onSurfaceVariant
            }

            Item { Layout.fillWidth: true }

            Txt {
                text: "20:31  ·  jueves 16 oct"
                textStyle: Design.label
                font.features: { "tnum": 1 }
            }

            Item { Layout.fillWidth: true }

            IconBtn { icon: Theme.iKeyboard; size: 28; iconSize: 16 }
            IconBtn { icon: Theme.iWifi4; size: 28; iconSize: 16 }
            IconBtn { icon: Theme.iBt; size: 28; iconSize: 16 }
            IconBtn { icon: Theme.iVolume; size: 28; iconSize: 16; checked: true }
            IconBtn { icon: Theme.iBellBadge; size: 28; iconSize: 16 }
            IconBtn { icon: Theme.iSettings; size: 28; iconSize: 16 }
            IconBtn { icon: Theme.iPower; size: 28; iconSize: 16 }
        }
    }
    property int activeWs: 1

    Flickable {
        id: flick
        anchors.top: bar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        contentHeight: page.implicitHeight + 64
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Connections {
            target: Design
            function onGuideScroll(y) {
                flick.contentY = Math.max(0, Math.min(y, flick.contentHeight - flick.height));
            }
        }

        ColumnLayout {
            id: page
            x: 32
            y: 32
            width: flick.width - 64
            spacing: 24

            // --- Cabecera ---
            ColumnLayout {
                spacing: 4
                Txt {
                    text: "Velure"
                    textStyle: Design.display
                    style: Text.Raised
                    styleColor: Design.alpha("#000000", 0.25)
                }
                Txt {
                    text: "Colores tonales de Material You (de matugen) · Mica y vidrio esmerilado · detalles finos de macOS"
                    textStyle: Design.body
                    color: Design.onSurfaceVariant
                }
            }

            // --- Color ---
            Section {
                heading: "Color"
                note: "Salen de matugen. Las superficies llevan el tono del fondo; lo activo usa contenedores tonales y el acento sólido queda para lo principal."

                SwatchRow {
                    label: "Superficies"
                    swatches: [
                        { name: "background", bg: Design.background, fg: Design.onSurface },
                        { name: "surface0", bg: Design.surface0, fg: Design.onSurface },
                        { name: "surface1", bg: Design.surface1, fg: Design.onSurface },
                        { name: "surface2", bg: Design.surface2, fg: Design.onSurface },
                        { name: "surface3", bg: Design.surface3, fg: Design.onSurface }
                    ]
                }
                SwatchRow {
                    label: "Acento y tonales"
                    swatches: [
                        { name: "accent", bg: Design.accent, fg: Design.onAccent },
                        { name: "accentContainer", bg: Design.accentContainer, fg: Design.onAccentContainer },
                        { name: "tonal", bg: Design.tonal, fg: Design.onTonal },
                        { name: "outline", bg: Design.outline, fg: Design.background },
                        { name: "outlineVariant", bg: Design.outlineVariant, fg: Design.onSurface }
                    ]
                }
                SwatchRow {
                    label: "Texto y estados"
                    swatches: [
                        { name: "onSurface", bg: Design.onSurface, fg: Design.background },
                        { name: "onSurfaceVariant", bg: Design.onSurfaceVariant, fg: Design.background },
                        { name: "error", bg: Design.error, fg: Design.onError },
                        { name: "success", bg: Design.success, fg: Design.background },
                        { name: "warning", bg: Design.warning, fg: Design.background }
                    ]
                }
            }

            // --- Materiales ---
            Section {
                heading: "Materiales"
                note: "Mica para la barra y los fondos grandes (sobria, se lee con cualquier cosa detrás). Vidrio esmerilado para lo que flota. Sólido para el contenido."

                RowLayout {
                    spacing: 20
                    Repeater {
                        model: [
                            { m: "mica", t: "Mica", d: "Barra · fondos grandes" },
                            { m: "glass", t: "Vidrio", d: "Paneles · menús · avisos" },
                            { m: "solid", t: "Sólido", d: "Tarjetas · contenido" }
                        ]
                        Surface {
                            id: matSurf
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 150
                            material: modelData.m
                            backdrop: wall
                            scrollY: flick.contentY
                            elevation: modelData.m === "glass" ? 2 : modelData.m === "solid" ? 1 : 0

                            ColumnLayout {
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                anchors.margins: 16
                                spacing: 2
                                Txt { text: matSurf.modelData.t; textStyle: Design.headline }
                                Txt { text: matSurf.modelData.d; textStyle: Design.caption; color: Design.onSurfaceVariant }
                            }
                        }
                    }
                }
            }

            // --- Tipografía ---
            Section {
                heading: "Tipografía"
                note: "Adwaita Sans (basada en Inter), con una escala fija. Los números usan cifras tabulares para que no bailen al cambiar."

                Repeater {
                    model: [
                        { s: Design.display, n: "Display · 34 · ligera", t: "Buenos días" },
                        { s: Design.title, n: "Título · 22 · media", t: "Ajustes rápidos" },
                        { s: Design.headline, n: "Encabezado · 16 · seminegrita", t: "Wi-Fi y Bluetooth" },
                        { s: Design.body, n: "Cuerpo · 13 · normal", t: "El texto normal de listas, paneles y notificaciones." },
                        { s: Design.label, n: "Etiqueta · 12 · media", t: "Botones, pestañas y la barra" },
                        { s: Design.caption, n: "Leyenda · 11 · normal", t: "Subtítulos, horas y detalles secundarios" }
                    ]
                    RowLayout {
                        required property var modelData
                        spacing: 24
                        Txt {
                            Layout.preferredWidth: 200
                            text: parent.modelData.n
                            textStyle: Design.caption
                            color: Design.onSurfaceVariant
                        }
                        Txt {
                            Layout.fillWidth: true
                            text: parent.modelData.t
                            textStyle: parent.modelData.s
                        }
                    }
                }
                RowLayout {
                    spacing: 24
                    Txt {
                        Layout.preferredWidth: 200
                        text: "Números (tabulares)"
                        textStyle: Design.caption
                        color: Design.onSurfaceVariant
                    }
                    Txt {
                        text: "12:45   98%   1.024 MB   3,2 GHz"
                        textStyle: Design.headline
                        font.features: { "tnum": 1 }
                    }
                }
            }

            // --- Forma, espacio y elevación ---
            Section {
                heading: "Forma, espacio y elevación"
                note: "Radios moderados (8 en elementos, 12 en paneles), espacios en múltiplos de 4 y sombras amplias y suaves solo en lo que flota."

                RowLayout {
                    spacing: 16
                    Repeater {
                        model: [{ r: Design.radiusXs, n: "4" }, { r: Design.radiusSm, n: "8" }, { r: Design.radiusMd, n: "12" }, { r: Design.radiusLg, n: "16" }]
                        ColumnLayout {
                            required property var modelData
                            spacing: 6
                            Rectangle {
                                implicitWidth: 72
                                implicitHeight: 52
                                radius: parent.modelData.r
                                color: Design.surface2
                                border.color: Design.border
                            }
                            Txt { text: "radio " + parent.modelData.n; textStyle: Design.caption; color: Design.onSurfaceVariant }
                        }
                    }

                    Item { implicitWidth: 24 }

                    // Escala de espacios
                    ColumnLayout {
                        spacing: 4
                        Repeater {
                            model: [4, 8, 12, 16, 24, 32]
                            RowLayout {
                                required property int modelData
                                spacing: 8
                                Rectangle {
                                    implicitWidth: parent.modelData * 3
                                    implicitHeight: 6
                                    radius: 3
                                    color: Design.accent
                                    opacity: 0.8
                                }
                                Txt { text: parent.modelData; textStyle: Design.caption; color: Design.onSurfaceVariant }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Elevación
                    Repeater {
                        model: [0, 1, 2, 3]
                        Surface {
                            id: elevSurf
                            required property int modelData
                            implicitWidth: 92
                            implicitHeight: 70
                            material: "solid"
                            tint: Design.surface2
                            elevation: modelData
                            bordered: modelData > 0
                            Txt {
                                anchors.centerIn: parent
                                text: "nivel " + elevSurf.modelData
                                textStyle: Design.caption
                                color: Design.onSurfaceVariant
                            }
                        }
                    }
                }
            }

            // --- Botones ---
            Section {
                heading: "Botones"
                note: "Relleno de acento para la acción principal, tonal para las demás, con borde o solo texto para lo secundario. Al pasar el ratón y al pulsar, una capa de estado."

                RowLayout {
                    spacing: 10
                    Btn { kind: "filled"; text: "Conectar"; icon: Theme.iCheck }
                    Btn { kind: "tonal"; text: "Guardar" }
                    Btn { kind: "outline"; text: "Cancelar" }
                    Btn { kind: "text"; text: "Más opciones" }
                    Btn { kind: "tonal"; text: "Desactivado"; enabled: false }
                    Item { implicitWidth: 16 }
                    Btn { kind: "filled"; text: "Pequeño"; small: true }
                    Btn { kind: "tonal"; text: "Pequeño"; small: true; icon: Theme.iRefresh }
                }
                RowLayout {
                    spacing: 8
                    IconBtn { icon: Theme.iSettings }
                    IconBtn { icon: Theme.iBell; checked: true }
                    IconBtn { icon: Theme.iPencil; kind: "tonal" }
                    IconBtn { icon: Theme.iPlus; kind: "filled" }
                    IconBtn { icon: Theme.iDelete; enabled: false }
                    Txt {
                        Layout.leftMargin: 12
                        text: "Iconos: normal · activo · tonal · relleno · desactivado"
                        textStyle: Design.caption
                        color: Design.onSurfaceVariant
                    }
                }
            }

            // --- Controles ---
            Section {
                heading: "Controles"
                note: "Interruptores y deslizadores finos con la bola en relieve; el segmentado eleva la opción elegida; los campos se hunden y, al enfocarse, el borde pasa a acento."

                GridLayout {
                    columns: 2
                    columnSpacing: 48
                    rowSpacing: 18

                    RowLayout {
                        spacing: 14
                        Toggle { checked: true }
                        Toggle {}
                        Toggle { checked: true; enabled: false }
                        Txt { text: "Interruptores"; textStyle: Design.caption; color: Design.onSurfaceVariant }
                    }
                    RowLayout {
                        spacing: 14
                        Check { text: "Recordar"; checked: true }
                        Check { text: "Sin marcar" }
                    }
                    RowLayout {
                        spacing: 12
                        Icon { text: Theme.iVolumeMedium; color: Design.onSurfaceVariant }
                        Slide { implicitWidth: 260; value: 0.45 }
                    }
                    Segmented {
                        implicitWidth: 300
                        options: ["Día", "Semana", "Mes"]
                        current: 1
                    }
                    Item { implicitHeight: 1 }
                    Field {
                        implicitWidth: 300
                        icon: Theme.iSearch
                        placeholder: "Buscar aplicaciones…"
                    }
                    Field {
                        implicitWidth: 300
                        placeholder: "Nombre de la red"
                    }
                    // Progreso
                    ColumnLayout {
                        Layout.preferredWidth: 300
                        Layout.fillWidth: false
                        spacing: 6
                        RowLayout {
                            Txt { Layout.fillWidth: true; text: "Descargando actualizaciones"; textStyle: Design.label }
                            Txt { text: "62%"; textStyle: Design.caption; color: Design.onSurfaceVariant; font.features: { "tnum": 1 } }
                        }
                        Rectangle {
                            implicitWidth: 300
                            implicitHeight: 4
                            radius: 2
                            color: Design.surface3
                            Rectangle { width: parent.width * 0.62; height: parent.height; radius: 2; color: Design.accent }
                        }
                    }
                    // Ajuste numérico y fila con interruptor
                    ColumnLayout {
                        Layout.preferredWidth: 300
                        Layout.fillWidth: false
                        spacing: 6
                        NumberStep {
                            id: demoStep
                            label: "Enfoque"
                            unit: "min"
                            value: 25
                            step: 5
                            onChanged: v => value = Math.max(5, v)
                        }
                        ToggleRow {
                            id: demoToggle
                            text: "Sonido al terminar"
                            checked: true
                            onToggled: checked = !checked
                        }
                    }
                    // Insignias
                    RowLayout {
                        spacing: 10
                        Badge { text: "3" }
                        Badge { text: "Nuevo"; tonal: true }
                        Badge { text: "Error"; color: Design.errorContainer; fg: Design.onSurface }
                        Txt { text: "Insignias"; textStyle: Design.caption; color: Design.onSurfaceVariant }
                    }
                }
            }

            // --- Ejemplos completos ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 24

                // Lista
                Section {
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 340
                    Layout.fillWidth: false
                    heading: "Listas y selección"
                    note: "Lo seleccionado, en contenedor tonal."

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        ListRow { icon: Theme.iWifi4; title: "Casa 5G"; subtitle: "Conectado · segura"; selected: true; Icon { text: Theme.iCheck; color: Design.onTonal } }
                        ListRow { icon: Theme.iWifi3; title: "Oficina"; subtitle: "Guardada" }
                        ListRow { icon: Theme.iWifi2; title: "Cafetería"; subtitle: "Abierta" }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        ListRow { icon: Theme.iBt; title: "Bluetooth"; Toggle { checked: true } }
                        ListRow { icon: Theme.iNight; title: "Luz nocturna"; Toggle {} }
                    }
                }

                // Panel de ajustes rápidos (vidrio)
                Item {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: 380
                    implicitHeight: quick.implicitHeight + 32

                    Surface {
                        anchors.fill: parent
                        material: "glass"
                        backdrop: wall
                        scrollY: flick.contentY
                        elevation: 3
                    }
                    ColumnLayout {
                        id: quick
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

                        RowLayout {
                            spacing: 12
                            Rectangle {
                                implicitWidth: 40
                                implicitHeight: 40
                                radius: 20
                                color: Design.accentContainer
                                Txt { anchors.centerIn: parent; text: Profile.name.charAt(0).toUpperCase(); textStyle: Design.headline; color: Design.onAccentContainer }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Txt { text: Profile.name; textStyle: Design.headline }
                                Txt { text: "Ajustes rápidos"; textStyle: Design.caption; color: Design.onSurfaceVariant }
                            }
                            IconBtn { icon: Theme.iSettings }
                            IconBtn { icon: Theme.iPower }
                        }
                        GridLayout {
                            columns: 2
                            columnSpacing: 8
                            rowSpacing: 8
                            Tile { icon: Theme.iWifi4; title: "Wi-Fi"; subtitle: "Casa 5G"; checked: true }
                            Tile { icon: Theme.iBt; title: "Bluetooth"; subtitle: "Auriculares"; checked: true }
                            Tile { icon: Theme.iNight; title: "Luz nocturna"; subtitle: "Desactivada" }
                            Tile { icon: Theme.iBellOff; title: "No molestar"; subtitle: "Desactivado" }
                        }
                        RowLayout {
                            spacing: 12
                            Icon { text: Theme.iVolume; color: Design.onSurfaceVariant }
                            Slide { Layout.fillWidth: true; value: 0.6 }
                        }
                        RowLayout {
                            spacing: 12
                            Icon { text: Theme.iBrightnessHigh; color: Design.onSurfaceVariant }
                            Slide { Layout.fillWidth: true; value: 0.8 }
                        }
                    }
                }

                // Notificación (vidrio)
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true
                    spacing: 12

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: notif.implicitHeight + 28

                        Surface {
                            anchors.fill: parent
                            material: "glass"
                            backdrop: wall
                            scrollY: flick.contentY
                            elevation: 2
                        }
                        ColumnLayout {
                            id: notif
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            RowLayout {
                                spacing: 10
                                Rectangle {
                                    implicitWidth: 36
                                    implicitHeight: 36
                                    radius: Design.radiusSm
                                    color: Design.tonal
                                    Icon { anchors.centerIn: parent; text: Theme.iGithub; color: Design.onTonal; font.pixelSize: 18 }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    RowLayout {
                                        Txt { Layout.fillWidth: true; text: "GitHub"; textStyle: Design.label }
                                        Txt { text: "ahora"; textStyle: Design.caption; color: Design.muted }
                                    }
                                    Txt {
                                        Layout.fillWidth: true
                                        text: "Nuevo commit en hyprland-dotfiles: «Teclado: distribuciones»"
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                        color: Design.onSurfaceVariant
                                    }
                                }
                            }
                            RowLayout {
                                spacing: 8
                                Btn { kind: "tonal"; text: "Ver"; small: true }
                                Btn { kind: "text"; text: "Descartar"; small: true }
                            }
                        }
                    }

                    // Aviso flotante (volumen)
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 240
                        implicitHeight: 44

                        Surface {
                            anchors.fill: parent
                            material: "glass"
                            backdrop: wall
                            scrollY: flick.contentY
                            radius: Design.radiusMd
                            elevation: 2
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 16
                            spacing: 12
                            Icon { text: Theme.iVolumeMedium; font.pixelSize: 18; color: Design.onSurface }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 4
                                radius: 2
                                color: Design.surface3
                                Rectangle { width: parent.width * 0.42; height: parent.height; radius: 2; color: Design.accent }
                            }
                            Txt { text: "42%"; textStyle: Design.label; font.features: { "tnum": 1 } }
                        }
                    }
                }
            }
        }
    }

    // Una sección de la guía: tarjeta de vidrio con título, nota y el contenido
    component Section: Item {
        id: section
        property string heading
        property string note
        default property alias body: bodyCol.data

        Layout.fillWidth: true
        implicitWidth: sectionCol.implicitWidth + 44
        implicitHeight: sectionCol.implicitHeight + 44

        Surface {
            anchors.fill: parent
            material: "glass"
            backdrop: wall
            scrollY: flick.contentY
            elevation: 1
        }
        ColumnLayout {
            id: sectionCol
            anchors.fill: parent
            anchors.margins: 22
            spacing: 16

            ColumnLayout {
                spacing: 2
                Txt { text: section.heading; textStyle: Design.title }
                Txt {
                    Layout.fillWidth: true
                    text: section.note
                    wrapMode: Text.Wrap
                    color: Design.onSurfaceVariant
                }
            }
            ColumnLayout {
                id: bodyCol
                Layout.fillWidth: true
                spacing: 12
            }
        }
    }

    // Fila de muestras de color: { name, bg, fg }
    component SwatchRow: RowLayout {
        id: swatchRow
        property string label
        property var swatches: []
        spacing: 10

        Txt {
            Layout.preferredWidth: 130
            text: swatchRow.label
            textStyle: Design.caption
            color: Design.onSurfaceVariant
        }
        Repeater {
            model: swatchRow.swatches
            Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 64
                radius: Design.radiusSm
                color: modelData.bg
                border.color: Design.border

                Txt {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 10
                    text: "Aa"
                    textStyle: Design.headline
                    color: parent.modelData.fg
                }
                Txt {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 10
                    text: parent.modelData.name
                    textStyle: Design.caption
                    color: parent.modelData.fg
                    opacity: 0.85
                }
            }
        }
    }

    // Insignia: número o etiqueta corta
    component Badge: Rectangle {
        property string text
        property bool tonal: false
        property color fg: tonal ? Design.onTonal : Design.onAccent
        implicitWidth: Math.max(20, badgeText.implicitWidth + 12)
        implicitHeight: 20
        radius: 10
        color: tonal ? Design.tonal : Design.accent
        Txt {
            id: badgeText
            anchors.centerIn: parent
            text: parent.text
            textStyle: Design.caption
            font.weight: Font.DemiBold
            color: parent.fg
        }
    }
}
