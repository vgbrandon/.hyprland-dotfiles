pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Cuentas de GitHub a través de gh (GitHub CLI): iniciar sesión (flujo de dispositivo:
// un código que se pega en github.com/login/device), cambiar de cuenta y cerrar sesión.
// La sesión es la misma que usan gh y git en la terminal. El panel está en modules/github
// (se abre desde el icono de la barra).
//   quickshell ipc call github toggle
Singleton {
    id: root

    // IPC: el icono de la barra del monitor enfocado abre su panel
    signal panelRequested()

    property bool available: true // gh instalado
    // Cuentas de github.com: { login, active, scopes, state }
    property var accounts: []
    readonly property var active: accounts.find(a => a.active) ?? null
    readonly property bool loggedIn: active !== null && active.state === "success"
    // Datos de la cuenta activa (gh api user)
    property var user: null
    property bool loading: false
    property string error: ""

    function refresh() {
        loading = true;
        statusProc.running = true;
    }

    Process {
        id: statusProc
        command: ["gh", "auth", "status", "--json", "hosts"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const hosts = JSON.parse(this.text).hosts ?? {};
                    root.accounts = (hosts["github.com"] ?? []).map(a => ({
                        login: a.login, active: a.active, scopes: a.scopes ?? "", state: a.state
                    }));
                } catch (e) {
                    root.accounts = [];
                }
                if (root.loggedIn) {
                    userProc.running = true;
                    // La actividad y su detalle: solo lo que falte (el resto está en caché)
                    root.ensureLoaded();
                    root.ensureDetails();
                }
                else {
                    root.user = null;
                    root.loading = false;
                }
            }
        }
        onExited: (code, status) => { if (code === 127) root.available = false; }
    }
    Process {
        id: userProc
        command: ["gh", "api", "user", "--jq", "{login,name,avatar_url,bio,html_url,public_repos,followers,following,created_at}"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.user = JSON.parse(this.text);
                } catch (e) {
                    root.user = null;
                }
                root.loading = false;
            }
        }
    }

    // --- Actividad (contribuciones por día) ---
    // Se piden a GitHub por bloques de 3 meses en una sola consulta y se guardan en
    // disco (github-activity.json, por cuenta). Un mes ya terminado no cambia: si se
    // descargó después de acabar, no se vuelve a pedir. El mes actual se actualiza como
    // mucho cada 10 minutos. Al retroceder, cuando solo queda un mes cargado por
    // detrás, se precargan los 3 anteriores, así no se ve "Cargando…".
    readonly property var levels: ({ NONE: 0, FIRST_QUARTILE: 1, SECOND_QUARTILE: 2, THIRD_QUARTILE: 3, FOURTH_QUARTILE: 4 })
    // Contribuciones por fecha ("AAAA-MM-DD" -> { count, level })
    property var days: ({})
    // Meses descargados: "AAAA-MM" -> hora de la descarga (ms)
    property var fetchedMonths: ({})

    // monthOffset 0 = el mes actual; 1 = el anterior…
    property int monthOffset: 0
    function monthAt(offset) {
        const now = new Date();
        const d = new Date(now.getFullYear(), now.getMonth() - offset, 1);
        return { year: d.getFullYear(), month: d.getMonth(), key: Qt.formatDate(d, "yyyy-MM") };
    }
    // { year, month (0-11), key }
    readonly property var shownMonth: monthAt(monthOffset)

    // ¿Hace falta (volver a) pedir este mes?
    function needsFetch(offset) {
        const m = monthAt(offset);
        const at = fetchedMonths[m.key];
        if (!at) return true;
        if (offset === 0) return Date.now() - at > 600000;
        // Descargado antes de que terminara el mes: falta el final
        return at < new Date(m.year, m.month + 1, 1).getTime();
    }
    // Cargando el mes que se está viendo (no las precargas)
    readonly property bool windowLoading: activityProc.running && needsFetch(monthOffset)

    readonly property int monthTotal: {
        const prefix = shownMonth.key + "-";
        let n = 0;
        for (const date in days)
            if (date.startsWith(prefix)) n += days[date].count;
        return n;
    }
    // Racha: días seguidos con contribuciones hasta hoy (si hoy aún no hay, hasta ayer)
    readonly property int streak: {
        const d = new Date();
        const key = x => Qt.formatDate(x, "yyyy-MM-dd");
        if ((days[key(d)]?.count ?? 0) === 0) d.setDate(d.getDate() - 1);
        let n = 0;
        while ((days[key(d)]?.count ?? 0) > 0) {
            n++;
            d.setDate(d.getDate() - 1);
        }
        return n;
    }

    // Mes más antiguo al que se puede ir: el de creación de la cuenta
    readonly property int maxOffset: {
        const created = user?.created_at ? new Date(user.created_at) : null;
        if (!created) return 1200;
        const now = new Date();
        return (now.getFullYear() - created.getFullYear()) * 12 + now.getMonth() - created.getMonth();
    }
    readonly property bool canGoBack: monthOffset < maxOffset

    // Al abrir el panel: el mes actual, sin ningún día elegido
    function resetWindow() {
        selectedDate = "";
        day = null;
        monthOffset = 0;
    }
    function previousMonth() {
        if (!canGoBack) return;
        monthOffset++;
        ensureLoaded();
    }
    function nextMonth() {
        if (monthOffset === 0) return;
        monthOffset--;
        ensureLoaded();
    }

    // Pide lo que falte del mes visible (en un bloque de 3 hacia atrás) y precarga
    // el bloque anterior si ya queda poco cargado por detrás
    function ensureLoaded() {
        if (!loggedIn) return;
        if (needsFetch(monthOffset)) {
            enqueue(monthOffset);
            return;
        }
        // La precarga se decide con todo descargado (al terminar cada bloque se vuelve a mirar)
        if (activityProc.running || queue.length > 0) return;
        let behind = 0;
        while (monthOffset + behind + 1 <= maxOffset && !needsFetch(monthOffset + behind + 1)) behind++;
        if (behind <= 1 && monthOffset + behind + 1 <= maxOffset) enqueue(monthOffset + behind + 1);
    }

    // Cola de bloques (offset del mes más reciente del bloque)
    property var queue: []
    function enqueue(offset) {
        if (queue.includes(offset) || activityProc.offset === offset && activityProc.running) return;
        queue = queue.concat([offset]);
        if (!activityProc.running) nextBlock();
    }
    function nextBlock() {
        if (queue.length === 0) return;
        let newest = queue[0];
        queue = queue.slice(1);
        // Lo que ya trajo otro bloque no se vuelve a pedir
        while (newest <= maxOffset && !needsFetch(newest)) newest++;
        if (newest > maxOffset) {
            nextBlock();
            return;
        }
        // Hasta 3 meses que hagan falta, desde "newest" hacia atrás
        let oldest = newest;
        while (oldest - newest < 2 && oldest + 1 <= maxOffset && needsFetch(oldest + 1)) oldest++;
        const a = monthAt(oldest), b = monthAt(newest);
        const keys = [];
        for (let o = newest; o <= oldest; o++) keys.push(monthAt(o).key);
        activityProc.offset = newest;
        activityProc.months = keys;
        activityProc.ok = false;
        activityProc.command = ["gh", "api", "graphql", "-f",
            "query=query($from:DateTime!,$to:DateTime!){viewer{contributionsCollection(from:$from,to:$to){contributionCalendar{weeks{contributionDays{date contributionCount contributionLevel}}}}}}",
            "-f", "from=" + new Date(a.year, a.month, 1).toISOString(),
            "-f", "to=" + new Date(b.year, b.month + 1, 1, 0, 0, -1).toISOString()];
        activityProc.running = true;
    }
    Process {
        id: activityProc
        property int offset: -1
        property var months: []
        property bool ok: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const weeks = JSON.parse(this.text).data.viewer.contributionsCollection.contributionCalendar.weeks;
                    const d = Object.assign({}, root.days);
                    for (const w of weeks)
                        for (const day of w.contributionDays)
                            d[day.date] = { count: day.contributionCount, level: root.levels[day.contributionLevel] ?? 0 };
                    root.days = d;
                    const f = Object.assign({}, root.fetchedMonths);
                    for (const key of activityProc.months) f[key] = Date.now();
                    root.fetchedMonths = f;
                    root.saveCache();
                    activityProc.ok = true;
                    root.ensureDetails();
                } catch (e) {
                    activityProc.ok = false;
                }
            }
        }
        // Siguiente bloque en cola o, si no queda ninguno, ver si toca precargar.
        // Tras un error no se insiste (se reintenta al volver a abrir el panel)
        onExited: code => {
            if (root.queue.length > 0) root.nextBlock();
            else if (code === 0 && ok) root.ensureLoaded();
        }
    }

    // --- Detalle de los días: commits (con su mensaje), PRs, issues y revisiones ---
    // Se descarga por mes completo y en segundo plano al mostrar un mes, así al pulsar
    // un día ya está. Cada mes se guarda con su total de contribuciones al descargarlo:
    // si se descargó ya terminado vale para siempre; si no (el mes actual), vale
    // mientras ese total no cambie.
    property string selectedDate: ""
    property var day: null
    // "AAAA-MM" -> { fetchedAt, total, days: { fecha: detalle } }
    property var monthDetails: ({})
    readonly property bool dayLoading: selectedDate !== "" && day === null

    function monthCount(key) {
        let n = 0;
        for (const date in days)
            if (date.startsWith(key + "-")) n += days[date].count;
        return n;
    }
    function detailsValid(key) {
        const entry = monthDetails[key];
        if (!entry) return false;
        const [y, m] = key.split("-").map(Number);
        if (entry.fetchedAt >= new Date(y, m, 1).getTime()) return true;
        return entry.total === monthCount(key);
    }
    function emptyDay(date) {
        return { date, commits: [], pullRequests: [], issues: [], reviews: [] };
    }

    function loadDay(date) {
        if (date === selectedDate) {
            // Segundo clic en el mismo día: se cierra el detalle
            selectedDate = "";
            day = null;
            return;
        }
        selectedDate = date;
        const key = date.slice(0, 7);
        if (detailsValid(key)) day = monthDetails[key].days[date] ?? emptyDay(date);
        else {
            day = null;
            fetchDetails(key);
        }
    }

    // Detalle del mes visible (y del actual), en segundo plano
    // (con los números del mes ya al día: si no, se volvería a pedir al llegar)
    function ensureDetails() {
        if (!loggedIn) return;
        for (const offset of [monthOffset, 0])
            if (!needsFetch(offset) && !detailsValid(monthAt(offset).key)) fetchDetails(monthAt(offset).key);
    }
    onShownMonthChanged: ensureDetails()

    property var detailQueue: []
    function fetchDetails(key) {
        if (detailsProc.month === key && detailsProc.running) return;
        // El que se pide al pulsar va primero
        detailQueue = [key].concat(detailQueue.filter(k => k !== key));
        if (!detailsProc.running) nextDetails();
    }
    function nextDetails() {
        while (detailQueue.length > 0 && detailsValid(detailQueue[0])) detailQueue = detailQueue.slice(1);
        if (detailQueue.length === 0) return;
        const key = detailQueue[0];
        detailQueue = detailQueue.slice(1);
        detailsProc.month = key;
        detailsProc.command = ["python3", "-I", Quickshell.shellPath("scripts/github-month.py"), key];
        detailsProc.running = true;
    }
    Process {
        id: detailsProc
        property string month: ""
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text);
                    if (d.error) return;
                    const all = Object.assign({}, root.monthDetails);
                    all[d.month] = { fetchedAt: Date.now(), total: root.monthCount(d.month), days: d.days };
                    root.monthDetails = all;
                    root.saveCache();
                    if (root.selectedDate.startsWith(d.month + "-"))
                        root.day = d.days[root.selectedDate] ?? root.emptyDay(root.selectedDate);
                } catch (e) {}
            }
        }
        onExited: root.nextDetails()
    }

    // --- Caché en disco (por cuenta) ---
    property var cacheAll: ({})
    function loadCache() {
        const c = cacheAll[active?.login ?? ""] ?? {};
        days = c.days ?? {};
        fetchedMonths = c.months ?? {};
        monthDetails = c.monthDetails ?? {};
    }
    function saveCache() {
        if (!active) return;
        const all = Object.assign({}, cacheAll);
        all[active.login] = { days, months: fetchedMonths, monthDetails };
        cacheAll = all;
        saveTimer.restart();
    }
    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: cacheFile.setText(JSON.stringify(root.cacheAll))
    }
    FileView {
        id: cacheFile
        path: Quickshell.cachePath("github-activity.json")
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                root.cacheAll = JSON.parse(text());
            } catch (e) {
                root.cacheAll = {};
            }
            root.loadCache();
        }
    }
    // Otra cuenta: su caché
    onActiveChanged: loadCache()

    // --- Iniciar sesión (flujo de dispositivo) ---
    // gh muestra un código (y lo copia al portapapeles) y espera a que se autorice en
    // el navegador; al terminar, git usa esta cuenta (gh auth setup-git).
    property bool loggingIn: false
    property string deviceCode: ""
    property string deviceUrl: "https://github.com/login/device"

    function login() {
        if (loggingIn) return;
        error = "";
        deviceCode = "";
        loggingIn = true;
        loginProc.running = true;
    }
    function cancelLogin() {
        if (loginProc.running) loginProc.signal(15);
        loggingIn = false;
        deviceCode = "";
    }
    function openDevicePage() {
        Qt.openUrlExternally(deviceUrl);
    }

    Process {
        id: loginProc
        command: ["gh", "auth", "login", "--web", "--hostname", "github.com", "--git-protocol", "https", "--skip-ssh-key"]
        stderr: SplitParser {
            onRead: line => {
                const code = line.match(/\b([A-Z0-9]{4}-[A-Z0-9]{4})\b/);
                if (code) root.deviceCode = code[1];
                const url = line.match(/https:\/\/\S+/);
                if (url) root.deviceUrl = url[0];
            }
        }
        onExited: code => {
            const wasCancelled = !root.loggingIn;
            root.loggingIn = false;
            root.deviceCode = "";
            if (code === 0) {
                setupGit.running = true;
                root.refresh();
            } else if (!wasCancelled) {
                root.error = "No se completó el inicio de sesión. Inténtalo de nuevo.";
            }
        }
    }
    Process {
        id: setupGit
        command: ["gh", "auth", "setup-git", "--hostname", "github.com"]
    }

    // --- Cambiar de cuenta y cerrar sesión ---
    function switchTo(login) {
        runAuth(["gh", "auth", "switch", "--hostname", "github.com", "--user", login]);
    }
    function logout(login) {
        runAuth(["gh", "auth", "logout", "--hostname", "github.com", "--user", login]);
    }
    function runAuth(cmd) {
        error = "";
        authProc.command = cmd;
        authProc.running = true;
    }
    Process {
        id: authProc
        stderr: StdioCollector {
            id: authErr
        }
        onExited: code => {
            if (code !== 0) root.error = authErr.text.trim().split("\n").pop() || "No se pudo completar";
            root.refresh();
        }
    }

    Component.onCompleted: refresh()

    IpcHandler {
        target: "github"

        function toggle(): void { root.panelRequested(); }
    }
}
