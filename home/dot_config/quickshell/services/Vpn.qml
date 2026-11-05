pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// VPN con el cliente oficial de Proton (protonvpn, del paquete proton-vpn-cli): la lógica.
// El estado (conectado o no, y a qué servidor) sale de NetworkManager, donde Proton crea la
// conexión «ProtonVPN <servidor>»: nmcli monitor avisa de cada cambio y no hace falta el
// llavero. Las órdenes a Proton (conectar, desconectar, estado, ajustes) van en cola y
// cada una mira antes si el llavero del sistema está bloqueado: Proton guarda ahí la
// sesión y, bloqueado, se queda esperando. Entonces no se lanza y el panel ofrece
// desbloquearlo (scripts/keyring-unlock.py, con el diálogo de contraseña); al desbloquear
// se repite lo que se pidió. El panel es modules/vpn/VpnPanel.qml.
//   quickshell ipc call vpn toggle | connect | disconnect | refresh | panel | state
Singleton {
    id: root

    // --- Conexión ---
    property bool connected: false
    property string server: ""          // p. ej. US-FREE#89
    property string location: ""        // p. ej. Miami, United States
    property int load: -1
    property string protocol: ""
    property string ip: ""              // IP pública (con o sin VPN)
    property string ipPlace: ""

    // --- Acciones ---
    property string action: ""          // "connect", "disconnect" o "" (nada en curso)
    readonly property bool busy: action !== ""
    // Lo que se ve en el interruptor: mientras se conecta o desconecta, lo pedido
    readonly property bool wanted: action === "connect" ? true : action === "disconnect" ? false : connected
    property string notice: ""
    property bool locked: false         // el llavero está bloqueado
    property bool unlocking: false

    // --- Cuenta y ajustes ---
    property string account: ""
    property int maxTier: 0             // 0 = plan gratuito (sin elegir país)
    readonly property bool free: maxTier === 0
    property bool killSwitch: false
    property bool ipv6: false

    readonly property string cli: "protonvpn"

    // Abrir el panel en el monitor principal (desde un atajo o por IPC)
    signal panelRequested()

    function connect() {
        if (busy) return;
        action = "connect";
        notice = "";
        run(["connect"], (out, code) => {
            action = "";
            if (code === 0) {
                refreshState();
                details();
            } else {
                notice = errorText(out) || "No se pudo conectar";
            }
        }, "connect");
    }
    function disconnect() {
        if (busy) return;
        action = "disconnect";
        notice = "";
        run(["disconnect"], (out, code) => {
            action = "";
            // protonvpn disconnect sale con código 1 aunque desconecte bien: vale lo que dice
            if (code !== 0 && !/Disconnected/.test(out)) notice = errorText(out) || "No se pudo desconectar";
            refreshState();
        }, "disconnect");
    }
    function toggle() {
        connected ? disconnect() : connect();
    }
    function setKillSwitch(on) {
        run(["config", "set", "kill-switch", on ? "standard" : "off"], (out, code) => {
            if (code === 0) killSwitch = on;
            else notice = errorText(out) || "No se pudo cambiar el kill switch";
        });
    }
    function setIpv6(on) {
        run(["config", "set", "ipv6", on ? "on" : "off"], (out, code) => {
            if (code === 0) ipv6 = on;
            else notice = errorText(out) || "No se pudo cambiar IPv6";
        });
    }

    // Todo lo del panel al abrirlo: estado, ajustes, cuenta, plan e IP pública
    function refresh() {
        refreshState();
        settings();
        run(["info"], (out, code) => {
            const m = out.match(/Account:\s*'?([^'\n]+)'?/);
            if (m) account = m[1].trim();
        });
        planProc.running = true;
        fetchIp();
    }

    // Servidor, carga y protocolo (con la VPN puesta)
    function details() {
        run(["status"], (out, code) => {
            const s = out.match(/Server:\s*(\S+)\s+in\s+(.+)/);
            if (s) {
                server = s[1];
                location = s[2].trim();
            }
            const l = out.match(/Load:\s*(\d+)/);
            load = l ? parseInt(l[1]) : -1;
            const p = out.match(/Protocol:\s*(\S+)/);
            protocol = p ? p[1] : "";
        });
    }
    function settings() {
        run(["config", "list"], (out, code) => {
            const k = out.match(/kill-switch\s+(\S+)/);
            if (k) killSwitch = k[1] !== "off";
            const v = out.match(/ipv6\s+(\S+)/);
            if (v) ipv6 = v[1] === "on";
        });
    }
    // Lo que dice Proton cuando falla (su línea «Error: …»)
    function errorText(out) {
        const m = out.match(/Error:\s*(.+)/);
        return m ? m[1].trim() : "";
    }

    // --- Cola de órdenes a Proton ---
    property var queue: []
    property var job: null
    // pendiente: la acción que se repite al desbloquear el llavero
    property string pending: ""
    function run(args, done, pendingAction) {
        queue = queue.concat([{ args: args, done: done, pending: pendingAction ?? "" }]);
        next();
    }
    function next() {
        if (job || queue.length === 0) return;
        job = queue[0];
        queue = queue.slice(1);
        // Si el llavero está bloqueado no se lanza (Proton se quedaría esperando)
        cliProc.command = ["sh", "-c", `
            if busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/aliases/default \
                org.freedesktop.Secret.Collection Locked 2>/dev/null | grep -q true; then
                echo __BLOQUEADO__; exit 75
            fi
            exec timeout 90 "$0" "$@" 2>&1`, cli].concat(job.args);
        cliProc.running = true;
    }
    Process {
        id: cliProc
        stdout: StdioCollector { id: cliOut }
        onExited: code => {
            const j = root.job;
            root.job = null;
            const out = cliOut.text;
            if (out.includes("__BLOQUEADO__")) {
                // Todo lo que esperaba se descarta; se repite la acción al desbloquear
                root.locked = true;
                root.queue = [];
                root.action = "";
                if (j?.pending) root.pending = j.pending;
            } else {
                root.locked = false;
                if (code === 124) j?.done("Error: Proton no respondió a tiempo", 124);
                else j?.done(out, code);
            }
            root.next();
        }
    }

    // Desbloquear el llavero (diálogo de contraseña) y repetir lo pendiente
    // Pulsar otra vez mientras espera relanza el diálogo (si el anterior no llegó a salir)
    function unlock() {
        notice = "";
        if (unlocking) {
            relaunch = true;
            unlockProc.running = false;
            return;
        }
        unlocking = true;
        unlockProc.running = true;
    }
    property bool relaunch: false
    Timer {
        id: relaunchTimer
        interval: 300
        onTriggered: {
            root.unlocking = true;
            unlockProc.running = true;
        }
    }
    Process {
        id: unlockProc
        command: ["python3", Quickshell.shellPath("scripts/keyring-unlock.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                root.unlocking = false;
                if (root.relaunch) {
                    root.relaunch = false;
                    relaunchTimer.start();
                    return;
                }
                const r = this.text.trim();
                if (r === "desbloqueado" || r === "ya estaba desbloqueado") {
                    root.locked = false;
                    const p = root.pending;
                    root.pending = "";
                    root.refresh();
                    if (p === "connect") root.connect();
                    else if (p === "disconnect") root.disconnect();
                } else {
                    root.notice = r === "cancelado" ? "Desbloqueo cancelado" : "El llavero no respondió";
                }
            }
        }
    }

    // --- Estado desde NetworkManager ---
    Process {
        id: monitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: stateTimer.restart()
        }
        // Si nmcli monitor se cae, se vuelve a lanzar
        onExited: restartMonitor.start()
    }
    Timer {
        id: restartMonitor
        interval: 5000
        onTriggered: monitor.running = true
    }
    Timer {
        id: stateTimer
        interval: 400
        onTriggered: root.refreshState()
    }
    function refreshState() {
        stateProc.running = true;
    }
    Process {
        id: stateProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.split("\n").find(l => l.startsWith("ProtonVPN "));
                const was = root.connected;
                root.connected = !!line;
                if (line) {
                    root.server = line.slice("ProtonVPN ".length).split(":")[0];
                    if (!was) {
                        root.details();
                        root.fetchIp();
                    }
                } else if (was) {
                    root.server = "";
                    root.location = "";
                    root.load = -1;
                    root.protocol = "";
                    root.fetchIp();
                }
            }
        }
    }
    Component.onCompleted: {
        refreshState();
        fetchIp();
        planProc.running = true;
    }

    // IP pública y desde dónde se ve
    function fetchIp() {
        ipProc.running = true;
    }
    Process {
        id: ipProc
        command: ["curl", "-s", "--max-time", "8", "https://ipinfo.io/json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text);
                    root.ip = d.ip ?? "";
                    root.ipPlace = [d.city, d.country].filter(x => x).join(", ");
                } catch (e) {
                    root.ip = "";
                    root.ipPlace = "";
                }
            }
        }
    }

    // Plan de la cuenta: MaxTier de la lista de servidores que guarda Proton
    Process {
        id: planProc
        command: ["python3", "-I", "-c", "import json, os\ntry:\n    print(json.load(open(os.path.expanduser('~/.cache/Proton/VPN/serverlist.json'))).get('MaxTier', 0))\nexcept Exception:\n    print(0)"]
        stdout: StdioCollector {
            onStreamFinished: root.maxTier = parseInt(this.text.trim()) || 0
        }
    }

    IpcHandler {
        target: "vpn"
        function toggle(): void { root.toggle(); }
        function connect(): void { root.connect(); }
        function disconnect(): void { root.disconnect(); }
        function refresh(): void { root.refresh(); }
        function panel(): void { root.panelRequested(); }
        // Para scripts: «conectado US-FREE#89 · Miami, United States» o «desconectado», y el aviso
        function state(): string {
            return (root.connected ? "conectado " + root.server + (root.location ? " · " + root.location : "") : "desconectado")
                + (root.busy ? " (" + root.action + " en curso)" : "") + (root.notice ? " | aviso: " + root.notice : "");
        }
    }
}
