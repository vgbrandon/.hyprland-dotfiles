pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Sonido (PipeWire): salidas y entradas, cuál se usa, su volumen y el de cada app que
// suena. El panel está en modules/audio (clic en el volumen de la barra).
//   quickshell ipc call audio toggle
Singleton {
    id: root

    signal panelRequested()

    readonly property var nodes: Pipewire.nodes.values
    // Dispositivos de salida y de entrada, y apps que suenan o graban (por el tipo del
    // nodo, que siempre está; las propiedades llegan más tarde)
    readonly property var sinks: nodes.filter(n => n.type === PwNodeType.AudioSink)
    readonly property var sources: nodes.filter(n => n.type === PwNodeType.AudioSource)
    readonly property var playing: nodes.filter(n => n.type === PwNodeType.AudioOutStream)
    readonly property var recording: nodes.filter(n => n.type === PwNodeType.AudioInStream)

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // Los nodos solo traen volumen si se siguen
    PwObjectTracker {
        objects: root.sinks.concat(root.sources, root.playing, root.recording)
    }

    function setDefault(node) {
        if (!node) return;
        if (node.isSink) Pipewire.preferredDefaultAudioSink = node;
        else Pipewire.preferredDefaultAudioSource = node;
    }

    // Volumen (0..1, en pasos de 1 %) y silencio de un nodo, sin el aviso flotante
    function setVolume(node, v) {
        if (!node?.audio) return;
        Osd.quiet();
        node.audio.volume = Math.max(0, Math.min(1, Math.round(v * 100) / 100));
    }
    function toggleMute(node) {
        if (!node?.audio) return;
        Osd.quiet();
        node.audio.muted = !node.audio.muted;
    }

    // Nombres en español de las funciones que da ALSA (device.profile.description)
    readonly property var profileNames: ({
        "Front Headphones": "Auriculares delanteros", "Headphones": "Auriculares",
        "Speakers": "Altavoces", "Speaker": "Altavoz", "S/PDIF Output": "Salida S/PDIF",
        "Line Output": "Salida de línea", "Line Input": "Entrada de línea",
        "Microphone": "Micrófono", "Front Microphone": "Micrófono delantero",
        "Rear Microphone": "Micrófono trasero", "Headset Microphone": "Micrófono de los cascos",
        "Analog Stereo": "Estéreo analógico", "Digital Stereo (IEC958)": "Digital (S/PDIF)"
    })
    function isHdmi(node) {
        return (node?.properties?.["device.profile.name"] ?? "").startsWith("hdmi");
    }
    // Nombre de un dispositivo: el del monitor si es HDMI; si no, su función en español
    function nameOf(node) {
        if (!node) return "";
        const p = node.properties ?? {};
        const profile = p["device.profile.description"] ?? "";
        if (isHdmi(node) && p["node.nick"]) return p["node.nick"];
        if (profile !== "") return profileNames[profile] ?? profile;
        return node.description || node.nickname || node.name;
    }
    // Detalle: el puerto HDMI, o la tarjeta
    function detailOf(node) {
        const p = node?.properties ?? {};
        if (isHdmi(node)) {
            const port = (p["device.profile.description"] ?? "").match(/\((HDMI \d+)\)/);
            return port ? port[1] : "HDMI";
        }
        return p["alsa.card_name"] ?? "";
    }
    // Icono según el tipo de salida
    function iconOf(node) {
        const text = ((node?.description ?? "") + " " + (node?.name ?? "")).toLowerCase();
        if (!node?.isSink) return Theme.iMic;
        if (text.includes("headphone") || text.includes("headset")) return Theme.iHeadphones;
        if (text.includes("hdmi") || text.includes("displayport")) return Theme.iTv;
        return Theme.iSpeaker;
    }
    // Nombre de la app de un flujo
    function appOf(node) {
        const p = node?.properties ?? {};
        return p["application.name"] ?? p["media.name"] ?? nameOf(node);
    }
    function appIconOf(node) {
        const p = node?.properties ?? {};
        return p["application.icon-name"] ?? p["application.process.binary"] ?? "";
    }

    IpcHandler {
        target: "audio"

        function toggle(): void { root.panelRequested(); }
    }
}
