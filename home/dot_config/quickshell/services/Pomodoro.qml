pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Pomodoro: bloques de enfoque con descansos cortos y, cada N rondas, uno largo.
// El estado se guarda (reiniciar Quickshell no lo pierde). El botón y el panel están
// en PomodoroButton.qml / PomodoroPanel.qml.
//   quickshell ipc call pomodoro toggle | start | pause | skip | reset | panel
Singleton {
    id: root

    // Fases: work = enfoque, short = descanso corto, long = descanso largo
    readonly property var phaseNames: ({ work: "Enfoque", short: "Descanso corto", long: "Descanso largo" })
    readonly property string phase: store.phase
    readonly property bool running: store.running
    readonly property bool isBreak: phase !== "work"
    // Rondas de enfoque completadas en el ciclo actual (0..rounds)
    readonly property int round: store.round
    readonly property int todayCount: store.todayDate === today() ? store.todayCount : 0

    // Duraciones en minutos y opciones
    readonly property int workMinutes: store.workMinutes
    readonly property int shortMinutes: store.shortMinutes
    readonly property int longMinutes: store.longMinutes
    readonly property int rounds: store.rounds
    readonly property bool autoStart: store.autoStart
    readonly property bool sound: store.sound

    function minutesOf(p) {
        return p === "work" ? workMinutes : p === "short" ? shortMinutes : longMinutes;
    }
    readonly property int total: minutesOf(phase) * 60
    // Segundos restantes (se actualiza cada segundo mientras corre)
    property int remaining: total
    readonly property real progress: total > 0 ? 1 - remaining / total : 0
    // Hay una sesión empezada (corriendo o en pausa a mitad): la barra muestra el tiempo
    readonly property bool active: running || remaining < total

    function today() {
        return Qt.formatDate(new Date(), "yyyy-MM-dd");
    }

    function timeText(seconds) {
        const s = seconds ?? remaining;
        return `${String(Math.floor(s / 60)).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;
    }

    function updateRemaining() {
        if (store.running) remaining = Math.max(0, Math.ceil((store.endsAt - Date.now()) / 1000));
        else remaining = store.pausedLeft >= 0 ? store.pausedLeft : total;
        if (store.running && remaining === 0) finish();
    }

    function save() {
        file.writeAdapter();
        updateRemaining();
    }

    function start() {
        if (store.running) return;
        store.endsAt = Date.now() + remaining * 1000;
        store.running = true;
        store.pausedLeft = -1;
        save();
    }
    function pause() {
        if (!store.running) return;
        updateRemaining();
        store.pausedLeft = remaining;
        store.running = false;
        save();
    }
    function toggle() {
        if (store.running) pause();
        else start();
    }
    // Vuelve al inicio de la fase actual, parado
    function reset() {
        store.running = false;
        store.pausedLeft = -1;
        save();
    }
    // Empieza de cero el ciclo (enfoque, ronda 0)
    function resetCycle() {
        store.round = 0;
        setPhase("work");
    }
    function setPhase(p) {
        store.phase = p;
        store.running = false;
        store.pausedLeft = -1;
        save();
    }
    // Pasa a la siguiente fase sin contarla como completada
    function skip() {
        advance(false);
    }

    // Fin de una fase: aviso y siguiente fase
    function finish() {
        const was = store.phase;
        if (was === "work") {
            if (store.todayDate !== today()) {
                store.todayDate = today();
                store.todayCount = 0;
            }
            store.todayCount++;
        }
        advance(true);
        notify(was);
    }

    function advance(completed) {
        let next;
        if (store.phase === "work") {
            const done = store.round + (completed ? 1 : 0);
            if (done >= store.rounds) {
                next = "long";
                store.round = store.rounds;
            } else {
                next = "short";
                store.round = done;
            }
        } else {
            next = "work";
            // Tras el descanso largo empieza un ciclo nuevo
            if (store.phase === "long") store.round = 0;
        }
        const autoStart = completed && store.autoStart;
        store.phase = next;
        store.pausedLeft = -1;
        store.running = autoStart;
        if (autoStart) store.endsAt = Date.now() + minutesOf(next) * 60000;
        save();
    }

    function notify(was) {
        const title = was === "work" ? "¡Enfoque terminado!" : "Descanso terminado";
        const next = root.phaseNames[store.phase].toLowerCase();
        const body = was === "work"
            ? `Toca ${next} (${minutesOf(store.phase)} min). Llevas ${todayCount} hoy.`
            : `De vuelta al enfoque (${minutesOf("work")} min).`;
        Quickshell.execDetached(["notify-send", "-a", "Pomodoro", title,
            body + (store.running ? "" : " Pulsa play para empezar.")]);
        if (store.sound)
            Quickshell.execDetached(["pw-play", "/usr/share/sounds/freedesktop/stereo/"
                + (was === "work" ? "complete.oga" : "bell.oga")]);
    }

    // Ajustes (desde el panel)
    function setMinutes(p, minutes) {
        const m = Math.max(1, Math.min(120, minutes));
        if (p === "work") store.workMinutes = m;
        else if (p === "short") store.shortMinutes = m;
        else store.longMinutes = m;
        // La fase actual sin empezar se ajusta a la nueva duración
        save();
    }
    function setRounds(n) {
        store.rounds = Math.max(1, Math.min(10, n));
        store.round = Math.min(store.round, store.rounds);
        save();
    }
    function setAutoStart(on) {
        store.autoStart = on;
        save();
    }
    function setSound(on) {
        store.sound = on;
        save();
    }

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: root.updateRemaining()
    }

    // Panel (lo abre el botón de la barra; por IPC, en la barra del monitor enfocado)
    signal panelRequested()

    FileView {
        id: file
        path: Quickshell.statePath("pomodoro.json")
        blockLoading: true
        // Aún no existe hasta el primer cambio: no es un error
        printErrors: false
        // Si terminó mientras Quickshell no corría, avisa al cargar
        onLoaded: root.updateRemaining()
        onLoadFailed: root.updateRemaining()

        JsonAdapter {
            id: store
            property string phase: "work"
            property bool running: false
            // Fin de la fase en curso (ms desde epoch) si corre
            property real endsAt: 0
            // Segundos que quedaban al pausar (-1 = fase sin empezar)
            property int pausedLeft: -1
            property int round: 0
            property int todayCount: 0
            property string todayDate: ""

            property int workMinutes: 25
            property int shortMinutes: 5
            property int longMinutes: 15
            property int rounds: 4
            property bool autoStart: false
            property bool sound: true
        }
    }

    IpcHandler {
        target: "pomodoro"

        function toggle(): void { root.toggle(); }
        function start(): void { root.start(); }
        function pause(): void { root.pause(); }
        function skip(): void { root.skip(); }
        function reset(): void { root.reset(); }
        function panel(): void { root.panelRequested(); }
    }
}
