pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Servidores locales: lo que tienes escuchando en puertos (un servidor de desarrollo,
// una API, una base de datos…), con su proceso y su proyecto. Se revisa cada pocos
// segundos (más seguido con el panel abierto). Los servicios en segundo plano
// conocidos (el de OpenCode) van aparte y no cuentan para el icono de la barra.
// El panel está en modules/servers.
//   quickshell ipc call servers toggle
Singleton {
    id: root

    // { port, address, pid, name, cwd, project, command, http }
    property var all: []
    // Servicios en segundo plano conocidos
    function isService(s) {
        return /opencode serve --service/.test(s.command);
    }
    readonly property var servers: all.filter(s => !isService(s))
    readonly property var services: all.filter(s => isService(s))

    property bool panelOpen: false
    signal panelRequested()

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    Process {
        id: proc
        command: ["python3", "-I", Quickshell.shellPath("scripts/local-servers.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.all = JSON.parse(this.text);
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: root.panelOpen ? 3000 : 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // --- Acciones ---
    function url(s) {
        return `http://localhost:${s.port}`;
    }
    function open(s) {
        Qt.openUrlExternally(url(s));
    }
    function copy(s) {
        Quickshell.execDetached(["wl-copy", url(s)]);
    }
    function openProject(s) {
        if (s.project) Quickshell.execDetached(["zeditor", s.project]);
    }
    // Detener: SIGTERM (si no se cierra, al volver a pulsar, SIGKILL)
    property var stopping: ({})
    function stop(s) {
        const force = stopping[s.pid] === true;
        Quickshell.execDetached(["kill", force ? "-KILL" : "-TERM", String(s.pid)]);
        const st = Object.assign({}, stopping);
        st[s.pid] = true;
        stopping = st;
        Qt.callLater(refresh);
        recheck.restart();
    }
    Timer {
        id: recheck
        interval: 1000
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "servers"

        function toggle(): void { root.panelRequested(); }
    }
}
