pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Aviso flotante (OSD) al cambiar el volumen, silenciar o cambiar la salida de audio,
// al silenciar el micrófono y al cambiar el brillo (Brightness lo llama). Se ve un momento y se va solo. No sale al iniciar ni
// cuando el cambio se hace desde la píldora del volumen (ya se está viendo ahí):
// esa llama a quiet(). La ventana está en modules/osd.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    // Lo que se muestra: "volume", "mic" o "brightness"
    property string kind: "volume"
    property bool shown: false
    property real brightness: 0
    readonly property real level: kind === "mic" ? (source?.audio?.volume ?? 0)
        : kind === "brightness" ? brightness : (sink?.audio?.volume ?? 0)
    readonly property bool muted: kind === "mic" ? (source?.audio?.muted ?? false)
        : kind === "brightness" ? false : (sink?.audio?.muted ?? false) || Math.round(level * 100) === 0
    // Nombre del dispositivo (al cambiar de salida)
    property string device: ""

    // Sin avisos hasta que se asienta el inicio, ni justo después de usar la píldora
    property bool ready: false
    property real quietUntil: 0
    function quiet() {
        quietUntil = Date.now() + 600;
    }

    // name: dispositivo o monitor; value: nivel del brillo
    function show(what, name, value) {
        if (!ready || Date.now() < quietUntil) return;
        kind = what;
        device = name ?? "";
        if (what === "brightness") brightness = value ?? 0;
        shown = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shown = false
    }
    Timer {
        interval: 2000
        running: true
        onTriggered: root.ready = true
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.show("volume"); }
        function onMutedChanged() { root.show("volume"); }
    }
    Connections {
        target: root.source?.audio ?? null
        function onMutedChanged() { root.show("mic"); }
    }
    // Otra salida de audio (auriculares, HDMI…): se avisa con su nombre
    onSinkChanged: if (sink) show("volume", sink.description || sink.nickname || sink.name)
}
