pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Teclado AULA F75 Max (por cable): luces, pantalla, ajustes y reloj, a través de
// ~/.local/bin/aulactl. El teclado no deja leer su configuración: lo que se muestra es
// lo último aplicado (lo guarda aulactl). La ventana es modules/keyboard/KeyboardWindow.qml.
//   quickshell ipc call keyboard toggle | openTab 0-2 | syncClock
Singleton {
    id: root

    property bool open: false
    property real closedAt: 0
    // Pestaña de la ventana: 0 = luces, 1 = pantalla, 2 = ajustes
    property int tab: 0

    function toggle() {
        if (!open && Date.now() - closedAt < 300) return;
        open = !open;
        if (open) refresh();
    }
    function close() {
        if (!open) return;
        open = false;
        closedAt = Date.now();
    }

    // La subida a la pantalla todavía no es fiable (el teclado mezcla los fotogramas
    // nuevos con restos de su memoria): oculta hasta capturar el protocolo del programa
    // oficial. Ver aulactl screen / screen-clear.
    readonly property bool screenReady: false

    // --- Estado (aulactl status) ---
    property bool available: false // aulactl instalado
    property bool connected: false
    property var light: ({})
    property var settings: ({})
    property var screen: ({})
    property var clock: ({})

    // Efectos (índice = byte del firmware), con nombre en español y qué opciones usan
    readonly property var modes: [
        { id: "off", name: "Apagado" },
        { id: "static", name: "Fijo", color: true },
        { id: "reactive", name: "Reactivo", color: true, speed: true },
        { id: "reactive-fade", name: "Reactivo suave", color: true, speed: true },
        { id: "glitter", name: "Destellos", color: true, speed: true },
        { id: "rain", name: "Lluvia", color: true, speed: true },
        { id: "colourful", name: "Colorido", speed: true },
        { id: "breathing", name: "Respiración", color: true, speed: true },
        { id: "spectrum", name: "Espectro", speed: true },
        { id: "outward", name: "Hacia fuera", color: true, speed: true },
        { id: "wave", name: "Ola", color: true, speed: true, direction: true },
        { id: "rolling", name: "Rodante", color: true, speed: true, direction: true },
        { id: "rotating", name: "Giratorio", color: true, speed: true, direction: true },
        { id: "explode", name: "Explosión", color: true, speed: true },
        { id: "launch", name: "Lanzamiento", color: true, speed: true },
        { id: "ripple", name: "Ondas", color: true, speed: true },
        { id: "flowing", name: "Fluido", color: true, speed: true, direction: true },
        { id: "pulse", name: "Pulso", color: true, speed: true },
        { id: "tilt", name: "Inclinación", color: true, speed: true, direction: true },
        { id: "shuttle", name: "Lanzadera", color: true, speed: true }
    ]
    readonly property var mode: modes.find(m => m.id === light.mode) ?? modes[0]

    function refresh() {
        statusProc.running = true;
    }

    Process {
        id: statusProc
        command: ["aulactl", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text);
                    root.available = true;
                    const wasConnected = root.connected;
                    root.connected = d.connected;
                    root.light = d.light;
                    root.settings = d.settings;
                    root.screen = d.screen;
                    root.clock = d.clock;
                    // Al conectar el teclado: la hora al día
                    if (d.connected && !wasConnected) root.syncClock();
                } catch (e) {
                    root.available = false;
                }
            }
        }
    }

    // Comprueba la conexión cada 10 s (y al iniciar)
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
    // El reloj del teclado se desvía: se vuelve a sincronizar cada hora
    Timer {
        interval: 3600000
        running: root.connected
        repeat: true
        onTriggered: root.syncClock()
    }

    // --- Comandos (en cola: el teclado atiende una transacción a la vez) ---
    property var queue: []
    property bool busy: runner.running
    property string error: ""
    // Subida de la pantalla: 0..1 (o -1 si no hay ninguna en curso)
    property real uploadProgress: -1

    function run(args) {
        queue = queue.concat([args]);
        if (!runner.running) next();
    }
    function next() {
        if (queue.length === 0) return;
        runner.command = ["aulactl"].concat(queue[0]);
        queue = queue.slice(1);
        runner.running = true;
    }

    Process {
        id: runner
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/^progress (\d+) (\d+)/);
                if (m) root.uploadProgress = Number(m[1]) / Number(m[2]);
            }
        }
        stderr: StdioCollector {
            id: runnerErr
        }
        onExited: code => {
            const text = runnerErr.text.trim();
            root.error = code === 0 ? "" : (text.replace(/^aulactl: /, "") || "No se pudo aplicar");
            root.uploadProgress = -1;
            root.refresh();
            root.next();
        }
    }

    // Luces: los cambios se agrupan (al arrastrar o hacer varios clics seguidos)
    property var pendingLight: null
    function setLight(changes) {
        light = Object.assign({}, pendingLight ?? light, changes);
        pendingLight = light;
        lightTimer.restart();
    }
    Timer {
        id: lightTimer
        interval: 250
        onTriggered: {
            const l = root.pendingLight;
            root.pendingLight = null;
            root.run(["light", l.mode, "--color", l.color, "--multicolor", l.multicolor ? "on" : "off",
                "--brightness", String(l.brightness), "--speed", String(l.speed), "--direction", l.direction]);
        }
    }

    function setSettings(changes) {
        settings = Object.assign({}, settings, changes);
        const s = settings;
        run(["settings", "--response", String(s.response), "--sleep", s.sleep,
            "--win-lock", s.winLock ? "on" : "off", "--alt-f4-lock", s.altF4Lock ? "on" : "off",
            "--alt-tab-lock", s.altTabLock ? "on" : "off", "--fn-switch", s.fnSwitch ? "on" : "off"]);
    }

    function syncClock(twelveHour) {
        const twelve = twelveHour ?? clock.twelveHour ?? false;
        run(twelve ? ["clock", "--12h"] : ["clock"]);
    }

    function setScreen(file, fit) {
        uploadProgress = 0;
        run(["screen", file, "--fit", fit ?? screen.fit ?? "fill"]);
    }

    IpcHandler {
        target: "keyboard"

        function toggle(): void { root.toggle(); }
        // Abre la ventana en una pestaña: 0 = luces, 1 = pantalla, 2 = ajustes
        function openTab(tab: int): void {
            root.tab = tab;
            if (!root.open) root.toggle();
        }
        function syncClock(): void { root.syncClock(); }
    }

}
