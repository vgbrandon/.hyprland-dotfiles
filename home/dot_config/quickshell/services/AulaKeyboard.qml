pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Teclado AULA F75 Max (por cable): luces, pantalla, teclas, ajustes y reloj, a través
// de ~/.local/bin/aulactl. El teclado no deja leer su configuración: lo que se muestra es
// lo último aplicado (lo guarda aulactl). La ventana es modules/keyboard/KeyboardWindow.qml.
//   quickshell ipc call keyboard toggle | openTab 0-4 | syncClock
Singleton {
    id: root

    property bool open: false
    property real closedAt: 0
    // Sección de la ventana: 0 = inicio, 1 = luces, 2 = pantalla, 3 = teclas, 4 = ajustes
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


    // --- Estado (aulactl status) ---
    property bool available: false // aulactl instalado
    property bool connected: false
    property var light: ({})
    property var settings: ({})
    property var screen: ({})
    property var clock: ({})
    property var keys: ({})
    // Modelo, firmware, rutas de hidraw y si hay permiso
    property var device: ({})

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

    // Ruta completa: la sesión (Hyprland) no tiene ~/.local/bin en el PATH
    readonly property string aulactl: Quickshell.env("HOME") + "/.local/bin/aulactl"

    function refresh() {
        statusProc.running = true;
    }

    Process {
        id: statusProc
        command: [root.aulactl, "status"]
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
                    root.keys = d.keys ?? {};
                    root.device = d.device ?? {};
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
    // Lo que está haciendo (para mostrarlo): "", o el texto de la operación en curso
    property string task: ""
    // Subida de la pantalla: 0..1 (o -1 si no hay ninguna en curso) y su etapa
    property real uploadProgress: -1
    property string uploadStep: ""
    // Último aviso de una operación que terminó bien
    property string notice: ""

    // done: el aviso al terminar bien (opcional)
    function run(args, label, done) {
        queue = queue.concat([{ args, label: label ?? "", done: done ?? "" }]);
        if (!runner.running) next();
    }
    property var current: null
    function next() {
        if (queue.length === 0) {
            task = "";
            return;
        }
        current = queue[0];
        queue = queue.slice(1);
        task = current.label;
        runner.command = [root.aulactl].concat(current.args);
        runner.running = true;
    }

    Process {
        id: runner
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/^progress (\w+) (\d+) (\d+)/);
                if (!m) return;
                root.uploadStep = m[1];
                if (m[1] === "upload") root.uploadProgress = Number(m[2]) / Number(m[3]);
                else if (m[1] === "commit") root.uploadProgress = 1;
            }
        }
        stderr: StdioCollector {
            id: runnerErr
        }
        onExited: code => {
            const text = runnerErr.text.trim();
            root.error = code === 0 ? "" : (text.replace(/^aulactl: /, "") || "No se pudo aplicar");
            if (code === 0 && root.current?.done) root.notice = root.current.done;
            root.uploadProgress = -1;
            root.uploadStep = "";
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
        uploadStep = "clear";
        run(["screen", file, "--fit", fit ?? screen.fit ?? "fill"], "Enviando a la pantalla…", "Imagen enviada a la pantalla");
    }
    function clearScreen() {
        run(["screen-clear"], "Borrando la memoria de la pantalla…", "Memoria de la pantalla borrada");
    }

    // Caps Lock como Ctrl (en el firmware: funciona en cualquier equipo)
    function setCapsCtrl(on) {
        keys = Object.assign({}, keys, { capsCtrl: on });
        run(["caps-ctrl", on ? "on" : "off"], "Cambiando Caps Lock…", on ? "Caps Lock ahora es Ctrl" : "Caps Lock restaurado");
    }

    // Restablecer: "data" (teclas e iluminación) o "factory" (todo, también la pantalla)
    function reset(kind) {
        run([kind === "factory" ? "factory-reset" : "reset-data"], "Restableciendo el teclado…",
            kind === "factory" ? "Teclado restablecido de fábrica" : "Teclas e iluminación restablecidas");
    }

    // Comprueba que el teclado responde
    property string probeResult: ""
    function probe() {
        probeResult = "";
        probeProc.running = true;
    }
    Process {
        id: probeProc
        command: [root.aulactl, "probe"]
        stdout: StdioCollector {
            onStreamFinished: root.probeResult = this.text.includes('"ok": true') ? "ok" : root.probeResult
        }
        onExited: code => {
            if (code !== 0) root.probeResult = "error";
        }
    }

    // --- Estado de la ventana (modules/keyboard) ---
    // Imágenes y GIF de ~/Pictures (las más recientes primero) para la pantalla
    property var images: []
    function loadImages() {
        pictures.running = true;
    }
    Process {
        id: pictures
        command: ["sh", "-c", `find "$HOME/Pictures" -maxdepth 2 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.webp' \\) -printf '%T@ %p\\n' 2>/dev/null | sort -rn | cut -d' ' -f2- | head -80`]
        stdout: StdioCollector {
            onStreamFinished: root.images = this.text.split("\n").filter(l => l !== "")
        }
    }
    // La imagen elegida para la pantalla (antes de enviarla) y su encaje
    property string pickedImage: ""
    property string pickedFit: screen.fit ?? "fill"
    // Acción que borra esperando el segundo clic: "", "data", "factory", "clear"
    property string confirming: ""
    property Timer confirmTimer: Timer {
        interval: 4000
        onTriggered: root.confirming = ""
    }
    // Colores vivos para los LED (los pastel del tema salen casi blancos)
    readonly property var swatches: ["#ffffff", "#ff0000", "#ff6000", "#ffd000", "#00ff00",
        "#00ffd0", "#00a0ff", "#0040ff", "#8000ff", "#ff00a0"]
    // Último efecto encendido (para volver a encender las luces)
    property string lastMode: ""
    onLightChanged: if (light.mode && light.mode !== "off") lastMode = light.mode

    IpcHandler {
        target: "keyboard"

        function toggle(): void { root.toggle(); }
        // Abre la ventana en una sección: 0 = inicio, 1 = luces, 2 = pantalla, 3 = teclas,
        // 4 = ajustes
        function openTab(tab: int): void {
            root.tab = tab;
            if (!root.open) root.toggle();
        }
        function syncClock(): void { root.syncClock(); }
    }

}
