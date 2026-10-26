import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components.base
import qs.components.design
import qs.modules.palettes
import qs.services

// Guía de estilo del diseño Velure, como un recorrido (igual que la guía de paletas, con
// sus mismas piezas): lo que saca el generador del fondo, los papeles del tema con su
// token de Design, y con ellos los materiales, la letra, la forma, los componentes y los
// paneles de la shell. Los materiales y los paneles de vidrio se ven sobre una franja
// con el fondo de pantalla. Los ejemplos se pueden usar (pasar el ratón, pulsar,
// encender…). Tokens en services/Design.qml.
//   quickshell ipc call styleguide toggle
FloatingWindow {
    id: win

    visible: Design.guideOpen
    onVisibleChanged: if (!visible) Design.guideOpen = false
    title: "Guía de estilo"
    implicitWidth: 1280
    implicitHeight: 880
    color: "#0c0c0e"

    PaletteData {
        id: pdata
        active: win.visible
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: page.implicitHeight + 48
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Connections {
            target: Design
            function onGuideScroll(y) {
                flick.contentY = Math.max(0, Math.min(y, flick.contentHeight - flick.height));
            }
            function onGuideCapture(path) {
                flick.grabToImage(r => r.saveToFile(path));
            }
        }

        ColumnLayout {
            id: page
            x: 32
            y: 28
            width: flick.width - 64
            spacing: 18

            // --- Cabecera ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    GuideText { text: "Velure"; size: 30; weight: Font.Light; color: "#f2f2f2" }
                    GuideText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: "La guía de estilo: cómo el color de tu fondo se convierte en el diseño. Lo que saca el generador, el papel que le da el tema y, con él, los materiales, la letra, la forma, los componentes y los paneles."
                        color: "#9a9aa2"
                    }
                }
                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: refreshLabel.implicitWidth + 28
                    implicitHeight: 34
                    radius: 6
                    color: refreshMouse.containsMouse ? "#2a2a30" : "#1e1e22"
                    border.color: "#33333a"
                    GuideText { id: refreshLabel; anchors.centerIn: parent; text: pdata.running ? "Generando…" : "Volver a generar"; size: 12 }
                    MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pdata.refresh() }
                }
            }

            GuideText {
                visible: !pdata.d
                text: pdata.running ? "Generando…" : "Sin datos: ¿está instalado ~/.local/bin/paleta?"
                color: "#9a9aa2"
            }

            // ============ 1 · Del generador ============
            GeneratorStep {
                number: "1"
                data: pdata
            }

            GuideArrow {
                visible: !!pdata.d
                text: "Se reparte en papeles: un solo tono (el «base») con sus vecinos análogos y la regla 60-30-10, con la luminosidad fijada para que todo se lea"
            }

            // ============ 2 · El tema ============
            ThemeStep {
                number: "2"
                data: pdata
                tokens: true
            }

            GuideArrow {
                text: "Cada papel es un token de Design (services/Design.qml), lo único que usa la shell para el color. Con ellos se definen los materiales, la letra y la forma"
            }

            // --- Materiales ---
            GuideStep {
                number: "3"
                title: "Materiales"
                subtitle: "Transparencia de Windows 11, casi opaca: Mica para la barra y los fondos grandes y acrílico para lo que flota, con canto especular arriba. Sólido para el contenido."

                Stage {
                    id: matStage
                RowLayout {
                    spacing: 20
                    Repeater {
                        model: [
                            { m: "mica", t: "Mica", d: "Barra · fondos grandes" },
                            { m: "glass", t: "Acrílico", d: "Paneles · menús · avisos" },
                            { m: "solid", t: "Sólido", d: "Tarjetas · contenido" }
                        ]
                        Surface {
                            id: matSurf
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 150
                            material: modelData.m
                            backdrop: matStage.wall
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
            }

            // --- Tipografía ---
            GuideStep {
                number: "4"
                title: "Tipografía"
                subtitle: "Adwaita Sans (basada en Inter), con una escala fija: títulos ligeros y grandes, texto en blanco roto y lo secundario en gris suave. Los números usan cifras tabulares para que no bailen al cambiar."

                Repeater {
                    model: [
                        { s: Design.display, n: "Display · 38 · ligera", t: "Buenos días" },
                        { s: Design.title, n: "Título · 24 · ligera", t: "Ajustes rápidos" },
                        { s: Design.headline, n: "Encabezado · 15 · media", t: "Wi-Fi y Bluetooth" },
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
            GuideStep {
                number: "5"
                title: "Forma, espacio y elevación"
                subtitle: "Esquinas contenidas (6 en elementos, 10 en paneles), espacios en múltiplos de 4 y sombras amplias y suaves solo en lo que flota."

                RowLayout {
                    spacing: 16
                    Repeater {
                        model: [{ r: Design.radiusXs, n: Design.radiusXs }, { r: Design.radiusSm, n: Design.radiusSm }, { r: Design.radiusMd, n: Design.radiusMd }, { r: Design.radiusLg, n: Design.radiusLg }]
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

            GuideArrow {
                text: "Con los tokens se construyen los componentes de components/design: los mismos en toda la shell"
            }

            // --- Botones ---
            GuideStep {
                number: "6"
                title: "Botones"
                subtitle: "El acento liso, sin resplandor, para la acción principal, vidrio elevado para las demás, con borde o solo texto para lo secundario. Al pasar el ratón, una capa de estado; al pulsar, se hunden un poco."

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
            GuideStep {
                number: "7"
                title: "Controles"
                subtitle: "Interruptores y deslizadores finos, lo lleno en el acento; todo se desliza suave, sin rebotes; los campos se hunden y, al enfocarse, el borde pasa a acento (sin halo)."

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

            GuideArrow {
                text: "Juntos forman los paneles de la shell (Velure)"
            }

            // --- Ejemplos completos ---
            GuideStep {
                number: "8"
                title: "Aplicado a la shell"
                subtitle: "Los componentes juntos en paneles de vidrio sobre tu fondo de pantalla: una lista, los ajustes rápidos, una notificación y el aviso de volumen."

                Stage {
                    id: exStage
            RowLayout {
                Layout.fillWidth: true
                spacing: 24

                // Lista
                GlassCard {
                    backdrop: exStage.wall
                    scrollY: flick.contentY
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 340
                    heading: "Listas y selección"
                    note: "Lo seleccionado, en un velo blanco discreto."

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
                        backdrop: exStage.wall
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
                            backdrop: exStage.wall
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
                            backdrop: exStage.wall
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
