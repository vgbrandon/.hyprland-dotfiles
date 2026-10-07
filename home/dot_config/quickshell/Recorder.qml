pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Grabación de pantalla con gpu-screen-recorder (codifica con la tarjeta gráfica).
//   quickshell ipc call record screen | region | stop | toggle
Singleton {
    id: root

    readonly property string dir: `${Quickshell.env("HOME")}/Videos/Grabaciones`
    property bool recording: false
    property bool selecting: false
    property bool systemAudio: true
    property bool microphone: false
    property string file: ""
    property real startedAt: 0
    property int elapsed: 0 // segundos

    function timeText() {
        const m = Math.floor(elapsed / 60), s = elapsed % 60;
        return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
    }

    function audioArgs() {
        const sources = [];
        if (systemAudio) sources.push("default_output");
        if (microphone) sources.push("default_input");
        // Varias fuentes separadas por "|" se mezclan en una sola pista
        return sources.length > 0 ? ["-a", sources.join("|"), "-ac", "aac"] : [];
    }

    function start(target, regionArgs) {
        if (recording) return;
        file = `${dir}/Grabacion_${Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss")}.mp4`;
        recordProc.command = ["gpu-screen-recorder", "-w", target, ...(regionArgs ?? []),
            "-f", "60", ...audioArgs(), "-o", file];
        recordProc.running = true;
        recording = true;
        startedAt = Date.now();
        elapsed = 0;
    }

    // Monitor enfocado completo
    function recordScreen() {
        const monitor = Hyprland.focusedMonitor?.name ?? "";
        if (monitor !== "") start(monitor);
    }

    // Región elegida con el ratón (slurp, con los colores del tema)
    function recordRegion() {
        if (recording || selecting) return;
        selecting = true;
        const hex = c => "#" + [c.r, c.g, c.b].map(v => Math.round(v * 255).toString(16).padStart(2, "0")).join("");
        slurpProc.command = ["slurp", "-d", "-f", "%wx%h+%x+%y", "-w", "2",
            "-b", "#00000066", "-c", hex(Theme.primary) + "ff", "-s", "#00000000"];
        slurpProc.running = true;
    }

    function stop() {
        if (recording) recordProc.signal(2); // SIGINT: termina y cierra el archivo bien
    }

    function toggle() {
        if (recording) stop();
        else recordScreen();
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", dir])

    IpcHandler {
        target: "record"

        function screen(): void { root.recordScreen(); }
        function region(): void { root.recordRegion(); }
        function stop(): void { root.stop(); }
        function toggle(): void { root.toggle(); }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsed = Math.floor((Date.now() - root.startedAt) / 1000)
    }

    Process {
        id: slurpProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.selecting = false;
                const region = this.text.trim();
                // Vacío si se canceló con Esc
                if (/^\d+x\d+\+-?\d+\+-?\d+$/.test(region)) root.start("region", ["-region", region]);
            }
        }
    }

    Process {
        id: recordProc
        onExited: {
            root.recording = false;
            root.finish(root.file);
        }
    }

    // Miniatura del video y notificación; clic en la notificación = abrir con mpv
    function finish(video) {
        Quickshell.execDetached(["sh", "-c", `
            [ -s "$1" ] || exit 0
            thumb="/tmp/qs-recording-thumb-$(date +%s).jpg"
            ffmpeg -loglevel error -y -ss 0.5 -i "$1" -frames:v 1 -vf scale=320:-1 "$thumb" 2>/dev/null
            action=$(notify-send -a "Grabación de pantalla" -h string:image-path:"$thumb" -A default=Abrir \\
                "Grabación guardada" "$(basename "$1")")
            [ "$action" = default ] && mpv --force-window "$1"`, "sh", video]);
    }
}
