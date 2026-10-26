import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components.base
import qs.components.design
import qs.modules.visualizer
import qs.services

// Guía de paletas: el recorrido del color de tu fondo actual, en tres pasos.
//   1. Del generador: la imagen y lo que saca de ella `paleta` (10 colores, acentos y
//      degradados, apagados, escalas clara y oscura).
//   2. El tema: cada papel (fondo, texto, acentos…) con el color del generador del que
//      sale (o «calculado»), en armonía análoga y con la regla 60-30-10.
//   3. Aplicado a Velure: los componentes reales de la shell con la paleta aplicada.
// No cambia nada de la shell.
//   quickshell ipc call paletas toggle | refresh | capture /tmp/paletas.png | scrollTo 900
FloatingWindow {
    id: win

    property bool open: false
    visible: open
    onVisibleChanged: if (!visible) open = false
    title: "Paletas"
    implicitWidth: 1280
    implicitHeight: 880
    color: "#0c0c0e"

    // Los datos (paleta roles sobre el fondo actual), compartidos con la guía de estilo
    PaletteData {
        id: pdata
        active: win.visible
    }
    readonly property var d: pdata.d
    readonly property var r: pdata.r

    // Señal de ejemplo para el visualizador del paso 3
    property var demo: []
    property real t: 0
    Timer {
        interval: 33
        repeat: true
        running: win.visible
        onTriggered: {
            win.t += 0.033;
            const n = Visualizer.bands, v = [];
            for (let i = 0; i < n; i++) {
                const x = i / n;
                const s = 0.5 + 0.5 * Math.sin(win.t * 3 + x * 9) * Math.cos(win.t * 1.7 + x * 4);
                v.push(Math.max(0, (0.25 + 0.6 * s) * (1 - x * 0.55) + 0.12 * Math.sin(win.t * 11 + i)));
            }
            win.demo = v;
        }
    }

    function refresh() {
        pdata.refresh();
    }

    IpcHandler {
        target: "paletas"
        function toggle(): void { win.open = !win.open; }
        function open(): void { win.open = true; }
        function close(): void { win.open = false; }
        function refresh(): void { win.refresh(); }
        function scrollTo(y: int): void { flick.contentY = Math.max(0, Math.min(y, flick.contentHeight - flick.height)); }
        function capture(path: string): void { page.grabToImage(res => res.saveToFile(path)); }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: page.implicitHeight + 48
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: page
            x: 32
            y: 28
            width: flick.width - 64
            spacing: 18

            // Cabecera
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    GuideText { text: "La paleta de tu fondo"; size: 30; weight: Font.Light; color: "#f2f2f2" }
                    GuideText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: "Cómo pasa el color de la imagen al escritorio: lo que saca el generador, el papel que le da el tema y cómo se ve aplicado."
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
                    GuideText { id: refreshLabel; anchors.centerIn: parent; text: pdata.running ? "Generando…" : "Volver a generar"; color: "#e6e6e6"; size: 12 }
                    MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.refresh() }
                }
            }

            GuideText {
                visible: !win.d
                text: pdata.running ? "Generando…" : "Sin datos: ¿está instalado ~/.local/bin/paleta?"
                color: "#9a9aa2"
            }

            // ============ 1 · Del generador ============
            GeneratorStep {
                number: "1"
                data: pdata
            }

            GuideArrow {
                visible: !!win.d
                text: "Se reparte en papeles: un solo tono (el «base») con sus vecinos análogos y la regla 60-30-10, con la luminosidad fijada para que todo se lea"
            }

            // ============ 2 · El tema ============
            ThemeStep {
                number: "2"
                data: pdata
            }

            GuideArrow {
                visible: !!win.r
                text: "Se aplica a la shell (Velure) y a las apps (kitty, Zed, GTK, Firefox…)"
            }

            // ============ 3 · Aplicado a Velure ============
            GuideStep {
                visible: !!win.r
                number: "3"
                title: "Aplicado a Velure"
                subtitle: "Los componentes reales de la shell (los de components/design) con la paleta aplicada ahora."

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: shellCol.implicitHeight
                    radius: 12
                    color: Design.background
                    border.color: Design.border
                    clip: true

                    ColumnLayout {
                        id: shellCol
                        width: parent.width
                        spacing: 0

                        // La barra (Mica): escritorios, reloj y estado
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 40
                            color: Design.alpha(Design.micaTint, Design.micaOpacity)
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Design.border }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 6
                                IconBtn { icon: Theme.iLogo; size: 30; iconSize: 16 }
                                Row {
                                    Layout.leftMargin: 6
                                    spacing: 6
                                    Rectangle { width: 26; height: 8; radius: 4; color: Design.hi; anchors.verticalCenter: parent.verticalCenter }
                                    Repeater {
                                        model: 2
                                        Rectangle { width: 8; height: 8; radius: 4; color: Design.onSurfaceVariant; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                }
                                Txt { Layout.leftMargin: 10; text: "Firefox — YouTube"; textStyle: Design.label; color: Design.onSurfaceVariant }
                                Item { Layout.fillWidth: true }
                                Txt { text: Qt.formatDateTime(new Date(), "hh:mm") + "  ·  " + Qt.locale("es_ES").toString(new Date(), "dddd d MMM"); textStyle: Design.label; font.features: { "tnum": 1 } }
                                Item { Layout.fillWidth: true }
                                IconBtn { icon: Theme.iWifi4; size: 30; iconSize: 16 }
                                IconBtn { icon: Theme.iBt; size: 30; iconSize: 16 }
                                IconBtn { icon: Theme.iVolume; size: 30; iconSize: 16; checked: true }
                                IconBtn { icon: Theme.iBellBadge; size: 30; iconSize: 16 }
                                IconBtn { icon: Theme.iPower; size: 30; iconSize: 16 }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.margins: 18
                            spacing: 18

                            // Panel de ajustes rápidos (acrílico)
                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                Layout.preferredWidth: 360
                                implicitHeight: quick.implicitHeight + 32
                                radius: Design.radiusMd
                                color: Design.alpha(Design.glassTint, Design.glassOpacity)
                                border.color: Design.border
                                GlassEdge { inset: Design.radiusMd }
                                ColumnLayout {
                                    id: quick
                                    x: 16
                                    y: 16
                                    width: parent.width - 32
                                    spacing: 12
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
                                        Layout.fillWidth: true
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

                            // Controles, lista y notificación
                            ColumnLayout {
                                Layout.alignment: Qt.AlignTop
                                Layout.fillWidth: true
                                spacing: 14
                                RowLayout {
                                    spacing: 8
                                    Btn { kind: "filled"; text: "Conectar"; icon: Theme.iCheck }
                                    Btn { kind: "tonal"; text: "Guardar" }
                                    Btn { kind: "outline"; text: "Cancelar" }
                                    Btn { kind: "text"; text: "Más" }
                                }
                                RowLayout {
                                    spacing: 14
                                    Toggle { checked: true }
                                    Toggle {}
                                    Check { text: "Recordar"; checked: true }
                                    Segmented { Layout.preferredWidth: 220; options: ["Día", "Semana", "Mes"]; current: 1 }
                                }
                                Field { Layout.fillWidth: true; icon: Theme.iSearch; placeholder: "Buscar aplicaciones…" }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    ListRow { icon: Theme.iWifi4; title: "Casa 5G"; subtitle: "Conectado · segura"; selected: true; Icon { text: Theme.iCheck; color: Design.accent } }
                                    ListRow { icon: Theme.iWifi3; title: "Oficina"; subtitle: "Guardada" }
                                }
                                // Notificación
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: notif.implicitHeight + 24
                                    radius: Design.radiusMd
                                    color: Design.surface1
                                    border.color: Design.border
                                    ColumnLayout {
                                        id: notif
                                        x: 12
                                        y: 12
                                        width: parent.width - 24
                                        spacing: 8
                                        RowLayout {
                                            spacing: 10
                                            Rectangle {
                                                implicitWidth: 34
                                                implicitHeight: 34
                                                radius: Design.radiusSm
                                                color: Design.accentContainer
                                                Icon { anchors.centerIn: parent; text: Theme.iGithub; color: Design.onAccentContainer; font.pixelSize: 17 }
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                RowLayout {
                                                    Txt { Layout.fillWidth: true; text: "GitHub"; textStyle: Design.label }
                                                    Txt { text: "ahora"; textStyle: Design.caption; color: Design.muted }
                                                }
                                                Txt { Layout.fillWidth: true; text: "Nuevo commit: «Paleta propia en Rust»"; color: Design.onSurfaceVariant }
                                            }
                                        }
                                    }
                                }
                            }

                            // Visualizador (con el degradado y una señal de ejemplo)
                            ColumnLayout {
                                Layout.alignment: Qt.AlignTop
                                Layout.preferredWidth: 220
                                spacing: 6
                                VisualizerView {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 200
                                    style: "wave"
                                    colorMode: "gradient"
                                    values: win.demo
                                }
                                Txt { Layout.alignment: Qt.AlignHCenter; text: "Visualizador · onda con degradado"; textStyle: Design.caption; color: Design.onSurfaceVariant }
                            }
                        }
                    }
                }
            }
        }
    }
}
