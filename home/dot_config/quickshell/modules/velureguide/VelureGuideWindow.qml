import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services

// Guía de velure: cómo el color de una imagen se convierte en el tema del escritorio, con
// datos reales. Por defecto, el fondo actual; se puede elegir otro fondo o cualquier
// imagen para ver qué tema daría, sin cambiar el fondo (y usarla como fondo si gusta).
// La ventana se pinta con los tokens de esa imagen. Los datos salen de `velure tokens`
// (la imagen, la armonía, los tokens) y de `velure uso` (qué usa cada app y dónde escribe).
//   quickshell ipc call guia toggle | ver /ruta.jpg | scrollTo 900 | capture /tmp/guia.png
FloatingWindow {
    id: win

    visible: Design.guideOpen
    onVisibleChanged: {
        if (!visible) {
            Design.guideOpen = false;
            return;
        }
        if (!usoProc.running && win.apps.length === 0) usoProc.running = true;
        refresh();
    }
    title: "Guía de velure"
    implicitWidth: 1320
    implicitHeight: 900
    color: win.c("crust")

    // La imagen que se explica: el fondo actual mientras no se elija otra
    readonly property string image: Design.guideImage !== "" ? Design.guideImage : Theme.wallpaper
    readonly property bool isWallpaper: image === Theme.wallpaper
    property var g: null
    property var apps: []
    property string error: ""
    readonly property var t: g ? g.tokens : ({})
    function c(name) { return t[name] ?? "#808080"; }

    onImageChanged: refresh()
    function refresh() {
        if (!visible || image === "") return;
        tokensProc.running = false;
        tokensProc.command = [Theme.velureBin, "tokens", image];
        tokensProc.running = true;
    }

    Process {
        id: tokensProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    win.g = JSON.parse(this.text);
                    win.error = "";
                } catch (e) {
                    win.error = "velure no pudo leer esta imagen";
                }
            }
        }
    }
    Process {
        id: usoProc
        command: [Theme.velureBin, "uso"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { win.apps = JSON.parse(this.text).apps; } catch (e) {}
            }
        }
    }
    // Otra imagen (zenity: ventana GTK con el tema)
    Process {
        id: filePicker
        command: ["zenity", "--file-selection", "--title=Elegir imagen",
            "--file-filter=Imágenes | *.png *.PNG *.jpg *.JPG *.jpeg *.JPEG *.webp *.WEBP *.gif *.GIF *.bmp *.tiff",
            "--file-filter=Todos | *"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim();
                if (p !== "") Design.guideImage = p;
            }
        }
    }

    Connections {
        target: Design
        function onGuideScroll(y) {
            flick.contentY = Math.max(0, Math.min(y, flick.contentHeight - flick.height));
        }
        function onGuideCapture(path) {
            page.grabToImage(r => r.saveToFile(path));
        }
    }

    // --- Color (OKLCH y contraste WCAG), para dibujar y medir con los datos reales ---
    function lin(v) { v /= 255; return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }
    function rgb(hex) { return [1, 3, 5].map(i => parseInt(hex.substr(i, 2), 16)); }
    function lum(hex) { const [r, gg, b] = rgb(hex).map(lin); return 0.2126 * r + 0.7152 * gg + 0.0722 * b; }
    function contrast(a, b) { const x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); }
    function oklch(hex) {
        const [r, gg, b] = rgb(hex).map(lin);
        const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * gg + 0.0514459929 * b);
        const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * gg + 0.1073969566 * b);
        const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * gg + 0.6299787005 * b);
        const L = 0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s;
        const A = 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s;
        const B = 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s;
        return { l: L, c: Math.hypot(A, B), h: (Math.atan2(B, A) * 180 / Math.PI + 360) % 360 };
    }
    function fromOklch(L, C, h) {
        const a = C * Math.cos(h * Math.PI / 180), b = C * Math.sin(h * Math.PI / 180);
        const l = Math.pow(L + 0.3963377774 * a + 0.2158037573 * b, 3);
        const m = Math.pow(L - 0.1055613458 * a - 0.0638541728 * b, 3);
        const s = Math.pow(L - 0.0894841775 * a - 1.291485548 * b, 3);
        const out = [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                     -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                     -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s]
            .map(v => { v = Math.max(0, Math.min(1, v)); return v <= 0.0031308 ? 12.92 * v : 1.055 * Math.pow(v, 1 / 2.4) - 0.055; });
        return Qt.rgba(out[0], out[1], out[2], 1);
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: page.implicitHeight + 60
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: page
            x: 36; y: 30
            width: win.width - 72
            spacing: 14

            Txt { text: "Cómo funciona velure"; size: 34; weight: Font.Light }
            Txt {
                Layout.fillWidth: true; wrapMode: Text.Wrap; color: win.c("subtext")
                text: "De una imagen al tema de todo el escritorio, con datos reales. Elige una imagen para ver qué tema daría: tu fondo no cambia hasta que la uses como fondo. La ventana se pinta con los colores que velure calcula para ella."
            }

            // ================= La imagen que se explica =================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: chooser.implicitHeight + 32
                radius: 14
                color: win.c("bg")
                border.color: win.c("border")
                ColumnLayout {
                    id: chooser
                    x: 16; y: 16; width: parent.width - 32; spacing: 12
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Txt {
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                            text: (win.isWallpaper ? "Tu fondo actual: " : "Vista previa: ") + win.image.split("/").pop()
                                + (tokensProc.running ? "  ·  calculando…" : win.error !== "" ? "  ·  " + win.error : "")
                            size: 15; weight: Font.Medium
                        }
                        Button { text: "Fondo actual"; visible: !win.isWallpaper; onClicked: Design.guideImage = "" }
                        Button { text: "Otra imagen…"; onClicked: filePicker.running = true }
                        Button {
                            text: "Usar como fondo"; primary: true; visible: !win.isWallpaper
                            onClicked: { Wallpaper.choose(win.image); Design.guideImage = ""; }
                        }
                    }
                    ListView {
                        Layout.fillWidth: true
                        implicitHeight: 84
                        orientation: ListView.Horizontal
                        spacing: 8
                        clip: true
                        model: Wallpaper.files
                        delegate: Rectangle {
                            required property string modelData
                            readonly property bool selected: modelData === win.image
                            width: 132; height: 80; radius: 8; clip: true
                            color: win.c("surface")
                            border.width: selected ? 3 : 1
                            border.color: selected ? win.c("primary") : win.c("border")
                            Image {
                                anchors.fill: parent; anchors.margins: parent.selected ? 3 : 1
                                source: "file://" + (Wallpaper.thumbs[parent.modelData] ?? parent.modelData)
                                fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 264
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: Design.guideImage = parent.modelData === Theme.wallpaper ? "" : parent.modelData
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14
                visible: !!win.g

                // ================= 0 · El recorrido =================
                    Card {
                        number: "↻"; title: "Cada vez que cambias de fondo"
                        subtitle: "La shell ejecuta velure; velure calcula los colores, escribe el tema de cada app, avisa a las que están abiertas y le devuelve los tokens a la shell."
                        Flow {
                            Layout.fillWidth: true; spacing: 8
                            Repeater {
                                model: [["Fondo nuevo", "Wallpaper.qml"], ["→", ""], ["velure aplicar", "~/.local/bin/velure"], ["→", ""],
                                        ["Paleta", "17 colores auditados"], ["→", ""], ["Tokens", "57 con nombre y regla"], ["→", ""],
                                        ["11 apps", "cada tema en su archivo"], ["→", ""], ["Ganchos", "recargan lo abierto"], ["→", ""], ["Shell", "recibe los tokens"]]
                                Rectangle {
                                    required property var modelData
                                    readonly property bool arrow: modelData[0] === "→"
                                    width: arrow ? 22 : col.implicitWidth + 28; height: 58; radius: 10
                                    color: arrow ? "transparent" : win.c("surface")
                                    border.color: arrow ? "transparent" : win.c("border")
                                    Txt { visible: parent.arrow; anchors.centerIn: parent; text: "→"; size: 20; color: win.c("muted") }
                                    Column {
                                        id: col; visible: !parent.arrow; anchors.centerIn: parent; spacing: 2
                                        Txt { text: modelData[0]; size: 14; weight: Font.Medium }
                                        Txt { text: modelData[1]; size: 11; color: win.c("muted"); font.family: Design.monoFont }
                                    }
                                }
                            }
                        }
                    }
    
                    // ================= 1 · La imagen =================
                    Card {
                        number: "1"; title: "Lee la imagen"
                        subtitle: "Agrupa los píxeles en sus colores dominantes (k-means en OKLab, el espacio donde las distancias se parecen a lo que ve el ojo) y mide cuánto ocupa cada uno."
                        RowLayout {
                            spacing: 22
                            Rectangle {
                                implicitWidth: 360; implicitHeight: 203; radius: 10; clip: true; color: "#000"
                                Image { anchors.fill: parent; source: win.g ? "file://" + win.g.image : ""; fillMode: Image.PreserveAspectCrop; sourceSize.width: 720; asynchronous: true }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Txt { text: "Sus colores, por presencia"; color: win.c("subtext") }
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Repeater {
                                        model: win.g ? win.g.image_colors : []
                                        Column {
                                            required property string modelData
                                            readonly property string mark: !win.g ? "" : modelData === win.g.origins.primary ? "primario"
                                                : modelData === win.g.origins.secondary ? "secundario" : modelData === win.g.origins.tertiary ? "terciario" : ""
                                            spacing: 3
                                            Rectangle { width: 52; height: 52; radius: 8; color: parent.modelData; border.width: parent.mark ? 2 : 1; border.color: parent.mark ? win.c("text") : win.c("border") }
                                            Txt { text: parent.modelData; size: 9; color: win.c("muted"); font.family: Design.monoFont }
                                            Txt { text: parent.mark; size: 10; weight: Font.Medium }
                                        }
                                    }
                                }
                                Txt { Layout.fillWidth: true; wrapMode: Text.Wrap; size: 12; color: win.c("muted"); text: "Marcados, los colores de los que salen los acentos. Un acento puede salir de un detalle pequeño: lo que cuenta es su tono, no cuánto ocupa." }
                            }
                        }
                    }
    
                    // ================= 2 · La armonía =================
                    Card {
                        number: "2"; title: "Detecta la armonía"
                        subtitle: "Pone los tonos de la imagen en el círculo cromático (OKLCH) y busca la plantilla de Matsuda que mejor los explica. De ahí salen el primario, el secundario y el terciario."
                        RowLayout {
                            spacing: 30
                            Canvas {
                                id: wheel
                                implicitWidth: 300; implicitHeight: 300
                                property var data: win.g
                                onDataChanged: requestPaint()
                                onPaint: {
                                    const ctx = getContext("2d"); ctx.reset();
                                    const cx = width / 2, cy = height / 2, R = 128, r = 96;
                                    for (let a = 0; a < 360; a++) {
                                        ctx.beginPath(); ctx.strokeStyle = win.fromOklch(0.72, 0.11, a); ctx.lineWidth = R - r;
                                        const s = (a - 90 - 0.6) * Math.PI / 180, e = (a - 90 + 0.6) * Math.PI / 180;
                                        ctx.arc(cx, cy, (R + r) / 2, s, e); ctx.stroke();
                                    }
                                    if (!win.g) return;
                                    const dot = (hex, rad, size, ring) => {
                                        const h = win.oklch(hex).h, ang = (h - 90) * Math.PI / 180;
                                        const x = cx + rad * Math.cos(ang), y = cy + rad * Math.sin(ang);
                                        ctx.beginPath(); ctx.fillStyle = hex; ctx.arc(x, y, size, 0, 2 * Math.PI); ctx.fill();
                                        ctx.lineWidth = ring; ctx.strokeStyle = win.c("text"); ctx.stroke();
                                    };
                                    win.g.image_colors.filter(h => win.oklch(h).c > 0.03).forEach(h => dot(h, 70, 6, 1));
                                    ["primary", "secondary", "tertiary"].forEach((k, i) => dot(win.c(k), (R + r) / 2, 13, 3));
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Txt { text: "Armonía detectada: " + (win.g ? win.g.harmony : ""); size: 20; weight: Font.Medium }
                                Txt { Layout.fillWidth: true; wrapMode: Text.Wrap; color: win.c("subtext"); text: "Puntos pequeños: los tonos de la imagen. Círculos grandes, sobre el anillo: los tres acentos, ya ajustados (luz y croma contenidos para que nada sea chillón)." }
                                Repeater {
                                    model: [["primary", "Primario", "lo principal: botones, carpetas, cursor"], ["secondary", "Secundario", "funciones, enlaces"], ["tertiary", "Terciario", "detalles"]]
                                    RowLayout {
                                        required property var modelData
                                        spacing: 10
                                        Rectangle { implicitWidth: 34; implicitHeight: 34; radius: 17; color: win.c(modelData[0]) }
                                        Txt { text: modelData[1]; weight: Font.Medium; Layout.preferredWidth: 100 }
                                        Txt { text: modelData[2]; color: win.c("subtext") }
                                        Txt { text: Math.round(win.oklch(win.c(modelData[0])).h) + "°"; color: win.c("muted"); font.family: Design.monoFont }
                                    }
                                }
                            }
                        }
                    }
    
                    // ================= 3 · La paleta =================
                    Card {
                        number: "3"; title: "Construye la paleta (17 colores)"
                        subtitle: "Siempre oscura para el escritorio. Neutros con un toque del tono (regla 60-30-10), acentos con croma contenido y estados que se apartan de los acentos para no confundirse. Se audita: contraste WCAG y APCA, y daltonismo."
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Strip { label: "Neutros: de lo más hondo al texto"; names: ["crust", "bg", "surface", "overlay", "border", "muted", "subtext", "text"] }
                            Strip { label: "Acentos"; names: ["primary", "on_primary", "primary_container", "secondary", "tertiary"] }
                            Strip { label: "Estados: con su significado, aunque el fondo no los tenga"; names: ["error", "warning", "success", "info"] }
                        }
                    }
    
                    // ================= 4 · Los tokens =================
                    Card {
                        number: "4"; title: "Deriva los tokens (57)"
                        subtitle: "Un nombre por color. Unos son la paleta tal cual; los demás salen de una regla. Abajo, cuatro reglas con tus colores."
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            Strip { label: "Fondos: la paleta y sus puntos medios (surface_low, surface_high)"; names: ["crust", "bg", "surface_low", "surface", "surface_high", "overlay", "border", "outline"] }
                            Strip { label: "Código: separados entre sí y del texto"; names: ["syntax_keyword", "syntax_function", "syntax_type", "syntax_string", "syntax_number", "syntax_property"] }
                            Strip { label: "Terminal: los 16 colores, cada uno con su significado"; names: Array.from({ length: 16 }, (_, i) => "ansi_" + i); small: true }
                            Strip { label: "Degradado del visualizador: a 35° como máximo del primario"; names: Array.from({ length: 8 }, (_, i) => "gradient_" + i); small: true }
    
                            GridLayout {
                                Layout.fillWidth: true; columns: win.width > 1000 ? 2 : 1; columnSpacing: 14; rowSpacing: 14
                                Rule {
                                    title: "Punto medio"; body: "surface_low está a medio camino entre bg y surface, en OKLab: la escalera sube pareja."
                                    swatches: ["bg", "surface_low", "surface"]
                                }
                                Rule {
                                    title: "Contraste mínimo"; body: "outline se aclara desde border hasta leerse a 3:1 sobre surface, lo mínimo para encontrar un control."
                                    swatches: ["border", "outline", "surface"]
                                    note: "outline sobre surface: " + win.contrast(win.c("outline"), win.c("surface")).toFixed(2) + ":1"
                                }
                                Rule {
                                    title: "Separación"; body: "syntax_type parte del terciario, pero con croma mínimo y lejos del texto: un tipo nunca parece un comentario."
                                    swatches: ["tertiary", "syntax_type", "muted"]
                                }
                                Rule {
                                    title: "Texto sobre un relleno"; body: "on_success es el oscuro o el claro, teñido de su propio tono, que mejor se lee sobre success."
                                    swatches: ["success", "on_success"]
                                    sample: true
                                    note: "on_success sobre success: " + win.contrast(win.c("on_success"), win.c("success")).toFixed(2) + ":1"
                                }
                            }
                        }
                    }
    
                    // ================= 5 · Las comprobaciones =================
                    Card {
                        number: "5"; title: "Comprueba cada par que se lee"
                        subtitle: "Cada regla de contraste está declarada (CONTRAST_RULES) y se verifica en cada fondo. Si una fallara, velure avisa. Aquí, unas cuantas con tus colores."
                        Flow {
                            Layout.fillWidth: true; spacing: 10
                            Repeater {
                                model: [["text", "bg", 7], ["subtext", "surface", 4.5], ["on_primary", "primary", 4.5], ["on_primary_container", "primary_container", 7],
                                        ["error", "bg", 4.5], ["warning", "surface", 4.5], ["syntax_type", "bg", 4.5], ["muted", "bg", 3]]
                                Rectangle {
                                    required property var modelData
                                    readonly property real ratio: win.contrast(win.c(modelData[0]), win.c(modelData[1]))
                                    width: 290; height: 64; radius: 10; color: win.c(modelData[1]); border.color: win.c("border")
                                    Txt { x: 14; y: 10; text: "Aa  " + modelData[0]; color: win.c(modelData[0]); size: 15; weight: Font.Medium }
                                    Txt { x: 14; y: 36; text: "sobre " + modelData[1] + " · " + parent.ratio.toFixed(1) + ":1 (pide " + modelData[2] + ") " + (parent.ratio >= modelData[2] ? "✓" : "✗"); color: win.c(modelData[0]); size: 11 }
                                }
                            }
                        }
                    }
    
                    // ================= 6 · Las apps =================
                    Card {
                        number: "6"; title: "Escribe el tema de cada app"
                        subtitle: "Cada app sabe qué token va en cada sitio y dónde se escribe; config.toml solo elige cuáles y su gancho. Las barras: los tokens que más usa cada una, con los colores de esta imagen."
                        GridLayout {
                            Layout.fillWidth: true; columns: win.width > 1100 ? 3 : 2; columnSpacing: 12; rowSpacing: 12
                            Repeater {
                                model: win.apps
                                Rectangle {
                                    required property var modelData
                                    readonly property var topTokens: Object.entries(modelData.roles).sort((a, b) => b[1] - a[1]).slice(0, 10)
                                    Layout.fillWidth: true; implicitHeight: 96; radius: 10
                                    color: win.c("surface"); border.color: win.c("border")
                                    Txt { x: 14; y: 10; text: modelData.app; size: 15; weight: Font.Medium }
                                    Txt { x: 14; y: 32; width: parent.width - 28; elide: Text.ElideMiddle; text: modelData.salida ?? ""; size: 10; color: win.c("muted"); font.family: Design.monoFont }
                                    Txt { anchors.right: parent.right; anchors.rightMargin: 14; y: 12; text: Object.keys(modelData.roles).length + " tokens"; size: 11; color: win.c("subtext") }
                                    Row {
                                        x: 14; y: 58; spacing: 0
                                        Repeater {
                                            model: parent.parent.topTokens
                                            Rectangle { required property var modelData; width: 28; height: 22; color: win.c(modelData[0]) }
                                        }
                                    }
                                }
                            }
                        }
                    }
            }
            Item { implicitHeight: 10 }
        }
    }

    // --- Piezas ---
    component Txt: Text {
        property int size: 13
        property int weight: Font.Normal
        color: win.c("text")
        font.family: Design.font
        font.pixelSize: size
        font.weight: weight
    }
    component Card: Rectangle {
        id: card
        property string number
        property string title
        property string subtitle
        default property alias content: inner.data
        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + 48
        radius: 14
        color: win.c("bg")
        border.color: win.c("border")
        ColumnLayout {
            id: body
            x: 24; y: 24; width: parent.width - 48; spacing: 16
            RowLayout {
                spacing: 14
                Rectangle {
                    implicitWidth: 36; implicitHeight: 36; radius: 18; color: win.c("primary_container")
                    Txt { anchors.centerIn: parent; text: card.number; size: 15; weight: Font.Medium; color: win.c("on_primary_container") }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Txt { text: card.title; size: 22; weight: Font.Light }
                    Txt { Layout.fillWidth: true; wrapMode: Text.Wrap; text: card.subtitle; color: win.c("subtext") }
                }
            }
            ColumnLayout { id: inner; Layout.fillWidth: true; spacing: 12 }
        }
    }
    component Strip: ColumnLayout {
        property string label
        property var names: []
        property bool small: false
        spacing: 6
        Layout.fillWidth: true
        Txt { text: parent.label; color: win.c("subtext"); size: 12 }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: parent.parent.names
                Column {
                    required property string modelData
                    spacing: 3
                    Rectangle { width: small ? 54 : 92; height: small ? 30 : 44; radius: 8; color: win.c(parent.modelData); border.color: win.c("border") }
                    Txt { visible: !small; text: parent.modelData; size: 10; color: win.c("subtext"); font.family: Design.monoFont }
                    Txt { text: win.c(parent.modelData); size: 9; color: win.c("muted"); font.family: Design.monoFont }
                }
            }
        }
    }
    component Rule: Rectangle {
        id: rule
        property string title
        property string body
        property var swatches: []
        property string note
        property bool sample: false
        Layout.fillWidth: true
        implicitHeight: col.implicitHeight + 28
        radius: 10
        color: win.c("surface")
        border.color: win.c("border")
        ColumnLayout {
            id: col
            x: 14; y: 14; width: parent.width - 28; spacing: 8
            Txt { text: rule.title; size: 15; weight: Font.Medium }
            Txt { Layout.fillWidth: true; wrapMode: Text.Wrap; text: rule.body; color: win.c("subtext"); size: 12 }
            Row {
                spacing: 8
                Repeater {
                    model: rule.swatches
                    Column {
                        required property string modelData
                        spacing: 3
                        Rectangle {
                            width: 110; height: 40; radius: 8; color: win.c(parent.modelData); border.color: win.c("border")
                            Txt { visible: rule.sample && parent.parent.modelData === "success"; anchors.centerIn: parent; text: "Guardado"; color: win.c("on_success"); weight: Font.Medium }
                        }
                        Txt { text: parent.modelData; size: 10; color: win.c("subtext"); font.family: Design.monoFont }
                    }
                }
            }
            Txt { visible: rule.note !== ""; text: rule.note; size: 12; color: win.c("primary") }
        }
    }
    component Button: Rectangle {
        id: button
        property string text
        property bool primary: false
        signal clicked
        implicitWidth: label.implicitWidth + 28
        implicitHeight: 34
        radius: 8
        color: primary ? win.c("primary") : mouse.containsMouse ? win.c("overlay") : win.c("surface_high")
        border.color: primary ? "transparent" : win.c("border")
        Txt { id: label; anchors.centerIn: parent; text: button.text; color: button.primary ? win.c("on_primary") : win.c("text") }
        MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: button.clicked() }
    }
}
