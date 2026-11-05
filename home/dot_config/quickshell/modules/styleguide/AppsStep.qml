import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.palettes
import qs.services

// Paso de la guía de estilo: Velure fuera de la shell. Cada app con su plantilla
// (~/.config/velure/templates), una vista previa pintada con los colores de ahora y los
// papeles que usa; al final, la tabla de qué papel usa cada app, sacada de las
// plantillas mismas (scripts/template-roles.py).
GuideStep {
    id: step
    title: "Aplicado a las apps"
    subtitle: "paleta rellena las plantillas de ~/.config/velure con los mismos papeles que la shell, así que las apps cambian con el fondo. Sin colores ANSI de por medio: la terminal usa los estados y los acentos, y el código, solo colores del fondo."

    property bool active: false

    function c(role) {
        return Theme.scheme[role.startsWith("term_") ? role : "p_" + role] ?? "#808080";
    }

    // --- Qué papeles usa cada plantilla ---
    property var usage: []
    onActiveChanged: if (active) rolesProc.running = true
    Process {
        id: rolesProc
        command: ["python3", "-I", Quickshell.shellPath("scripts/template-roles.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    step.usage = JSON.parse(this.text).apps;
                } catch (e) {}
            }
        }
    }
    // Las apps en el orden de la tabla y las que aún usan los nombres de Material
    readonly property var matrixApps: ["kitty", "fish", "Starship", "Zed", "GTK", "Iconos", "Firefox", "fastfetch"]
        .map(n => usage.find(a => a.app === n)).filter(a => a)
    readonly property var legacyApps: usage.filter(a => !Object.keys(a.roles).some(r => r.startsWith("p_")))
    readonly property var groups: [
        { name: "Neutros", roles: ["background", "surface0", "surface1", "surface2", "surface3", "outlineVariant", "outline", "subtext", "text"] },
        { name: "El tono", roles: ["accent", "onAccent", "accentDeep", "accent2", "accent3", "hi", "container", "onContainer"] },
        { name: "Estados", roles: ["error", "warning", "success", "info"] },
        { name: "Del fondo (código)", roles: ["extra1", "extra2", "extra3"] },
        { name: "Terminal", roles: ["term_red", "term_yellow", "term_green", "term_blue", "term_magenta", "term_cyan"] }
    ]
    // Columnas de la tabla
    readonly property int labelW: 260
    readonly property real colW: matrixApps.length ? (matrix.width - labelW) / matrixApps.length : 100
    function uses(app, role) {
        if (role.startsWith("term_")) return (app.roles[role] ?? 0) + (app.roles[role + "_bright"] ?? 0);
        return app.roles["p_" + role] ?? 0;
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 14
        rowSpacing: 14
        uniformCellWidths: true

        // ============ Terminal: kitty + fish + Starship ============
        AppCard {
            name: "Terminal"
            file: "kitty.conf · fish-colors.fish · starship-palette.toml"
            roles: [
                ["background", "fondo"], ["text", "texto"], ["accent", "cursor, órdenes, carpeta"],
                ["accent2", "enlaces, comillas"], ["accent3", "operadores, git"],
                ["container", "selección, pestaña"], ["outline", "sugerencia, duración"],
                ["error", "error"], ["success", "prompt ok"]
            ]

            Rectangle {
                implicitHeight: term.implicitHeight
                radius: Design.corner(8)
                color: step.c("background")
                border.color: step.c("outlineVariant")
                clip: true
                ColumnLayout {
                    id: term
                    width: parent.width
                    spacing: 0
                    // Pestañas de kitty
                    Row {
                        Layout.margins: 6
                        spacing: 4
                        Rectangle {
                            width: 70; height: 22; radius: Design.corner(4)
                            color: step.c("container")
                            GuideText { anchors.centerIn: parent; text: "fish"; size: 11; color: step.c("onContainer") }
                        }
                        Rectangle {
                            width: 70; height: 22; radius: Design.corner(4)
                            color: step.c("surface1")
                            GuideText { anchors.centerIn: parent; text: "nvim"; size: 11; color: step.c("subtext") }
                        }
                    }
                    Code {
                        Layout.leftMargin: 12
                        Layout.bottomMargin: 8
                        lines: [
                            [["accent", "~/velure "], ["outline", "on "], ["accent", " main "], ["accent3", "[!2] "], ["outline", "took 3s"]],
                            [["success", "❯ "], ["accent", "git"], ["text", " commit -m "], ["accent2", "\"feat: velure\""], ["accent3", " && "], ["accent", "ls"], ["text", " -la"]],
                            [["success", "❯ "], ["error", "gti"], ["outline", " status"]],
                            [["text", "Abrir "], ["accent2", "https://velure.dev"], ["text", "  "], ["onContainer", " seleccionado ", "container"], ["accent", "█"]]
                        ]
                    }
                    // Los 16 colores: normal arriba, brillante abajo
                    Grid {
                        Layout.leftMargin: 12
                        Layout.bottomMargin: 12
                        columns: 8
                        spacing: 3
                        Repeater {
                            model: ["surface3", "term_red", "term_green", "term_yellow", "term_blue", "term_magenta", "term_cyan", "subtext",
                                "outline", "term_red_bright", "term_green_bright", "term_yellow_bright", "term_blue_bright", "term_magenta_bright", "term_cyan_bright", "text"]
                            Rectangle { width: 26; height: 14; radius: Design.corner(3); color: step.c(modelData) }
                        }
                    }
                }
            }
        }

        // ============ Zed ============
        AppCard {
            name: "Zed"
            file: "zed.json"
            roles: [
                ["accent", "palabras clave"], ["accent2", "funciones"], ["accent3", "tipos"],
                ["extra1", "cadenas"], ["extra2", "números, constantes"], ["extra3", "propiedades"],
                ["outline", "comentarios, nº de línea"], ["subtext", "puntuación"], ["surface1", "pestaña activa"]
            ]

            Rectangle {
                implicitHeight: zed.implicitHeight
                radius: Design.corner(8)
                color: step.c("background")
                border.color: step.c("outlineVariant")
                clip: true
                ColumnLayout {
                    id: zed
                    width: parent.width
                    spacing: 0
                    Row {
                        Rectangle {
                            width: 110; height: 28
                            color: step.c("surface1")
                            GuideText { anchors.centerIn: parent; text: "roles.rs"; size: 11; color: step.c("text") }
                        }
                        Rectangle {
                            width: 110; height: 28
                            color: step.c("background")
                            GuideText { anchors.centerIn: parent; text: "main.rs"; size: 11; color: step.c("subtext") }
                        }
                    }
                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: step.c("outlineVariant") }
                    Code {
                        Layout.margins: 12
                        lines: [
                            [["outline", "1  "], ["outline", "// Los extras: tonos del fondo lejos del acento"]],
                            [["outline", "2  "], ["accent", "#[inline]"]],
                            [["text", "3  "], ["accent", "pub fn "], ["accent2", "extras"], ["subtext", "("], ["text", "fondo"], ["subtext", ": &"], ["accent3", "Imagen"], ["subtext", ") -> "], ["accent3", "Vec"], ["subtext", "<"], ["accent3", "Color"], ["subtext", "> {"]],
                            [["outline", "4  "], ["accent", "    let "], ["text", "luz "], ["subtext", "= "], ["extra2", "0.76"], ["subtext", ";"]],
                            [["outline", "5  "], ["accent", "    let "], ["text", "tema "], ["subtext", "= "], ["extra1", "\"velure\""], ["subtext", ";"]],
                            [["outline", "6  "], ["text", "    fondo"], ["subtext", "."], ["extra3", "tonos"], ["subtext", "."], ["accent2", "lejos"], ["subtext", "("], ["accent3", "Some"], ["subtext", "("], ["text", "luz"], ["subtext", "), "], ["extra2", "true"], ["subtext", ")"]],
                            [["outline", "7  "], ["subtext", "}"]]
                        ]
                    }
                }
            }
        }

        // ============ GTK (Thunar) + iconos ============
        AppCard {
            name: "Thunar (GTK) e iconos"
            file: "gtk.css · gtk3-theme.css · icons-color"
            roles: [
                ["background", "ventana y contenido"], ["text", "texto"], ["outlineVariant", "bordes, barra lateral"],
                ["accent", "selección, carpetas"], ["onAccent", "texto sobre acento"], ["surface1", "menús, diálogos"],
                ["error", "destructivo"]
            ]

            Rectangle {
                implicitHeight: 196
                radius: Design.corner(8)
                color: step.c("background")
                border.color: step.c("outlineVariant")
                clip: true
                // Barra de título
                GuideText { x: 14; y: 10; text: "Imágenes — Thunar"; size: 12; color: step.c("text") }
                Rectangle { y: 34; width: parent.width; height: 1; color: step.c("outlineVariant") }
                // Barra lateral
                Column {
                    x: 8
                    y: 44
                    spacing: 2
                    Repeater {
                        model: ["Inicio", "Imágenes", "Descargas", "Papelera"]
                        Rectangle {
                            width: 116; height: 24; radius: Design.corner(4)
                            color: index === 1 ? step.c("accent") : "transparent"
                            GuideText {
                                x: 8; anchors.verticalCenter: parent.verticalCenter
                                text: modelData; size: 11
                                color: index === 1 ? step.c("onAccent") : step.c("text")
                            }
                        }
                    }
                }
                Rectangle { x: 132; y: 35; width: 1; height: parent.height - 35; color: step.c("outlineVariant") }
                // Carpetas (iconos teñidos con el acento)
                Grid {
                    x: 148
                    y: 48
                    columns: 4
                    columnSpacing: 10
                    rowSpacing: 6
                    Repeater {
                        model: ["Fondos", "Capturas", "Stickers", "2026"]
                        Column {
                            width: 64
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Theme.iFolder
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 40
                                color: step.c("accent")
                            }
                            GuideText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData; size: 10; color: step.c("text")
                            }
                        }
                    }
                }
                // Botón destructivo
                Rectangle {
                    x: parent.width - width - 12
                    y: parent.height - height - 12
                    width: 110; height: 26; radius: Design.corner(5)
                    color: step.c("error")
                    GuideText { anchors.centerIn: parent; text: "Vaciar papelera"; size: 11; color: step.c("onAccent") }
                }
            }
        }

        // ============ Firefox ============
        AppCard {
            name: "Firefox"
            file: "firefox-userChrome.css · firefox-userContent.css"
            roles: [
                ["background", "marco, barras"], ["surface1", "pestaña activa, dirección, paneles"],
                ["subtext", "otras pestañas"], ["accent", "foco (60 %), botón principal, enlaces"],
                ["container", "sugerencia elegida"], ["surface2", "botones"]
            ]

            Rectangle {
                implicitHeight: 196
                radius: Design.corner(8)
                color: step.c("background")
                border.color: step.c("outlineVariant")
                clip: true
                // Pestañas
                Row {
                    x: 8; y: 6
                    spacing: 4
                    Rectangle {
                        width: 130; height: 26; radius: Design.corner(6)
                        color: step.c("surface1")
                        GuideText { x: 10; anchors.verticalCenter: parent.verticalCenter; text: "Velure — GitHub"; size: 11; color: step.c("text") }
                    }
                    Rectangle {
                        width: 130; height: 26; radius: Design.corner(6)
                        color: "transparent"
                        GuideText { x: 10; anchors.verticalCenter: parent.verticalCenter; text: "Nueva pestaña"; size: 11; color: step.c("subtext") }
                    }
                }
                // Barra de direcciones enfocada (borde 1 px al 60 % del acento) y sus sugerencias
                Rectangle {
                    x: 8; y: 40
                    width: parent.width - 16; height: 30; radius: Design.corner(6)
                    color: step.c("surface1")
                    border.color: Design.alpha(step.c("accent"), 0.6)
                    GuideText { x: 12; anchors.verticalCenter: parent.verticalCenter; text: "velure"; size: 12; color: step.c("text") }
                }
                Rectangle {
                    x: 8; y: 74
                    width: parent.width - 16; height: 72; radius: Design.corner(6)
                    color: step.c("surface1")
                    Column {
                        x: 4; y: 4
                        spacing: 2
                        Rectangle {
                            width: parent.parent.width - 8; height: 30; radius: Design.corner(4)
                            color: step.c("container")
                            GuideText { x: 10; anchors.verticalCenter: parent.verticalCenter; text: "velure — Buscar"; size: 11; color: step.c("onContainer") }
                        }
                        Item {
                            width: parent.parent.width - 8; height: 30
                            GuideText { x: 10; anchors.verticalCenter: parent.verticalCenter; text: "github.com/vgbrandon/velure"; size: 11; color: step.c("subtext") }
                        }
                    }
                }
                // Botones del panel: principal en el acento y uno normal
                Row {
                    x: parent.width - width - 12
                    y: parent.height - height - 12
                    spacing: 6
                    Rectangle {
                        width: 80; height: 26; radius: Design.corner(5)
                        color: step.c("surface2")
                        GuideText { anchors.centerIn: parent; text: "Cancelar"; size: 11; color: step.c("text") }
                    }
                    Rectangle {
                        width: 80; height: 26; radius: Design.corner(5)
                        color: step.c("accent")
                        GuideText { anchors.centerIn: parent; text: "Guardar"; size: 11; color: step.c("onAccent") }
                    }
                }
            }
        }

        // ============ fastfetch ============
        AppCard {
            name: "fastfetch"
            file: "fastfetch.jsonc"
            roles: [["accent", "logo y claves"], ["text", "valores (el de la terminal)"]]

            Rectangle {
                implicitHeight: ff.implicitHeight + 24
                radius: Design.corner(8)
                color: step.c("background")
                border.color: step.c("outlineVariant")
                Code {
                    id: ff
                    x: 14; y: 12
                    lines: [
                        [["accent", "      /\\       "], ["accent", "vgbrandon"], ["text", "@"], ["accent", "archlinux"]],
                        [["accent", "     /  \\      "], ["accent", "OS      "], ["text", "Arch Linux"]],
                        [["accent", "    /\\   \\     "], ["accent", "WM      "], ["text", "Hyprland"]],
                        [["accent", "   /      \\    "], ["accent", "Shell   "], ["text", "fish"]],
                        [["accent", "  /   ,,   \\   "], ["accent", "Terminal"], ["text", " kitty"]],
                        [["accent", " /   |  |  -\\  "], ["accent", "Tema    "], ["text", "Velure"]],
                        [["accent", "/_-''    ''-_\\ "]]
                    ]
                }
            }
        }

        // ============ Las demás ============
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Design.corner(10)
            color: "#1a1a1e"
            border.color: "#26262c"
            ColumnLayout {
                x: 16; y: 16
                width: parent.width - 32
                spacing: 10
                GuideText { text: "Cómo leer la tabla"; size: 15; weight: Font.Medium }
                GuideText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    size: 12
                    color: "#9a9aa2"
                    text: "Debajo, cada fila es un papel de la paleta y cada columna, una app; el punto dice que la plantilla lo usa (más grande, más veces). Sale de las plantillas al abrir la guía, así que siempre está al día."
                }
                GuideText {
                    Layout.fillWidth: true
                    visible: step.legacyApps.length > 0
                    wrapMode: Text.Wrap
                    size: 12
                    color: "#d6b26e"
                    text: "Aún con los nombres de Material (primary, surface…), sin los papeles de Velure: " + step.legacyApps.map(a => a.app).join(", ") + "."
                }
            }
        }
    }

    // ============ La tabla: papel × app ============
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: matrix.implicitHeight + 28
        radius: Design.corner(10)
        color: "#1a1a1e"
        border.color: "#26262c"

        ColumnLayout {
            id: matrix
            x: 16; y: 14
            width: parent.width - 32
            spacing: 2

            // Cabecera: las apps
            RowLayout {
                spacing: 0
                Item { implicitWidth: step.labelW; implicitHeight: 26 }
                Repeater {
                    model: step.matrixApps
                    GuideText {
                        Layout.preferredWidth: step.colW
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.app
                        size: 12
                        weight: Font.Medium
                    }
                }
            }

            Repeater {
                model: step.groups
                ColumnLayout {
                    id: grp
                    required property var modelData
                    spacing: 0
                    GuideLabel { Layout.topMargin: 10; Layout.bottomMargin: 4; text: grp.modelData.name }
                    Repeater {
                        model: grp.modelData.roles
                        RowLayout {
                            id: rrow
                            required property string modelData
                            spacing: 0
                            Row {
                                Layout.preferredWidth: step.labelW
                                spacing: 8
                                Rectangle {
                                    implicitWidth: 16; implicitHeight: 16; radius: Design.corner(3)
                                    color: step.c(rrow.modelData)
                                    border.color: "#1affffff"
                                }
                                GuideText { text: rrow.modelData; size: 11; font.family: "JetBrainsMono Nerd Font" }
                                GuideText { text: step.c(rrow.modelData).toString(); size: 10; color: "#6a6a72"; font.family: "JetBrainsMono Nerd Font" }
                            }
                            Repeater {
                                model: step.matrixApps
                                Item {
                                    id: cell
                                    required property var modelData
                                    readonly property int n: step.uses(modelData, rrow.modelData)
                                    Layout.preferredWidth: step.colW
                                    implicitHeight: 22
                                    Rectangle {
                                        anchors.centerIn: parent
                                        visible: cell.n > 0
                                        width: Math.min(16, 8 + cell.n)
                                        height: width
                                        radius: width / 2
                                        color: step.c(rrow.modelData)
                                        border.color: "#26ffffff"
                                    }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        visible: cell.n === 0
                                        width: 8; height: 1
                                        color: "#33333a"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
