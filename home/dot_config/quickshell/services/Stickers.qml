pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Creador de stickers de WhatsApp (WebP de 512 × 512, estáticos o animados): la lógica.
// Abre una imagen, GIF o video (o lo pega del portapapeles), lo analiza con ffprobe y, en
// los animados, genera la vista previa del tramo elegido (un GIF). La ventana es
// modules/stickers/StickerWindow.qml: coloca la imagen en el cuadrado, pone los textos y
// al exportar guarda la capa de textos y llama a run(); scripts/sticker-export.sh hace el
// sticker con ffmpeg en ~/Pictures/Stickers, dentro de los límites de WhatsApp.
//   quickshell ipc call stickers toggle | open | close | load RUTA
Singleton {
    id: root

    property bool open: false
    function toggle() {
        open = !open;
    }

    readonly property string home: Quickshell.env("HOME")
    readonly property string cacheDir: home + "/.cache/velure/stickers"
    readonly property string outDir: home + "/Pictures/Stickers"
    readonly property string overlayPath: cacheDir + "/textos.png"
    readonly property string previewPath: cacheDir + "/vista.gif"

    // --- El origen ---
    property string source: ""          // archivo elegido
    property string kind: ""            // "image", "gif" o "video"
    property string display: ""         // lo que muestra el lienzo (la imagen o la vista previa)
    property int mediaWidth: 0
    property int mediaHeight: 0
    property real duration: 0           // segundos (animados)
    readonly property bool animated: kind === "gif" || kind === "video"
    readonly property bool ready: display !== "" && mediaWidth > 0
    // Tramo de los animados (WhatsApp: hasta 10 s; más corto pesa menos)
    readonly property real maxLength: 8
    readonly property real defaultLength: 4
    property real start: 0
    property real length: 0
    property string notice: ""
    property bool busy: false

    // --- Exportar ---
    property bool exporting: false
    property string lastFile: ""
    property int lastSize: 0

    signal loaded()

    // Las carpetas de trabajo (la capa de textos se guarda ahí antes de exportar)
    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", cacheDir])

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    // Elegir un archivo (zenity: ventana GTK con el tema)
    function pick() {
        picker.running = true;
    }
    Process {
        id: picker
        command: ["zenity", "--file-selection", "--title=Elegir imagen, GIF o video",
            "--file-filter=Imágenes, GIF y videos | *.png *.PNG *.jpg *.JPG *.jpeg *.JPEG *.webp *.WEBP *.gif *.GIF *.mp4 *.MP4 *.webm *.mkv *.mov *.MOV *.avi",
            "--file-filter=Todos | *"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim();
                if (p !== "") root.load(p);
            }
        }
    }

    // Pegar del portapapeles: una imagen copiada o un archivo copiado (en Thunar)
    function paste() {
        notice = "";
        paster.running = true;
    }
    Process {
        id: paster
        command: ["sh", "-c", `d="$1"; mkdir -p "$d"
            tipos=$(wl-paste --list-types 2>/dev/null) || { echo "error"; exit 0; }
            if printf '%s\\n' "$tipos" | grep -qx 'text/uri-list'; then
                uri=$(wl-paste --type text/uri-list | grep -m1 '^file://')
                if [ -n "$uri" ]; then
                    python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1][7:]))' "$uri"; exit 0
                fi
            fi
            tipo=$(printf '%s\\n' "$tipos" | grep -m1 -E '^image/(png|jpeg|gif|webp)$')
            [ -n "$tipo" ] || { echo "error"; exit 0; }
            ext=\${tipo#image/}; [ "$ext" = jpeg ] && ext=jpg
            f="$d/pegado-$(date +%s).$ext"
            wl-paste --type "$tipo" > "$f" && echo "$f"`, "sh", root.cacheDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim();
                if (p === "" || p === "error") root.notice = "El portapapeles no tiene una imagen ni un archivo";
                else root.load(p);
            }
        }
    }

    // Cargar un archivo: se analiza y se prepara lo que muestra el lienzo
    function load(path) {
        path = String(path).replace(/^file:\/\//, "");
        notice = "";
        busy = true;
        source = path;
        display = "";
        mediaWidth = 0;
        mediaHeight = 0;
        probe.command = ["ffprobe", "-v", "error", "-select_streams", "v:0", "-count_packets",
            "-show_entries", "stream=width,height,nb_read_packets:format=duration", "-of", "json", path];
        probe.running = true;
    }
    Process {
        id: probe
        stdout: StdioCollector {
            onStreamFinished: {
                let d = null;
                try {
                    d = JSON.parse(this.text);
                } catch (e) {}
                const s = d?.streams?.[0];
                if (!s || !s.width) {
                    root.busy = false;
                    root.notice = "No se pudo leer el archivo: ¿es una imagen, un GIF o un video?";
                    return;
                }
                const ext = root.source.split(".").pop().toLowerCase();
                const frames = parseInt(s.nb_read_packets ?? "1") || 1;
                const dur = parseFloat(d.format?.duration ?? "0") || 0;
                root.mediaWidth = s.width;
                root.mediaHeight = s.height;
                if (["mp4", "webm", "mkv", "mov", "avi", "m4v"].includes(ext)) root.kind = "video";
                else if (ext === "gif" && frames > 1) root.kind = "gif";
                else root.kind = "image";
                root.duration = dur;
                if (root.animated) {
                    root.start = 0;
                    root.length = Math.min(dur > 0 ? dur : root.defaultLength, root.defaultLength);
                    root.makePreview();
                } else if (ext === "webp") {
                    // Qt no lee WebP sin qt6-imageformats: se convierte a PNG para verlo
                    convert.command = ["sh", "-c", 'mkdir -p "$1" && ffmpeg -v error -y -i "$2" "$1/vista.png" && echo ok',
                        "sh", root.cacheDir, root.source];
                    convert.running = true;
                } else {
                    root.display = "file://" + root.source;
                    root.busy = false;
                    root.loaded();
                }
            }
        }
    }
    Process {
        id: convert
        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;
                if (this.text.trim() !== "ok") {
                    root.notice = "No se pudo abrir la imagen";
                    return;
                }
                // Un nombre distinto cada vez: si no, el lienzo seguiría con la anterior
                root.display = "file://" + root.cacheDir + "/vista.png?" + Date.now();
                root.loaded();
            }
        }
    }

    // Vista previa de los animados: el tramo elegido en GIF (15 fps, hasta 384 px: carga rápido)
    function setRange(s, l) {
        start = Math.max(0, Math.min(s, Math.max(0, duration - 0.1)));
        length = Math.max(0.5, Math.min(l, maxLength, duration > 0 ? duration - start : maxLength));
        previewTimer.restart();
    }
    Timer {
        id: previewTimer
        interval: 400
        onTriggered: root.makePreview()
    }
    function makePreview() {
        busy = true;
        preview.command = ["sh", "-c", `mkdir -p "$1"
            ffmpeg -v error -y -ss "$3" -t "$4" -i "$2" -filter_complex \
              "fps=15,scale=384:384:force_original_aspect_ratio=decrease,split[a][b];[a]palettegen=reserve_transparent=1[p];[b][p]paletteuse" \
              -loop 0 "$1/vista.gif" && echo ok`, "sh", cacheDir, source, String(start), String(length)];
        preview.running = true;
    }
    Process {
        id: preview
        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;
                if (this.text.trim() !== "ok") {
                    root.notice = "No se pudo preparar la vista previa";
                    return;
                }
                const primera = root.display === "";
                root.display = "file://" + root.previewPath + "?" + Date.now();
                if (primera) root.loaded();
            }
        }
    }

    // Exportar: la ventana ya guardó la capa de textos (overlayPath); x, y, w, h son la
    // imagen en el lienzo de 512 × 512
    function run(x, y, w, h) {
        if (!ready || exporting) return;
        exporting = true;
        notice = "";
        const fecha = Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss");
        const out = outDir + "/sticker-" + fecha + ".webp";
        exporter.out = out;
        const args = [Quickshell.shellPath("scripts/sticker-export.sh"), animated ? "anim" : "static", source,
            String(Math.round(w)), String(Math.round(h)), String(Math.round(x)), String(Math.round(y)), overlayPath, out];
        if (animated) args.push(String(start), String(length));
        exporter.command = args;
        exporter.running = true;
    }
    Process {
        id: exporter
        property string out
        stdout: StdioCollector {
            onStreamFinished: {
                root.exporting = false;
                const r = this.text.trim().split(" ");
                if (r[0] === "ok") {
                    root.lastFile = exporter.out;
                    root.lastSize = parseInt(r[1]);
                    root.notice = "";
                } else {
                    root.notice = r.slice(1).join(" ") || "No se pudo crear el sticker";
                }
            }
        }
    }

    // Copiar el último sticker (para pegarlo en WhatsApp) y abrir la carpeta
    function copyLast() {
        if (lastFile === "") return;
        Quickshell.execDetached(["sh", "-c", 'wl-copy --type image/webp < "$1"', "sh", lastFile]);
    }
    function openFolder() {
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$1" && xdg-open "$1"', "sh", outDir]);
    }

    IpcHandler {
        target: "stickers"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
        function load(path: string): void { root.open = true; root.load(path); }
    }
}
