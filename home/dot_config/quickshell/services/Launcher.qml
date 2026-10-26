pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Lanzador: paleta de comandos con las aplicaciones y las acciones de la shell (cambiar
// el fondo, bloquear, captura, luz nocturna, apagar…), cada acción con su atajo de
// teclado si lo tiene en hyprland.lua. Se abre con: quickshell ipc call launcher toggle
// La ventana es modules/launcher/LauncherWindow.qml.
Singleton {
    id: root

    property bool open: false
    property string query: ""
    // Veces que se abrió cada app ({ id: número }), guardado en disco
    property var usage: ({})
    // Últimas apps abiertas (ids, la más reciente primero), guardado en disco
    property var recent: []
    readonly property var recentApps: recent.map(id => apps.find(a => a.id === id)).filter(a => a)

    // Más usadas primero; a igualdad, orden alfabético
    readonly property var apps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => (usage[b.id] ?? 0) - (usage[a.id] ?? 0) || a.name.localeCompare(b.name))

    // Acciones de la shell. bind = descripción del atajo en hyprland.lua (para mostrar
    // sus teclas); featured = se ven sin haber escrito nada.
    readonly property var actions: [
        { title: "Cambiar el fondo de pantalla", icon: Theme.iImage, keywords: "wallpaper fondo imagen", featured: true, run: () => Wallpaper.open = true },
        { title: "Historial del portapapeles", icon: Theme.iClipboard, keywords: "clipboard copiar pegar", bind: "Herramientas: Historial del portapapeles", run: () => Clipboard.toggle() },
        { title: "Captura de pantalla", icon: Theme.iCamera, keywords: "screenshot captura foto", bind: "Herramientas: Captura de pantalla", featured: true, run: () => Screenshot.open() },
        { title: "Grabar la pantalla", icon: Theme.iVideo, keywords: "grabar video record", run: () => Recorder.recordScreen() },
        { title: "Grabar una región", icon: Theme.iRegion, keywords: "grabar video record region zona", run: () => Recorder.recordRegion() },
        { title: "Selector de color", icon: Theme.iPicker, keywords: "color picker gotero", run: () => ColorPicker.pick() },
        { title: "Asistente de IA", icon: Theme.iOpenCode, keywords: "ia ai opencode chat", bind: "Herramientas: Asistente de IA (OpenCode)", run: () => AI.toggle() },
        { title: "Atajos de teclado", icon: Theme.iList, keywords: "atajos shortcuts teclas", bind: "Herramientas: Ver los atajos de teclado", run: () => Shortcuts.toggle() },
        { title: "Ajustes rápidos", icon: Theme.iSettings, keywords: "ajustes configuración settings", run: () => Config.toggle() },
        { title: "Sonido (salida, entrada y apps)", icon: Theme.iVolume, keywords: "sonido audio volumen micrófono auriculares altavoces salida entrada", run: () => Audio.panelRequested() },
        { title: "Notas", icon: Theme.iNote, keywords: "notas apuntes texto", bind: "Herramientas: Notas", run: () => Notes.open = true },
        { title: "Nota nueva", icon: Theme.iPlus, keywords: "nota nueva apuntar crear", run: () => { Notes.open = true; Notes.create(); } },
        { title: "Contraseñas (Bitwarden)", icon: Theme.iBitwarden, keywords: "bitwarden contraseñas claves bóveda password", bind: "Herramientas: Contraseñas (Bitwarden)", run: () => Bitwarden.open = true },
        { title: "Generar una contraseña", icon: Theme.iKey, keywords: "generar contraseña aleatoria password bitwarden", run: () => Bitwarden.openGenerator() },
        { title: "Visualizador de audio", icon: Theme.iMusic, keywords: "visualizador audio música espectro barras ondas", run: () => Visualizer.pickerOpen = true },
        { title: "Notificaciones", icon: Theme.iBell, keywords: "notificaciones avisos", run: () => Notifs.toggleCenter() },
        { title: "No molestar (activar o desactivar)", icon: Theme.iBellOff, keywords: "no molestar silencio dnd", run: () => Notifs.dnd = !Notifs.dnd },
        { title: "Luz nocturna (activar o desactivar)", icon: Theme.iNight, keywords: "luz nocturna noche filtro", run: () => NightLight.toggle() },
        { title: "Pantallas", icon: Theme.iMonitor, keywords: "monitores pantallas resolución displays", run: () => Displays.toggle() },
        { title: "Perfil", icon: Theme.iPencil, keywords: "perfil foto nombre contraseña usuario", run: () => Profile.toggle() },
        { title: "Siguiente distribución de teclado", icon: Theme.iKeyboard, keywords: "teclado idioma layout distribución", run: () => KeyboardLayout.next() },
        { title: "Pomodoro: empezar o pausar", icon: Theme.iTimer, keywords: "pomodoro temporizador enfoque", run: () => Pomodoro.toggle() },
        { title: "Guía de estilo", icon: Theme.iStar, keywords: "diseño velure estilo guía", run: () => Design.guideOpen = true },
        { title: "Bloquear la pantalla", icon: Theme.iLock, keywords: "bloquear lock", bind: "Sistema: Bloquear la pantalla", featured: true, run: () => Lock.lock() },
        { title: "Menú de energía", icon: Theme.iPower, keywords: "energía apagar reiniciar power", bind: "Sistema: Menú de energía", run: () => PowerMenu.toggle() },
        { title: "Suspender", icon: Theme.iSleep, keywords: "suspender dormir sleep", run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { title: "Reiniciar", icon: Theme.iReboot, keywords: "reiniciar reboot", run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { title: "Apagar", icon: Theme.iPower, keywords: "apagar shutdown poweroff", run: () => Quickshell.execDetached(["systemctl", "poweroff"]) },
        { title: "Cerrar la sesión", icon: Theme.iLogout, keywords: "cerrar sesión salir logout", bind: "Sistema: Cerrar la sesión", run: () => Hypr.exit() }
    ]

    // Teclas de cada atajo (descripción -> "Super Shift L"), leídas de Hyprland al abrir
    property var hints: ({})
    function hintFor(action) {
        return action.bind ? (hints[action.bind] ?? "") : "";
    }

    // Lo que muestra la paleta: [{ kind: "header", title } | { kind: "app", entry } |
    // { kind: "action", action }]. Sin escribir: las apps más usadas y las acciones
    // principales. Escribiendo: las que coinciden de cada grupo.
    // Sin mayúsculas ni tildes, para comparar ("Energía" = "energia")
    function plain(text) {
        return (text ?? "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
    }
    function wordsOf(text) {
        return plain(text).split(/[\s:()\-_.]+/).filter(w => w !== "");
    }

    readonly property var items: {
        const q = plain(query.trim());
        let appList, actionList, actionsFirst = false;
        if (q === "") {
            // Sin escribir: las 3 últimas apps abiertas (completadas con las más usadas)
            // y 3 acciones
            appList = recentApps.concat(apps.filter(a => !recentApps.includes(a))).slice(0, 3);
            actionList = actions.filter(a => a.featured).slice(0, 3);
        } else {
            // Apps: nombre empieza por (4) > una palabra empieza por (3) > contiene (2) >
            // otros campos (1). El orden por uso se mantiene dentro de cada nivel.
            const appScore = a => {
                const name = plain(a.name);
                if (name.startsWith(q)) return 4;
                if (wordsOf(a.name).some(w => w.startsWith(q))) return 3;
                if (name.includes(q)) return 2;
                return plain([a.genericName, a.comment, a.id, ...(a.keywords ?? [])].join(" ")).includes(q) ? 1 : 0;
            };
            // Acciones, en la misma escala: título empieza por (4) > una palabra del título
            // (3) > una palabra clave (1). Con varias palabras, todas tienen que estar.
            const words = q.split(/\s+/);
            const actionScore = a => {
                const title = plain(a.title);
                const own = wordsOf(a.title), keys = wordsOf(a.keywords);
                if (!words.every(w => own.some(o => o.startsWith(w)) || keys.some(k => k.startsWith(w)))) return 0;
                if (title.startsWith(q)) return 4;
                if (words.every(w => own.some(o => o.startsWith(w)))) return 3;
                return 1;
            };
            const rank = (list, score) => list.map(x => ({ x, s: score(x) }))
                .filter(r => r.s > 0)
                .sort((a, b) => b.s - a.s);
            const apr = rank(apps, appScore).slice(0, 6);
            const acr = rank(actions, actionScore).slice(0, 6);
            appList = apr.map(r => r.x);
            actionList = acr.map(r => r.x);
            // El grupo con la mejor coincidencia va primero (así queda seleccionada)
            actionsFirst = acr.length > 0 && (apr.length === 0 || acr[0].s > apr[0].s);
        }
        const appPart = appList.length === 0 ? [] : [{ kind: "header", title: "Aplicaciones" }]
            .concat(appList.map(a => ({ kind: "app", entry: a })));
        const actionPart = actionList.length === 0 ? [] : [{ kind: "header", title: "Acciones" }]
            .concat(actionList.map(a => ({ kind: "action", action: a })));
        return actionsFirst ? actionPart.concat(appPart) : appPart.concat(actionPart);
    }

    function toggle() {
        open = !open;
    }

    // Abre una app o hace una acción (con la paleta ya cerrada, para que lo que abra
    // reciba el teclado)
    function activate(item) {
        if (!item || item.kind === "header") return;
        open = false;
        if (item.kind === "app") {
            item.entry.execute();
            // Se actualiza después de cerrar para que el reordenamiento no se vea
            const u = Object.assign({}, usage);
            u[item.entry.id] = (u[item.entry.id] ?? 0) + 1;
            usage = u;
            usageFile.setText(JSON.stringify(u));
            recent = [item.entry.id].concat(recent.filter(id => id !== item.entry.id)).slice(0, 10);
            recentFile.setText(JSON.stringify(recent));
        } else {
            pending = item.action;
            runLater.restart();
        }
    }
    property var pending: null
    Timer {
        id: runLater
        interval: 150
        onTriggered: {
            root.pending?.run();
            root.pending = null;
        }
    }

    onOpenChanged: if (open) bindsProc.running = true

    Process {
        id: bindsProc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const h = {};
                    for (const b of JSON.parse(this.text))
                        if (b.description && !(b.description in h)) h[b.description] = Shortcuts.combo(b).join(" ");
                    root.hints = h;
                } catch (e) {}
            }
        }
    }

    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher-usage.json")
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {
                root.usage = {};
            }
        }
    }

    FileView {
        id: recentFile
        path: Quickshell.statePath("launcher-recent.json")
        printErrors: false
        onLoaded: {
            try {
                root.recent = JSON.parse(text());
            } catch (e) {
                root.recent = [];
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }
}
