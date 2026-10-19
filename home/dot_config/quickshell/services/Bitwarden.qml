pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Bitwarden con rbw: buscar en la bóveda y copiar usuario (o correo), contraseña o
// código 2FA, y generar contraseñas. rbw-agent mantiene la bóveda abierta y la cierra
// sola tras un rato (rbw config set lock_timeout <segundos>); también se cierra al
// bloquear la pantalla. Cuando rbw necesita la contraseña maestra (o un código 2FA) usa
// scripts/bw-pinentry.py, que pregunta aquí (pin) en lugar de abrir otra ventana.
// Lo copiado no entra en el historial del portapapeles y se borra a los 30 s.
// La ventana está en modules/bitwarden.
//   quickshell ipc call bitwarden toggle | open | close | lock | sync | generator
Singleton {
    id: root

    property bool open: false
    function toggle() {
        open = !open;
    }
    // Abre directamente en el generador
    signal generatorRequested()
    function openGenerator() {
        open = true;
        generatorRequested();
    }
    onOpenChanged: {
        if (open) refresh();
        else if (pin) cancelPin();
    }

    // --- Estado ---
    property bool installed: false
    property bool checked: false
    property string email: ""
    property bool unlocked: false
    // Trabajando (abrir, sincronizar…) y qué
    property string busy: ""
    property string error: ""

    // Entradas: [{ id, name, user, folder, uris, type }] (sin contraseñas)
    property var items: []
    property string query: ""
    readonly property var results: {
        const q = plain(query.trim());
        if (q === "") return items;
        const words = q.split(/\s+/);
        const scored = [];
        for (const it of items) {
            const name = plain(it.name ?? ""), rest = plain([it.user, it.folder].concat(it.uris ?? []).join(" "));
            let score = 0;
            for (const w of words) {
                if (name.startsWith(w)) score += 4;
                else if (name.split(/[\s._-]+/).some(p => p.startsWith(w))) score += 3;
                else if (name.includes(w)) score += 2;
                else if (rest.includes(w)) score += 1;
                else {
                    score = 0;
                    break;
                }
            }
            if (score > 0) scored.push({ it, score });
        }
        scored.sort((a, b) => b.score - a.score || (a.it.name ?? "").localeCompare(b.it.name ?? ""));
        return scored.map(s => s.it);
    }
    function plain(s) {
        return s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
    }

    // Pregunta de rbw en curso: { fifo, title, prompt, desc, error } o null
    property var pin: null

    // Contraseña generada
    property string generated: ""

    readonly property string pinentry: Quickshell.shellPath("scripts/bw-pinentry.py")

    // --- Órdenes ---
    // Lanza un proceso y llama a done(código, salida, errores) cuando termina
    function run(command, done) {
        procComp.createObject(root, { command, done: done ?? null });
    }
    Component {
        id: procComp
        Process {
            id: proc
            property var done
            property int code: -1
            property int pending: 3
            function step() {
                if (--pending > 0) return;
                if (done) done(code, out.text, err.text);
                destroy();
            }
            running: true
            stdout: StdioCollector {
                id: out
                onStreamFinished: proc.step()
            }
            stderr: StdioCollector {
                id: err
                onStreamFinished: proc.step()
            }
            onExited: c => {
                code = c;
                step();
            }
        }
    }

    // Mira si está instalado, la cuenta y si la bóveda está abierta (y carga la lista)
    function refresh() {
        run(["sh", "-c", "command -v rbw >/dev/null || exit 9; rbw config show"], (code, out) => {
            checked = true;
            installed = code !== 9;
            if (!installed) return;
            let config = {};
            try {
                config = JSON.parse(out);
            } catch (e) {}
            email = config.email ?? "";
            // Que rbw pregunte aquí
            if (config.pinentry !== pinentry) run(["rbw", "config", "set", "pinentry", pinentry]);
            if (email !== "") checkUnlocked();
        });
    }
    function checkUnlocked() {
        run(["rbw", "unlocked"], code => {
            unlocked = code === 0;
            if (unlocked && items.length === 0) load();
            if (!unlocked) items = [];
        });
    }
    function load() {
        run(["rbw", "list", "--raw"], (code, out, err) => {
            if (code !== 0) {
                error = firstLine(err);
                return;
            }
            try {
                items = JSON.parse(out).sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""));
                fetchIcons();
            } catch (e) {
                error = "No se pudo leer la lista de rbw";
            }
        });
    }

    // --- Iconos de las webs ---
    // Del servicio de iconos de Bitwarden (como sus apps; solo se le envía el dominio),
    // guardados en caché: scripts/bw-icons.sh. Sin icono, la fila muestra la inicial.
    readonly property string iconDir: Quickshell.cachePath("bitwarden-icons")
    // Dominios con icono ya descargado: { "github.com": true, … }
    property var icons: ({})
    // Dominio de una entrada: el de su primera dirección, o el nombre si parece uno
    function domainOf(item) {
        const uri = (item.uris ?? []).find(u => u) ?? "";
        let host = uri.replace(/^[a-z][a-z0-9+.-]*:\/\//i, "").split(/[\/?#:]/)[0];
        if (host === "" && /^[a-z0-9-]+(\.[a-z0-9-]+)+$/i.test(item.name ?? "")) host = item.name;
        host = host.toLowerCase().replace(/^www\./, "");
        return /^[a-z0-9-]+(\.[a-z0-9-]+)+$/.test(host) ? host : "";
    }
    function iconOf(item) {
        const d = domainOf(item);
        return d !== "" && icons[d] ? `file://${iconDir}/${d}.png` : "";
    }
    // Los ya guardados salen al momento; los nuevos, según llegan (una línea por dominio)
    function fetchIcons() {
        const domains = [...new Set(items.map(domainOf).filter(d => d !== ""))];
        if (domains.length === 0 || iconProc.running) return;
        iconProc.command = ["sh", Quickshell.shellPath("scripts/bw-icons.sh"), iconDir].concat(domains);
        iconProc.running = true;
    }
    Process {
        id: iconProc
        stdout: SplitParser {
            onRead: d => {
                if (d === "" || root.icons[d]) return;
                const next = Object.assign({}, root.icons);
                next[d] = true;
                root.icons = next;
            }
        }
    }
    // Errores de rbw conocidos, en español
    function explain(err) {
        if (/api key/i.test(err)) return "La clave de la API no es correcta (client_id o client_secret de otra cuenta, o copiados a medias)";
        if (/device/i.test(err)) return "Bitwarden no reconoce este equipo: hace falta la clave de la API";
        if (/password|incorrect|invalid_grant/i.test(err)) return "Correo o contraseña incorrectos";
        if (/400|401/.test(err)) return "Bitwarden rechazó el inicio de sesión (revisa la contraseña o la clave de la API)";
        return firstLine(err);
    }
    function isEmail(text) {
        return /^[^\s@]+@[^\s@]+$/.test(text ?? "");
    }
    function firstLine(text) {
        return text.trim().split("\n").pop().replace(/^rbw [a-z-]+: /, "");
    }

    // Primera vez: guarda el correo e inicia sesión (rbw pregunta la contraseña aquí)
    function setup(mail) {
        if (mail.trim() === "") return;
        error = "";
        busy = "Iniciando sesión…";
        registered = false;
        run(["sh", "-c", 'rbw config set email "$1" && rbw config set pinentry "$2"', "sh", mail.trim(), pinentry], code => {
            email = mail.trim();
            login();
        });
    }
    // Ya se intentó registrar el equipo en este intento
    property bool registered: false
    function login() {
        error = "";
        busy = "Iniciando sesión…";
        run(["rbw", "login"], (code, out, err) => {
            if (!needsRegister(code, err)) finish(code, err);
        });
    }
    // rbw unlock también inicia sesión si hace falta, con los mismos errores
    // Desbloquear con la contraseña escrita en el panel: cuando rbw la pida, se responde
    // sola (también si vuelve a pedirla tras registrar el equipo). Se olvida al terminar.
    property string masterPassword: ""
    function unlockWith(password) {
        if (busy !== "" || password === "") return;
        masterPassword = password;
        unlock();
    }
    function unlock() {
        error = "";
        busy = "Abriendo la bóveda…";
        registered = false;
        run(["rbw", "unlock"], (code, out, err) => {
            if (!needsRegister(code, err)) finish(code, err);
        });
    }
    // Equipo nuevo: bitwarden.com pide verificarlo ("New device verification required",
    // que rbw solo muestra como error 400). Se registra con la clave de la API (rbw
    // register la pregunta aquí) y se vuelve a iniciar sesión.
    function needsRegister(code, err) {
        if (code === 0 || registered || /cancel|incorrect|invalid/i.test(err) || !/400|device|register/i.test(err)) return false;
        registered = true;
        busy = "Bitwarden pide verificar este equipo: escribe la clave de la API";
        run(["rbw", "register"], (c2, o2, e2) => {
            if (c2 === 0) login();
            else finish(c2, e2);
        });
        return true;
    }
    // La contraseña maestra escrita en el panel no era correcta
    property bool wrongPassword: false
    function finish(code, err) {
        masterPassword = "";
        busy = "";
        if (wrongPassword) error = "Contraseña incorrecta";
        else if (code !== 0 && !/cancel/i.test(err)) error = explain(err);
        wrongPassword = false;
        checkUnlocked();
    }

    function lock() {
        items = [];
        unlocked = false;
        run(["rbw", "lock"]);
    }
    // Cambiar de cuenta: cierra la bóveda, borra la copia local (la de la web no se toca),
    // para el agente y olvida el correo; el panel vuelve a "Inicia sesión"
    function switchAccount() {
        if (busy !== "") return;
        items = [];
        unlocked = false;
        error = "";
        busy = "Cerrando la sesión…";
        run(["sh", "-c", "rbw lock; rbw purge; rbw stop-agent; rbw config unset email"], () => {
            busy = "";
            email = "";
            refresh();
        });
    }
    function sync() {
        if (!unlocked) return;
        error = "";
        busy = "Sincronizando…";
        run(["rbw", "sync"], (code, out, err) => {
            busy = "";
            if (code !== 0) error = firstLine(err);
            else load();
        });
    }

    // --- Copiar ---
    // what: "password" | "username" | "totp". Se cierra el panel (para pegar) y avisa.
    function copy(item, what) {
        if (!item) return;
        open = false;
        const names = { password: "Contraseña", username: isEmail(item.user) ? "Correo" : "Usuario", totp: "Código 2FA" };
        if (what === "username") {
            Quickshell.execDetached(["wl-copy", "--", item.user ?? ""]);
            notify(`${names[what]} de ${item.name} copiado`);
            return;
        }
        // El valor no pasa por aquí: va de rbw al portapapeles (marcado como sensible, así
        // cliphist no lo guarda) y se borra a los 30 s si sigue ahí
        const get = what === "totp" ? 'rbw code "$1"' : 'rbw get "$1"';
        run(["sh", "-c", `v=$(${get}) || exit 1; [ -n "$v" ] || exit 2
printf %s "$v" | wl-copy --sensitive
(sleep 30; [ "$(wl-paste -n 2>/dev/null)" = "$v" ] && wl-copy --clear) >/dev/null 2>&1 &`, "sh", item.id], (code, out, err) => {
            if (code === 0) notify(`${names[what]} de ${item.name} copiada · se borra en 30 s`);
            else if (what === "totp") notify(`${item.name} no tiene código 2FA`);
            else notify(`No se pudo copiar: ${firstLine(err) || "entrada vacía"}`);
        });
    }

    // --- Generador --- kind: "all" | "nosymbols" | "numbers" | "words"
    function generate(kind, length) {
        const flag = { nosymbols: ["--no-symbols"], numbers: ["--only-numbers"], words: ["--diceware"] }[kind] ?? [];
        run(["rbw", "generate"].concat(flag, [String(length)]), (code, out) => {
            if (code === 0) generated = out.trim();
        });
    }
    function copyGenerated() {
        if (generated === "") return;
        Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy --sensitive', "sh", generated]);
        notify("Contraseña generada copiada");
    }

    function notify(text) {
        Quickshell.execDetached(["notify-send", "-a", "Bitwarden", "-i", Quickshell.shellPath("assets/bitwarden.svg"), "-t", "3000", "Bitwarden", text]);
    }

    // --- Preguntas de rbw (desde bw-pinentry.py) ---
    function answerPin(text) {
        if (!pin) return;
        writeFifo(pin.fifo, "1" + text);
        pin = null;
    }
    function cancelPin() {
        if (!pin) return;
        writeFifo(pin.fifo, "0");
        pin = null;
    }
    // La respuesta va por la entrada del proceso, no en sus argumentos
    function writeFifo(fifo, data) {
        fifoComp.createObject(root, { fifo, data });
    }
    Component {
        id: fifoComp
        Process {
            property string fifo
            property string data
            command: ["sh", "-c", 'cat > "$1"', "sh", fifo]
            stdinEnabled: true
            running: true
            onStarted: {
                write(data);
                data = "";
                stdinEnabled = false;
            }
            onExited: destroy()
        }
    }

    // Comprueba de vez en cuando si rbw-agent cerró la bóveda por inactividad
    Timer {
        interval: 30000
        running: root.unlocked
        repeat: true
        onTriggered: root.checkUnlocked()
    }

    // Al bloquear la pantalla, también la bóveda
    Connections {
        target: Lock
        function onLockedChanged() {
            if (Lock.locked && root.unlocked) root.lock();
        }
    }

    Component.onCompleted: refresh()

    IpcHandler {
        target: "bitwarden"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
        function lock(): void { root.lock(); }
        function sync(): void { root.sync(); }
        function generator(): void { root.openGenerator(); }
        function ping(): bool { return true; }
        // Lo llama scripts/bw-pinentry.py
        function askPin(fifo: string, title: string, prompt: string, desc: string, error: string): void {
            if (root.pin) root.cancelPin();
            // La contraseña maestra ya escrita en el panel: se responde sola. Si rbw dice
            // que no es correcta, se cancela y se avisa en el panel.
            if (root.masterPassword !== "" && /master password/i.test(prompt)) {
                if (error === "") {
                    root.writeFifo(fifo, "1" + root.masterPassword);
                } else {
                    root.writeFifo(fifo, "0");
                    root.masterPassword = "";
                    root.wrongPassword = true;
                }
                return;
            }
            root.pin = { fifo, title, prompt, desc, error };
            root.open = true;
        }
        function cancelPin(): void { root.pin = null; }
    }
}
