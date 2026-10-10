pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

// Inicio de sesión con greetd: usuario + contraseña, y lanza la sesión elegida
// (las de /usr/share/wayland-sessions).
Singleton {
    id: root

    property string user: Theme.user
    property string password: ""
    property bool busy: false
    property string error: ""
    // Aumenta en cada intento fallido (lo usa la animación de temblor)
    property int failCount: 0

    // Sesiones disponibles: [{ name, command: [...] }]
    property var sessions: []
    property int sessionIndex: 0
    readonly property var session: sessions[sessionIndex] ?? null

    function nextSession(step) {
        if (sessions.length > 0)
            sessionIndex = (sessionIndex + step + sessions.length) % sessions.length;
    }

    function fail(message) {
        busy = false;
        password = "";
        error = message;
        failCount++;
    }

    function submit() {
        if (busy || password === "" || user === "") return;
        if (!Greetd.available) {
            fail("greetd no está disponible (vista previa)");
            return;
        }
        busy = true;
        error = "";
        Greetd.createSession(user);
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) Greetd.respond(root.password);
            else if (error) root.error = message;
        }
        function onAuthFailure(message) {
            root.fail("Contraseña incorrecta");
        }
        function onReadyToLaunch() {
            // Al lanzar, Quickshell se cierra y el Hyprland del greeter también
            Greetd.launch(root.session?.command ?? ["start-hyprland"], ["XDG_SESSION_TYPE=wayland"], true);
        }
        function onError(error) {
            Greetd.cancelSession();
            root.fail(`Error: ${error}`);
        }
    }

    // Lee nombre y comando de cada sesión; Hyprland queda elegida por defecto
    Process {
        running: true
        command: ["sh", "-c", `for f in /usr/share/wayland-sessions/*.desktop; do
            n=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
            e=$(grep -m1 '^Exec=' "$f" | cut -d= -f2-)
            printf '%s\\t%s\\n' "$n" "$e"
        done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = this.text.trim().split("\n").filter(l => l.includes("\t")).map(l => {
                    const [name, exec] = l.split("\t");
                    // Quita los códigos de campo de los .desktop (%U, %f…)
                    return { name, command: exec.split(/\s+/).filter(a => a !== "" && !/^%./.test(a)) };
                });
                root.sessions = list;
                const i = list.findIndex(s => s.name === "Hyprland");
                root.sessionIndex = i >= 0 ? i : 0;
            }
        }
    }
}
