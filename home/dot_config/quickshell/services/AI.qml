pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Asistente de IA conectado a OpenCode (su servicio de fondo, "opencode service"): las
// conversaciones son las mismas que en la terminal (opencode -c las continúa). El panel
// está en modules/ai/AIPanel.qml.
//   - Conexión: lee la contraseña de ~/.config/opencode/service.json y la dirección con
//     "opencode service status" (si está parado, lo arranca).
//   - Peticiones con XMLHttpRequest; los eventos en vivo (respuesta mientras se escribe,
//     herramientas, permisos…) con curl sobre /api/event.
//   - Mensajes y partes son objetos (Message / Part) para que el texto que va llegando
//     actualice solo lo suyo y no toda la lista.
//   quickshell ipc call ai toggle | open | close | newChat | ask "texto"
Singleton {
    id: root

    property bool open: false
    property real closedAt: 0

    function toggle() {
        if (!open && Date.now() - closedAt < 300) return;
        open = !open;
    }
    function close() {
        if (!open) return;
        open = false;
        closedAt = Date.now();
    }
    onOpenChanged: if (open && status !== "ready") connect()

    // --- Conexión ---
    readonly property string opencode: Quickshell.env("HOME") + "/.opencode/bin/opencode"
    property string url: ""
    property string password: ""
    // connecting | ready | error
    property string status: "connecting"
    property string statusText: "Conectando con OpenCode…"
    property int attempts: 0

    function connect() {
        status = "connecting";
        statusText = "Conectando con OpenCode…";
        serviceFile.reload();
        statusProc.running = true;
    }

    FileView {
        id: serviceFile
        path: Quickshell.env("HOME") + "/.config/opencode/service.json"
        printErrors: false
        onLoaded: {
            try {
                root.password = JSON.parse(text()).password ?? "";
            } catch (e) {
                root.password = "";
            }
        }
    }

    Process {
        id: statusProc
        command: [root.opencode, "service", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text.trim();
                if (out.startsWith("http")) {
                    root.url = out;
                    root.attempts = 0;
                    root.status = "ready";
                    events.running = true;
                    root.loadAll();
                } else if (root.attempts < 3) {
                    // Parado: se arranca y se vuelve a mirar
                    root.attempts++;
                    root.statusText = "Iniciando el servicio de OpenCode…";
                    startProc.running = true;
                } else {
                    root.fail("No se pudo iniciar el servicio de OpenCode");
                }
            }
        }
        onExited: code => { if (code !== 0) root.fail("No se encontró OpenCode (~/.opencode/bin/opencode)"); }
    }
    Process {
        id: startProc
        command: [root.opencode, "service", "start"]
        onExited: retryTimer.restart()
    }
    Timer {
        id: retryTimer
        interval: 1500
        onTriggered: {
            serviceFile.reload();
            statusProc.running = true;
        }
    }

    function fail(text) {
        status = "error";
        statusText = text;
    }

    // Eventos en vivo. La contraseña va por la entrada estándar de curl (no se ve en ps).
    Process {
        id: events
        command: ["sh", "-c", 'printf \'user = "opencode:%s"\\n\' "$OC_PASSWORD" | exec curl -sN --fail -K - "$OC_URL/api/event"']
        environment: ({ OC_PASSWORD: root.password, OC_URL: root.url })
        stdout: SplitParser {
            // Los eventos van separados por una línea en blanco: cada trozo llega
            // con un salto de línea delante
            onRead: raw => {
                const line = raw.trim();
                if (!line.startsWith("data:")) return;
                try {
                    const e = JSON.parse(line.slice(5));
                    root.handleEvent(e.type, e.data ?? {});
                } catch (err) {}
            }
        }
        // Se cortó (servicio reiniciado, suspensión…): reconectar
        onExited: if (root.status === "ready") reconnectTimer.restart()
    }
    Timer {
        id: reconnectTimer
        interval: 2000
        onTriggered: root.connect()
    }

    // Cabecera de autenticación (Basic, usuario "opencode"): base64 de la contraseña
    readonly property string authHeader: "Basic " + base64("opencode:" + password)
    function base64(str) {
        const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        const bytes = [];
        for (const ch of unescape(encodeURIComponent(str))) bytes.push(ch.charCodeAt(0));
        let out = "";
        for (let i = 0; i < bytes.length; i += 3) {
            const n = (bytes[i] << 16) | ((bytes[i + 1] ?? 0) << 8) | (bytes[i + 2] ?? 0);
            out += chars[(n >> 18) & 63] + chars[(n >> 12) & 63]
                + (i + 1 < bytes.length ? chars[(n >> 6) & 63] : "=")
                + (i + 2 < bytes.length ? chars[n & 63] : "=");
        }
        return out;
    }

    // Petición a la API. done(datos) si va bien; si no, el error se muestra en el panel.
    function api(method, path, body, done, failed) {
        const xhr = new XMLHttpRequest();
        xhr.open(method, url + path);
        xhr.setRequestHeader("Authorization", authHeader);
        if (body !== undefined && body !== null) xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            let data = null;
            try {
                data = xhr.responseText ? JSON.parse(xhr.responseText) : null;
            } catch (e) {}
            if (xhr.status >= 200 && xhr.status < 300) {
                done?.(data);
            } else if (xhr.status === 0) {
                // Sin respuesta: el servicio se cayó
                connect();
            } else {
                const msg = data?.message ?? data?.error?.message ?? `Error ${xhr.status}`;
                if (failed) failed(msg);
                else error = msg;
            }
        };
        xhr.send(body !== undefined && body !== null ? JSON.stringify(body) : null);
    }

    function loadAll() {
        loadModels();
        loadAgents();
        loadProjects();
        loadCommands();
        loadSessions();
        api("GET", "/api/session/active", null, d => {
            const b = {};
            for (const id of Object.keys(d?.data ?? {})) b[id] = true;
            busySessions = b;
        });
        if (sessionId !== "") loadSession(sessionId);
        else if (store.lastSession !== "") loadSession(store.lastSession);
    }

    // --- Ajustes guardados (modelo elegido, última conversación, carpeta) ---
    FileView {
        id: settingsFile
        path: Quickshell.statePath("ai.json")
        blockLoading: true
        printErrors: false

        JsonAdapter {
            id: store
            property var model: null // { providerID, id }
            property string lastSession: ""
            property string directory: ""
            // Agente: build (actúa) o plan (solo lee y propone)
            property string agent: "build"
            // Pedir permiso antes de editar archivos o ejecutar comandos
            property bool askFirst: true
        }
    }
    function save() {
        settingsFile.writeAdapter();
    }

    // Carpeta en la que trabaja el agente (por defecto, la personal)
    readonly property string directory: store.directory || Quickshell.env("HOME")

    // --- Modelos ---
    property var models: [] // { providerID, id, name, free }
    // El elegido; si no hay ninguno guardado, el primero gratuito
    readonly property var model: store.model ?? (models.length > 0 ? { providerID: models[0].providerID, id: models[0].id } : null)
    readonly property string modelName: {
        const m = model;
        if (!m) return "Sin modelo";
        return models.find(x => x.providerID === m.providerID && x.id === m.id)?.name ?? m.id;
    }

    function loadModels() {
        api("GET", "/api/model", null, d => {
            const list = (d?.data ?? []).map(m => ({
                providerID: m.providerID,
                id: m.id,
                name: (m.name ?? m.id).replace(/ Free$/, ""),
                free: (m.cost ?? []).every(c => !c.input && !c.output)
            }));
            // Gratuitos primero, luego por nombre
            list.sort((a, b) => (b.free - a.free) || a.name.localeCompare(b.name));
            models = list;
        });
    }

    function setModel(m) {
        store.model = { providerID: m.providerID, id: m.id };
        save();
        if (sessionId !== "")
            api("POST", `/api/session/${sessionId}/model`, { model: store.model });
    }

    // --- Carpeta de trabajo ---
    // Cambiarla empieza una conversación nueva (cada conversación es de una carpeta)
    property var projects: [] // carpetas usadas antes en OpenCode, la más reciente primero
    function loadProjects() {
        api("GET", "/api/project", null, d => {
            projects = (Array.isArray(d) ? d : d?.data ?? [])
                .filter(p => p.canonical && !p.canonical.startsWith("/tmp/"))
                .sort((a, b) => (b.time?.active ?? 0) - (a.time?.active ?? 0))
                .map(p => p.canonical);
        });
    }
    function setDirectory(dir) {
        store.directory = dir === Quickshell.env("HOME") ? "" : dir;
        save();
        newSession();
        loadCommands();
    }
    function shortPath(path) {
        return path.replace(Quickshell.env("HOME"), "~");
    }
    // Ubicación para las peticiones que dependen de la carpeta
    function locationQuery(dir) {
        return "location%5Bdirectory%5D=" + encodeURIComponent(dir ?? directory);
    }

    // Buscar archivos (para @) o carpetas (para elegir la de trabajo). done(rutas)
    function findPaths(query, type, base, done) {
        api("GET", `/api/fs/find?${locationQuery(base)}&type=${type}&limit=12&query=${encodeURIComponent(query)}`, null,
            d => done((d?.data ?? []).map(e => e.path)), () => done([]));
    }

    // --- Comandos "/" de OpenCode (más los del panel: nueva y compactar) ---
    property var commands: [] // { name, description }
    function loadCommands() {
        api("GET", `/api/command?${locationQuery()}`, null, d => {
            commands = (d?.data ?? []).map(c => ({ name: c.name, description: c.description ?? "" }));
        });
    }
    function runCommand(name, args) {
        const files = takeAttachments();
        const go = id => {
            setBusy(id, true);
            api("POST", `/api/session/${id}/command`, { name, text: args, files }, null, msg => {
                setBusy(id, false);
                error = msg;
            });
        };
        if (sessionId === "") createSession(go);
        else go(sessionId);
    }

    // --- Adjuntos: imágenes (captura, portapapeles) y archivos mencionados con @ ---
    property var attachments: [] // { uri, name, path, image }
    readonly property string attachDir: Quickshell.cachePath("ai")
    function attach(path, name) {
        if (attachments.some(a => a.path === path)) return;
        attachments = attachments.concat([{ uri: "file://" + path, name: name ?? path.split("/").pop(), path, image: /\.(png|jpe?g|webp|gif)$/i.test(path) }]);
    }
    function removeAttachment(path) {
        attachments = attachments.filter(a => a.path !== path);
    }
    function takeAttachments() {
        const files = attachments.map(a => ({ uri: a.uri, name: a.name }));
        attachments = [];
        return files;
    }

    // Captura de una zona: el panel se aparta mientras se elige
    property bool capturing: false
    function captureRegion() {
        if (capturing) return;
        capturing = true;
        open = false;
        const hex = c => "#" + [c.r, c.g, c.b].map(v => Math.round(v * 255).toString(16).padStart(2, "0")).join("");
        captureProc.command = ["sh", "-c", 'mkdir -p "$1"; f="$1/captura-$(date +%s%N).png"; sleep 0.3; '
            + 'g=$(slurp -d -b "#00000066" -c "$2" -w 2 < /dev/null) && grim -g "$g" "$f" && echo "$f"',
            "sh", attachDir, hex(Theme.primary) + "ff"];
        captureProc.running = true;
    }
    Process {
        id: captureProc
        stdout: StdioCollector {
            onStreamFinished: {
                const f = this.text.trim();
                if (f !== "") root.attach(f, "Captura");
            }
        }
        onExited: {
            root.capturing = false;
            root.open = true;
        }
    }

    // Imagen del portapapeles (si la hay); quiet = sin aviso si no hay imagen
    function pasteImage(quiet) {
        clipProc.quiet = quiet === true;
        clipProc.command = ["sh", "-c", 'wl-paste --list-types | grep -q "^image/png$" || exit 3; mkdir -p "$1"; '
            + 'f="$1/portapapeles-$(date +%s%N).png"; wl-paste --type image/png > "$f" && echo "$f"', "sh", attachDir];
        clipProc.running = true;
    }
    Process {
        id: clipProc
        property bool quiet: false
        stdout: StdioCollector {
            onStreamFinished: {
                const f = this.text.trim();
                if (f !== "") root.attach(f, "Imagen pegada");
            }
        }
        onExited: code => { if (code === 3 && !quiet) root.error = "No hay ninguna imagen en el portapapeles"; }
    }

    // --- Agentes (los principales: build y plan) ---
    property var agents: [] // { id, name, description }
    readonly property string agent: store.agent
    function loadAgents() {
        api("GET", "/api/agent", null, d => {
            agents = (d?.data ?? []).filter(a => a.mode === "primary" && !a.hidden)
                .map(a => ({ id: a.id, name: a.name ?? a.id, description: a.description ?? "" }));
        });
    }
    function setAgent(id) {
        store.agent = id;
        save();
        if (sessionId !== "") api("POST", `/api/session/${sessionId}/agent`, { agent: id });
    }

    // --- Permisos: preguntar antes de editar o ejecutar ---
    // OpenCode (agente build) lo permite todo por defecto; con askFirst la conversación
    // pide permiso para estas acciones (las tarjetas de permiso del panel).
    readonly property bool askFirst: store.askFirst
    readonly property var askRules: ["edit", "write", "patch", "shell", "bash"].map(a => ({ action: a, resource: "*", effect: "ask" }))
    function setAskFirst(on) {
        store.askFirst = on;
        save();
        if (sessionId !== "") api("PATCH", `/api/session/${sessionId}`, { permissions: on ? askRules : [] });
    }

    // --- Conversaciones ---
    property var sessions: [] // Session.Info de OpenCode, la más reciente primero
    property string sessionId: ""
    readonly property var session: sessions.find(s => s.id === sessionId) ?? null
    readonly property string title: session?.title || (sessionId === "" ? "Nueva conversación" : "Conversación")
    property var busySessions: ({})
    readonly property bool busy: busySessions[sessionId] === true
    property string error: ""
    // Tokens de la conversación actual
    property var usage: null

    function loadSessions() {
        api("GET", "/api/session?limit=100", null, d => {
            sessions = (d?.data ?? []).filter(s => !s.parentID).sort((a, b) => b.time.updated - a.time.updated);
            if (!store.model) adoptLastModel();
        });
    }

    // Sin modelo elegido aquí: el último que se usó en OpenCode (en la terminal)
    function adoptLastModel() {
        const last = sessions.find(s => s.tokens?.output > 0);
        if (!last) return;
        api("GET", `/api/session/${last.id}/message?limit=20&order=desc`, null, d => {
            const m = (d?.data ?? []).find(x => x.type === "assistant" && x.model)?.model;
            if (m && !store.model) {
                store.model = { providerID: m.providerID, id: m.id };
                save();
            }
        });
    }
    Timer {
        id: sessionsTimer
        interval: 400
        onTriggered: root.loadSessions()
    }

    function newSession() {
        clearMessages();
        sessionId = "";
        usage = null;
        error = "";
        permissions = [];
        forms = [];
        revertPending = null;
        store.lastSession = "";
        save();
    }

    function loadSession(id) {
        clearMessages();
        sessionId = id;
        error = "";
        permissions = [];
        forms = [];
        revertPending = null;
        store.lastSession = id;
        save();
        // Los últimos 150 mensajes (llegan del más nuevo al más viejo)
        api("GET", `/api/session/${id}/message?limit=150&order=desc`, null, d => {
            if (sessionId !== id) return;
            const list = (d?.data ?? []).slice().reverse();
            const out = [];
            for (const m of list) {
                const msg = fromStored(m);
                if (msg) out.push(msg);
            }
            messages = out;
            loadPermissions();
            loadForms();
        }, msg => {
            // Ya no existe (borrada desde la terminal)
            if (sessionId === id) newSession();
        });
        api("GET", `/api/session/${id}`, null, d => {
            if (sessionId === id) usage = d?.data?.tokens ?? null;
        });
    }

    function deleteSession(id) {
        api("DELETE", `/api/session/${id}`, null, () => {
            if (sessionId === id) newSession();
            loadSessions();
        });
    }

    function renameSession(id, title) {
        api("PATCH", `/api/session/${id}`, { title }, () => loadSessions());
    }

    // --- Mensajes ---
    property var messages: []

    component Message: QtObject {
        property string kind // user | assistant | error | note
        property string mid
        property string text
        property var files: [] // nombres de los adjuntos (mensajes del usuario)
        property var parts: []
        property var model: null
    }
    component Part: QtObject {
        property string type // text | reasoning | tool
        property string key
        property string text
        property bool done: false
        // Herramientas
        property string name
        property var input: null
        property string output
        property string status // pending | running | completed | error
    }
    Component { id: messageComp; Message {} }
    Component { id: partComp; Part {} }

    function clearMessages() {
        const old = messages;
        messages = [];
        for (const m of old) {
            for (const p of m.parts) p.destroy();
            m.destroy();
        }
    }

    function newMessage(props) {
        return messageComp.createObject(root, props);
    }
    function newPart(msg, props) {
        const p = partComp.createObject(msg, props);
        msg.parts = msg.parts.concat([p]);
        return p;
    }

    function toolOutput(content) {
        return (content ?? []).map(c => c.text ?? "").join("").trim();
    }

    // Mensaje guardado en OpenCode → Message
    function fromStored(m) {
        if (m.type === "user")
            return newMessage({ kind: "user", mid: m.id, text: m.text ?? "", files: (m.files ?? []).map(f => f.name ?? "archivo") });
        if (m.type === "assistant") {
            const msg = newMessage({ kind: "assistant", mid: m.id, model: m.model });
            for (const c of m.content ?? []) {
                if (c.type === "text" || c.type === "reasoning") {
                    if ((c.text ?? "").trim() === "") continue;
                    newPart(msg, { type: c.type, text: c.text, done: true });
                } else if (c.type === "tool") {
                    const st = c.state ?? {};
                    newPart(msg, {
                        type: "tool", key: c.id, name: c.name ?? "", input: st.input ?? null,
                        output: st.status === "error" ? (st.error?.message ?? st.error ?? "") : toolOutput(st.content),
                        status: st.status === "completed" ? "completed" : st.status === "error" ? "error" : "running",
                        done: true
                    });
                }
            }
            return msg.parts.length > 0 ? msg : (msg.destroy(), null);
        }
        if (m.type === "compaction")
            return newMessage({ kind: "note", mid: m.id, text: m.status === "completed" ? "Conversación compactada" : "Compactando la conversación…" });
        if (m.type === "idle" && m.outcome && m.outcome !== "succeeded" && m.error)
            return newMessage({ kind: "error", mid: m.id, text: m.error.message ?? String(m.error) });
        return null;
    }

    function findMessage(mid) {
        for (let i = messages.length - 1; i >= 0; i--)
            if (messages[i].mid === mid) return messages[i];
        return null;
    }
    function assistant(mid) {
        let msg = findMessage(mid);
        if (!msg) {
            msg = newMessage({ kind: "assistant", mid });
            messages = messages.concat([msg]);
        }
        return msg;
    }
    function findPart(msg, key) {
        return msg.parts.find(p => p.key === key) ?? null;
    }
    function addError(text) {
        messages = messages.concat([newMessage({ kind: "error", mid: "err" + Date.now(), text })]);
    }

    // --- Eventos ---
    function setBusy(id, on) {
        const b = Object.assign({}, busySessions);
        if (on) b[id] = true;
        else delete b[id];
        busySessions = b;
    }

    function handleEvent(type, d) {
        const sid = d.sessionID ?? "";

        if (type === "session.execution.started") setBusy(sid, true);
        else if (type === "session.execution.succeeded" || type === "session.execution.failed") {
            setBusy(sid, false);
            sessionsTimer.restart();
            if (type === "session.execution.succeeded" && !open && sid === sessionId)
                Quickshell.execDetached(["notify-send", "-a", "Asistente", "Respuesta lista", title]);
        }
        if (/^session\.(created|updated|removed|deleted|title)/.test(type)) sessionsTimer.restart();
        if (type.includes("permission")) loadPermissions();
        if (type.includes("form")) loadForms();
        if (type === "session.execution.succeeded" && compacting && sid === sessionId) {
            compacting = false;
            loadSession(sid);
        }

        if (sid === "" || sid !== sessionId) return;

        switch (type) {
        case "session.inbox.enqueued":
            if (d.item?.type === "user")
                messages = messages.concat([newMessage({ kind: "user", mid: d.inboxID, text: d.item.payload?.text ?? "",
                    files: (d.item.payload?.files ?? []).map(f => f.name ?? "archivo") })]);
            break;
        case "session.step.started":
            assistant(d.assistantMessageID).model = d.model;
            break;
        case "session.reasoning.started":
        case "session.text.started": {
            const kind = type.split(".")[1];
            const msg = assistant(d.assistantMessageID);
            if (!findPart(msg, kind + d.ordinal)) newPart(msg, { type: kind, key: kind + d.ordinal });
            break;
        }
        case "session.reasoning.delta":
        case "session.text.delta": {
            const kind = type.split(".")[1];
            const msg = assistant(d.assistantMessageID);
            const p = findPart(msg, kind + d.ordinal) ?? newPart(msg, { type: kind, key: kind + d.ordinal });
            p.text += d.delta ?? "";
            break;
        }
        case "session.reasoning.ended":
        case "session.text.ended": {
            const kind = type.split(".")[1];
            const msg = assistant(d.assistantMessageID);
            const p = findPart(msg, kind + d.ordinal) ?? newPart(msg, { type: kind, key: kind + d.ordinal });
            p.text = d.text ?? p.text;
            p.done = true;
            break;
        }
        case "session.tool.input.started": {
            const msg = assistant(d.assistantMessageID);
            if (!findPart(msg, d.id)) newPart(msg, { type: "tool", key: d.id, name: d.name ?? "", status: "pending" });
            break;
        }
        case "session.tool.called": {
            const msg = assistant(d.assistantMessageID);
            const p = findPart(msg, d.id) ?? newPart(msg, { type: "tool", key: d.id, name: d.name ?? "" });
            p.input = d.input ?? null;
            p.status = "running";
            break;
        }
        case "session.tool.success": {
            const p = findPart(assistant(d.assistantMessageID), d.id);
            if (p) {
                p.output = toolOutput(d.content);
                p.status = "completed";
                p.done = true;
            }
            break;
        }
        case "session.step.failed":
        case "session.execution.failed":
            if (d.error) addError(friendlyError(d.error));
            break;
        case "session.usage.updated":
            usage = d.tokens ?? null;
            break;
        default:
            // Herramienta que falló (el nombre exacto del evento puede variar)
            if (type.startsWith("session.tool.") && (d.error || type.endsWith("failed") || type.endsWith("error"))) {
                const p = findPart(assistant(d.assistantMessageID), d.id);
                if (p) {
                    p.output = d.error?.message ?? String(d.error ?? "Error");
                    p.status = "error";
                    p.done = true;
                }
            }
        }
    }

    function friendlyError(e) {
        if (e.status === 410 || /deprecated/i.test(e.message ?? ""))
            return "Este modelo ya no está disponible. Elige otro en el selector de abajo.";
        if (e.status === 429)
            return "Se alcanzó el límite de uso de este modelo. Espera un poco o elige otro.";
        return e.message ?? "Error del modelo";
    }

    // --- Enviar ---
    function createSession(then) {
        const body = { location: { directory }, agent, permissions: askFirst ? askRules : [] };
        if (model) body.model = model;
        api("POST", "/api/session", body, d => {
            const id = d.data.id;
            sessionId = id;
            store.lastSession = id;
            save();
            usage = null;
            then(id);
            loadSessions();
        });
    }

    // mentions: rutas (relativas a la carpeta) mencionadas con @ en el texto
    function send(text, mentions) {
        text = text.trim();
        if (text === "" || status !== "ready") return;
        error = "";
        const files = takeAttachments();
        for (const path of mentions ?? []) {
            const tag = "@" + path;
            const start = text.indexOf(tag);
            if (start < 0) continue;
            files.push({ uri: "file://" + (path.startsWith("/") ? path : directory + "/" + path), name: path,
                mention: { start, end: start + tag.length, text: tag } });
        }
        if (sessionId === "") createSession(id => prompt(id, text, files));
        else prompt(sessionId, text, files);
    }
    function prompt(id, text, files) {
        setBusy(id, true);
        const body = { text };
        if (files && files.length > 0) body.files = files;
        const go = () => api("POST", `/api/session/${id}/prompt`, body, null, msg => {
            setBusy(id, false);
            error = msg;
        });
        // Conversación empezada en la terminal (u otro modo): se le aplica el de aquí
        const want = askFirst ? askRules : [];
        const has = (session?.permissions ?? []).filter(r => r.effect === "ask").length;
        if (session && has !== want.length) api("PATCH", `/api/session/${id}`, { permissions: want }, go, go);
        else go();
    }

    // Detener la respuesta en curso
    function stop() {
        if (sessionId !== "") api("POST", `/api/session/${sessionId}/interrupt`, null, () => setBusy(sessionId, false));
    }

    // --- Permisos: el agente pide permiso para editar, ejecutar… ---
    property var permissions: [] // Permission.Request de la conversación actual
    function loadPermissions() {
        const id = sessionId;
        if (id === "") return;
        api("GET", `/api/session/${id}/permission`, null, d => {
            if (sessionId === id) permissions = d?.data ?? [];
        });
    }
    // decision: once | always | reject
    function replyPermission(req, decision) {
        permissions = permissions.filter(p => p.id !== req.id);
        api("POST", `/api/session/${req.sessionID}/permission/${req.id}/reply`, { decision }, () => loadPermissions());
    }

    // --- Preguntas del agente (formularios) ---
    property var forms: [] // Form.Info de la conversación actual
    function loadForms() {
        const id = sessionId;
        if (id === "") return;
        api("GET", `/api/session/${id}/form`, null, d => {
            if (sessionId === id) forms = d?.data ?? [];
        });
    }
    function replyForm(form, answer) {
        forms = forms.filter(f => f.id !== form.id);
        api("POST", `/api/session/${form.sessionID}/form/${form.id}/reply`, { answer }, () => loadForms(), msg => {
            error = msg;
            loadForms();
        });
    }
    function cancelForm(form) {
        forms = forms.filter(f => f.id !== form.id);
        api("DELETE", `/api/session/${form.sessionID}/form/${form.id}`, null, () => loadForms());
    }

    // --- Deshacer: vuelve a antes de un mensaje (y sus cambios en archivos) ---
    // Primero se prepara (revertPending: qué archivos cambian) y luego se confirma.
    property var revertPending: null // Session.Revert
    function stageRevert(messageID) {
        if (sessionId === "") return;
        api("POST", `/api/session/${sessionId}/revert/stage`, { messageID, files: true }, d => {
            revertPending = d?.data ?? { messageID };
        });
    }
    function commitRevert() {
        const id = sessionId;
        revertPending = null;
        api("POST", `/api/session/${id}/revert/commit`, null, () => loadSession(id));
    }
    function cancelRevert() {
        revertPending = null;
        api("DELETE", `/api/session/${sessionId}/revert`, null);
    }

    // --- Compactar: resume la conversación para liberar contexto ---
    property bool compacting: false
    function compact() {
        if (sessionId === "" || busy) return;
        compacting = true;
        setBusy(sessionId, true);
        api("POST", `/api/session/${sessionId}/compact`, {}, null, msg => {
            compacting = false;
            setBusy(sessionId, false);
            error = msg;
        });
    }

    IpcHandler {
        target: "ai"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.close(); }
        // Envía una pregunta (en la conversación actual) y abre el panel
        function ask(text: string): void {
            root.open = true;
            root.send(text);
        }
        function newChat(): void {
            root.newSession();
            root.open = true;
        }
    }

    Component.onCompleted: connect()
}
