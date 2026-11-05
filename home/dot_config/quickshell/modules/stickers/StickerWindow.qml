import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.components.base
import qs.components.design
import qs.services

// Editor de stickers de WhatsApp (la lógica está en services/Stickers.qml): a la izquierda
// el lienzo de 512 × 512 (la imagen se arrastra y se acerca con la rueda; los textos se
// arrastran) y a la derecha las herramientas: origen (archivo, pegar o soltar; en los
// animados, el tramo), recorte, textos y exportar. Lo que se ve es lo que sale: al
// exportar se guarda la capa de textos tal cual y ffmpeg la pone sobre la imagen.
//   quickshell ipc call stickers toggle
//   quickshell ipc call stickereditor addText TEXTO | exportSticker
FloatingWindow {
    id: win

    visible: Stickers.open
    onVisibleChanged: if (!visible) Stickers.open = false
    title: "Stickers"
    implicitWidth: 1180
    implicitHeight: 780
    color: Design.background

    // --- La imagen en el lienzo: escala (px del lienzo por px de la imagen) y esquina ---
    readonly property int side: 512
    property real scale: 1
    property real mx: 0
    property real my: 0
    readonly property real coverScale: Stickers.mediaWidth > 0 ? Math.max(side / Stickers.mediaWidth, side / Stickers.mediaHeight) : 1
    readonly property real containScale: Stickers.mediaWidth > 0 ? Math.min(side / Stickers.mediaWidth, side / Stickers.mediaHeight) : 1
    // 0 = encajar (se ve entera), 1 = rellenar (cubre el cuadrado)
    property int fitMode: 1

    function placeCentered(s) {
        scale = s;
        mx = (side - Stickers.mediaWidth * s) / 2;
        my = (side - Stickers.mediaHeight * s) / 2;
    }
    function fill() {
        fitMode = 1;
        placeCentered(coverScale);
    }
    function fit() {
        fitMode = 0;
        placeCentered(containScale);
    }
    // Acercar o alejar manteniendo quieto el punto (px, py) del lienzo
    function zoomTo(s, px, py) {
        s = Math.max(containScale / 4, Math.min(s, coverScale * 6));
        mx = px - (px - mx) * s / scale;
        my = py - (py - my) * s / scale;
        scale = s;
    }
    Connections {
        target: Stickers
        function onLoaded() {
            win.fill();
        }
    }

    // --- Los textos ---
    ListModel { id: texts }
    property int current: -1
    readonly property var sel: current >= 0 && current < texts.count ? texts.get(current) : null
    readonly property string defaultFont: {
        const fams = Qt.fontFamilies();
        for (const f of ["Anton", "Bebas Neue", "Impact", "Archivo Black", "Montserrat", "Adwaita Sans"])
            if (fams.includes(f)) return f;
        return "Sans";
    }
    function addText() {
        texts.append({ text: "TEXTO", family: defaultFont, size: 72, weight: Font.Black, fill: "#ffffff",
            stroke: "#000000", strokeWidth: 6, angle: 0, cx: side / 2, cy: texts.count % 2 === 0 ? side - 70 : 70 });
        current = texts.count - 1;
    }
    function setSel(prop, value) {
        if (current >= 0) texts.setProperty(current, prop, value);
    }
    // Que el texto elegido quepa en el ancho (al escribirlo o al cambiar de fuente): si se
    // sale, se reduce; si cabe, se deja el tamaño que tenga
    TextMetrics { id: metrics }
    function fitSel() {
        const t = sel;
        if (!t) return;
        metrics.font.family = t.family;
        metrics.font.pixelSize = t.size;
        metrics.font.weight = t.weight;
        metrics.text = t.text;
        const ancho = metrics.advanceWidth + t.strokeWidth * 2;
        if (ancho > 480) setSel("size", Math.max(16, Math.floor(t.size * 480 / ancho)));
    }

    IpcHandler {
        target: "stickereditor"
        function addText(text: string): void {
            win.addText();
            win.setSel("text", text);
            win.fitSel();
        }
        function exportSticker(): void { win.doExport(); }
    }

    // --- Exportar: se guarda la capa de textos (sin el marco de selección) y se hace ---
    property bool cleanLayer: false
    function doExport() {
        if (!Stickers.ready || Stickers.exporting) return;
        cleanLayer = true;
        Qt.callLater(() => textLayer.grabToImage(r => {
            r.saveToFile(Stickers.overlayPath);
            win.cleanLayer = false;
            Stickers.run(win.mx, win.my, Stickers.mediaWidth * win.scale, Stickers.mediaHeight * win.scale);
        }, Qt.size(side, side)));
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24

        // ================= Lienzo =================
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: win.side
            Layout.maximumWidth: win.side
            spacing: 14

            ColumnLayout {
                spacing: 2
                Txt { text: "Stickers"; textStyle: Design.title }
                Txt {
                    text: "Cuadrado de 512 × 512 para WhatsApp: estáticos o animados"
                    textStyle: Design.caption
                    color: Design.onSurfaceVariant
                }
            }

            ClippingRectangle {
                id: canvasBox
                Layout.preferredWidth: win.side
                Layout.preferredHeight: win.side
                radius: Design.radiusMd
                color: "transparent"

                // Fondo de cuadros: lo que queda así será transparente en el sticker
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d");
                        const n = 16;
                        for (let i = 0; i < width / n; i++)
                            for (let j = 0; j < height / n; j++) {
                                ctx.fillStyle = (i + j) % 2 === 0 ? "#2a2c33" : "#22242a";
                                ctx.fillRect(i * n, j * n, n, n);
                            }
                    }
                }

                // La imagen (o la vista previa del tramo animado)
                Image {
                    visible: Stickers.ready && !Stickers.animated
                    x: win.mx
                    y: win.my
                    width: Stickers.mediaWidth * win.scale
                    height: Stickers.mediaHeight * win.scale
                    source: Stickers.ready && !Stickers.animated ? Stickers.display : ""
                    sourceSize.width: 1024
                    asynchronous: true
                    smooth: true
                    mipmap: true
                }
                AnimatedImage {
                    visible: Stickers.ready && Stickers.animated
                    x: win.mx
                    y: win.my
                    width: Stickers.mediaWidth * win.scale
                    height: Stickers.mediaHeight * win.scale
                    source: Stickers.ready && Stickers.animated ? Stickers.display : ""
                    playing: win.visible
                    smooth: true
                }

                // Mover la imagen (arrastrar) y acercar o alejar (rueda)
                MouseArea {
                    anchors.fill: parent
                    enabled: Stickers.ready
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    property real fx
                    property real fy
                    onPressed: e => {
                        win.current = -1;
                        fx = e.x - win.mx;
                        fy = e.y - win.my;
                    }
                    onPositionChanged: e => {
                        if (!pressed) return;
                        win.mx = e.x - fx;
                        win.my = e.y - fy;
                    }
                    onWheel: e => win.zoomTo(win.scale * (e.angleDelta.y > 0 ? 1.1 : 1 / 1.1), e.x, e.y)
                }

                // La capa de textos: exactamente lo que se guarda para el sticker
                Item {
                    id: textLayer
                    width: win.side
                    height: win.side
                    Repeater {
                        model: texts
                        StickerText {
                            required property int index
                            required property var model
                            text: model.text
                            family: model.family
                            size: model.size
                            weight: model.weight
                            fill: model.fill
                            stroke: model.stroke
                            strokeWidth: model.strokeWidth
                            angle: model.angle
                            cx: model.cx
                            cy: model.cy
                            selected: win.current === index
                            clean: win.cleanLayer
                            onPressed: win.current = index
                            onMoved: (x, y) => {
                                texts.setProperty(index, "cx", x);
                                texts.setProperty(index, "cy", y);
                            }
                        }
                    }
                }

                // Sin nada abierto
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: !Stickers.ready
                    spacing: 12
                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        text: Stickers.busy ? Theme.iTimer : Theme.iSticker
                        font.pixelSize: 44
                        color: Design.onSurfaceVariant
                    }
                    Txt {
                        Layout.alignment: Qt.AlignHCenter
                        text: Stickers.busy ? "Preparando…" : "Abre una imagen, un GIF o un video,\npégalo o suéltalo aquí"
                        horizontalAlignment: Text.AlignHCenter
                        color: Design.onSurfaceVariant
                    }
                }

                // Soltar un archivo (desde Thunar)
                DropArea {
                    anchors.fill: parent
                    onDropped: drop => {
                        if (drop.hasUrls) Stickers.load(drop.urls[0].toString());
                    }
                }
            }

            Txt {
                Layout.fillWidth: true
                text: Stickers.ready
                    ? "Arrastra la imagen para moverla y usa la rueda para acercarla. Los textos también se arrastran. Lo que queda en cuadros sale transparente."
                    : ""
                textStyle: Design.caption
                color: Design.muted
                wrapMode: Text.Wrap
            }
        }

        // ================= Herramientas =================
        Flickable {
            id: toolsFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: tools.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: tools
                width: toolsFlick.width
                spacing: 14

                // --- Origen ---
                ToolBox {
                    title: "Origen"
                    note: Stickers.source === "" ? "Imagen (PNG, JPG, WebP), GIF o video"
                        : Stickers.source.split("/").pop() + "  ·  " + Stickers.mediaWidth + " × " + Stickers.mediaHeight
                          + "  ·  " + ({ image: "imagen", gif: "GIF animado", video: "video" })[Stickers.kind]
                    RowLayout {
                        spacing: 8
                        Btn { kind: "tonal"; icon: Theme.iImage; text: "Abrir archivo…"; onClicked: Stickers.pick() }
                        Btn { kind: "tonal"; icon: Theme.iClipboard; text: "Pegar"; onClicked: Stickers.paste() }
                    }
                    // Tramo de los animados
                    ColumnLayout {
                        visible: Stickers.animated
                        Layout.fillWidth: true
                        spacing: 6
                        Txt {
                            text: "Empieza en " + Stickers.start.toFixed(1) + " s"
                                + (Stickers.duration > 0 ? " de " + Stickers.duration.toFixed(1) + " s" : "")
                            textStyle: Design.label
                            color: Design.onSurfaceVariant
                        }
                        Slide {
                            Layout.fillWidth: true
                            value: Stickers.duration > 0 ? Stickers.start / Stickers.duration : 0
                            onMoved: v => Stickers.setRange(v * Stickers.duration, Stickers.length)
                        }
                        Txt {
                            text: "Dura " + Stickers.length.toFixed(1) + " s (más corto pesa menos; hasta " + Stickers.maxLength + " s)"
                            textStyle: Design.label
                            color: Design.onSurfaceVariant
                        }
                        Slide {
                            Layout.fillWidth: true
                            value: (Stickers.length - 0.5) / (Stickers.maxLength - 0.5)
                            onMoved: v => Stickers.setRange(Stickers.start, 0.5 + v * (Stickers.maxLength - 0.5))
                        }
                    }
                }

                // --- Recorte ---
                ToolBox {
                    visible: Stickers.ready
                    title: "Recorte"
                    note: "Rellenar cubre el cuadrado (recorta lo que sobra); encajar muestra la imagen entera con fondo transparente"
                    Segmented {
                        Layout.fillWidth: true
                        options: ["Encajar", "Rellenar"]
                        current: win.fitMode
                        follow: false
                        onSelected: i => i === 0 ? win.fit() : win.fill()
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Icon { text: Theme.iImage; color: Design.onSurfaceVariant }
                        Slide {
                            Layout.fillWidth: true
                            // Escala logarítmica entre encajar/4 y rellenar×6
                            readonly property real lo: Math.log(win.containScale / 4)
                            readonly property real hi: Math.log(win.coverScale * 6)
                            value: (Math.log(win.scale) - lo) / (hi - lo)
                            onMoved: v => win.zoomTo(Math.exp(lo + v * (hi - lo)), win.side / 2, win.side / 2)
                        }
                        Btn { kind: "text"; small: true; text: "Centrar"; onClicked: win.placeCentered(win.scale) }
                    }
                }

                // --- Textos ---
                ToolBox {
                    visible: Stickers.ready
                    title: "Textos"
                    note: "Elige un texto en la lista o pulsándolo en el lienzo para editarlo"
                    Btn { kind: "tonal"; icon: Theme.iPlus; text: "Añadir texto"; onClicked: win.addText() }
                    Repeater {
                        model: texts
                        ListRow {
                            required property int index
                            required property var model
                            Layout.fillWidth: true
                            icon: Theme.iPencil
                            title: model.text === "" ? "(vacío)" : model.text
                            subtitle: model.family + " · " + model.size + " px"
                            selected: win.current === index
                            onClicked: win.current = index
                            IconBtn {
                                icon: Theme.iDelete
                                onClicked: {
                                    texts.remove(parent.index);
                                    win.current = Math.min(win.current, texts.count - 1);
                                }
                            }
                        }
                    }

                    // Edición del texto elegido
                    ColumnLayout {
                        visible: win.sel !== null
                        Layout.fillWidth: true
                        spacing: 12

                        Field {
                            Layout.fillWidth: true
                            placeholder: "Texto"
                            text: win.sel?.text ?? ""
                            onTextChanged: {
                                if (win.sel && text !== win.sel.text) {
                                    win.setSel("text", text);
                                    win.fitSel();
                                }
                            }
                        }

                        // Fuente: buscar entre las instaladas
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Txt { text: "Fuente: " + (win.sel?.family ?? ""); textStyle: Design.label; color: Design.onSurfaceVariant }
                            Field {
                                id: fontSearch
                                Layout.fillWidth: true
                                icon: Theme.iSearch
                                placeholder: "Buscar fuente"
                            }
                            ListView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 132
                                clip: true
                                model: Qt.fontFamilies().filter(f => f.toLowerCase().includes(fontSearch.text.toLowerCase()))
                                delegate: Rectangle {
                                    required property string modelData
                                    width: ListView.view.width
                                    height: 30
                                    radius: Design.radiusSm
                                    color: win.sel?.family === modelData ? Design.selection : fontMouse.containsMouse ? Design.hoverLayer : "transparent"
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: 10
                                        text: parent.modelData
                                        font.family: parent.modelData
                                        font.pixelSize: 15
                                        color: Design.onSurface
                                    }
                                    MouseArea {
                                        id: fontMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            win.setSel("family", parent.modelData);
                                            win.fitSel();
                                        }
                                    }
                                }
                            }
                        }

                        Segmented {
                            Layout.fillWidth: true
                            options: ["Normal", "Negrita", "Muy gruesa"]
                            readonly property var weights: [Font.Normal, Font.Bold, Font.Black]
                            current: Math.max(0, weights.indexOf(win.sel?.weight ?? Font.Black))
                            follow: false
                            onSelected: i => win.setSel("weight", weights[i])
                        }

                        Txt { text: "Tamaño: " + (win.sel?.size ?? 0) + " px"; textStyle: Design.label; color: Design.onSurfaceVariant }
                        Slide {
                            Layout.fillWidth: true
                            value: ((win.sel?.size ?? 72) - 16) / (200 - 16)
                            onMoved: v => win.setSel("size", Math.round(16 + v * (200 - 16)))
                        }

                        ColorRow {
                            label: "Letra"
                            value: win.sel?.fill ?? "#ffffff"
                            onPicked: c => win.setSel("fill", c.toString())
                        }
                        ColorRow {
                            label: "Borde"
                            value: win.sel?.stroke ?? "#000000"
                            onPicked: c => win.setSel("stroke", c.toString())
                        }
                        Txt { text: "Grosor del borde: " + (win.sel?.strokeWidth ?? 0) + " px"; textStyle: Design.label; color: Design.onSurfaceVariant }
                        Slide {
                            Layout.fillWidth: true
                            value: (win.sel?.strokeWidth ?? 6) / 20
                            onMoved: v => win.setSel("strokeWidth", Math.round(v * 20))
                        }
                        Txt { text: "Giro: " + Math.round(win.sel?.angle ?? 0) + "°"; textStyle: Design.label; color: Design.onSurfaceVariant }
                        Slide {
                            Layout.fillWidth: true
                            value: ((win.sel?.angle ?? 0) + 45) / 90
                            onMoved: v => win.setSel("angle", Math.round(v * 90 - 45))
                        }
                    }
                }

                // --- Exportar ---
                ToolBox {
                    visible: Stickers.ready
                    title: "Crear el sticker"
                    note: (Stickers.animated ? "WebP animado, hasta 500 KB" : "WebP, hasta 100 KB") + ", en ~/Pictures/Stickers"
                    Btn {
                        kind: "filled"
                        icon: Theme.iSticker
                        text: Stickers.exporting ? "Creando…" : "Crear sticker"
                        onClicked: win.doExport()
                    }
                    RowLayout {
                        visible: Stickers.lastFile !== ""
                        Layout.fillWidth: true
                        spacing: 8
                        Txt {
                            Layout.fillWidth: true
                            text: Stickers.lastFile.split("/").pop() + "  ·  " + Math.round(Stickers.lastSize / 1024) + " KB"
                            textStyle: Design.caption
                            color: Design.onSurfaceVariant
                            elide: Text.ElideMiddle
                        }
                        Btn { kind: "tonal"; small: true; text: "Copiar"; onClicked: Stickers.copyLast() }
                        Btn { kind: "text"; small: true; text: "Abrir carpeta"; onClicked: Stickers.openFolder() }
                    }
                }

                Txt {
                    visible: Stickers.notice !== ""
                    Layout.fillWidth: true
                    text: Stickers.notice
                    color: Design.error
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
