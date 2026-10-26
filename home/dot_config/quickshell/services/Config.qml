pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Estado del panel de ajustes rápidos (entra desde la derecha).
//   quickshell ipc call config toggle
Singleton {
    id: root

    property bool open: false
    property real closedAt: 0

    // Posición de la barra: top | bottom | left | right (se guarda en settings.json).
    // barTarget es la elegida; barPosition, la que se ve: cambia a mitad de la
    // animación, cuando la barra está escondida.
    readonly property string barTarget: savedPosition
    // La guardada (si no es válida, arriba)
    readonly property string savedPosition: ["top", "bottom", "left", "right"].includes(settings.barPosition) ? settings.barPosition : "top"
    property string barPosition: "top"
    readonly property bool barVertical: barPosition === "left" || barPosition === "right"
    // 0 = barra visible, 1 = escondida fuera de su borde. Empieza escondida:
    // al iniciar la sesión entra deslizándose (introAnim)
    property real barHide: 1

    readonly property int nightLightTemp: settings.nightLightTemp
    // Se guarda con un pequeño retraso: al arrastrar el deslizador llegan muchos valores
    function setNightLightTemp(t) {
        settings.nightLightTemp = t;
        saveTimer.restart();
    }
    Timer {
        id: saveTimer
        interval: 500
        onTriggered: settingsFile.writeAdapter()
    }

    readonly property string primaryMonitor: settings.primaryMonitor
    function setPrimaryMonitor(name) {
        settings.primaryMonitor = name;
        settingsFile.writeAdapter();
    }

    // Barra y paneles translúcidos (Hyprland desenfoca lo que hay detrás). También el
    // fondo de las apps que lo permiten (kitty y Zed), con translucent.sh de Velure
    readonly property bool translucent: settings.translucent
    function setTranslucent(on) {
        settings.translucent = on;
        settingsFile.writeAdapter();
    }
    // Al cambiar (también si se edita el archivo a mano) y al iniciar (ver
    // onSettingsLoadedChanged)
    onTranslucentChanged: if (settingsLoaded) applyTranslucentApps()
    function applyTranslucentApps() {
        translucentApps.command = ["sh", Quickshell.env("HOME") + "/.config/velure/scripts/translucent.sh", translucent ? "on" : "off"];
        translucentApps.running = true;
    }
    Process {
        id: translucentApps
    }

    // Selector de fondos: "carousel" (el elegido al centro, flechas) o "grid" (todos a
    // pantalla completa, con buscador)
    readonly property string wallpaperPicker: settings.wallpaperPicker === "grid" ? "grid" : "carousel"
    function setWallpaperPicker(style) {
        settings.wallpaperPicker = style;
        settingsFile.writeAdapter();
    }

    // Módulos de la barra que se ocultan (Ajustes → Módulos de la barra). Las claves
    // están en barModules; los ajustes no se pueden quitar (si no, no se podría volver).
    readonly property var barModules: [
        { key: "launcher", label: "Lanzador", icon: Theme.iApps },
        { key: "workspaces", label: "Escritorios", icon: Theme.iWindow },
        { key: "window", label: "Ventana activa", icon: Theme.iWindow },
        { key: "media", label: "Multimedia", icon: Theme.iMusic },
        { key: "clock", label: "Reloj", icon: Theme.iTimer },
        { key: "resources", label: "CPU y RAM", icon: Theme.iCpu },
        { key: "wallpaper", label: "Fondos", icon: Theme.iImage },
        { key: "picker", label: "Selector de color", icon: Theme.iPicker },
        { key: "clipboard", label: "Portapapeles", icon: Theme.iClipboard },
        { key: "record", label: "Grabar", icon: Theme.iVideo },
        { key: "screenshot", label: "Captura", icon: Theme.iCamera },
        { key: "pomodoro", label: "Pomodoro", icon: Theme.iCoffee },
        { key: "nightlight", label: "Luz nocturna", icon: Theme.iNight },
        { key: "tray", label: "Bandeja", icon: Theme.iApps },
        { key: "updates", label: "Actualizaciones", icon: Theme.iPacman },
        { key: "bitwarden", label: "Bitwarden", icon: Theme.iBitwarden },
        { key: "keyboard", label: "Teclado", icon: Theme.iKeyboard },
        { key: "network", label: "Red", icon: Theme.iWifi },
        { key: "bluetooth", label: "Bluetooth", icon: Theme.iBt },
        { key: "servers", label: "Servidores", icon: Theme.iServer },
        { key: "github", label: "GitHub", icon: Theme.iGithub },
        { key: "ai", label: "IA", icon: Theme.iOpenCode },
        { key: "volume", label: "Volumen", icon: Theme.iVolume },
        { key: "notifications", label: "Notificaciones", icon: Theme.iBell },
        { key: "power", label: "Energía", icon: Theme.iPower }
    ]
    readonly property var barHidden: Array.from(settings.barHidden ?? [])
    function barShows(key) {
        return !barHidden.includes(key);
    }
    function toggleBarModule(key) {
        const hidden = barHidden.filter(k => k !== key);
        if (hidden.length === barHidden.length) hidden.push(key);
        settings.barHidden = hidden;
        settingsFile.writeAdapter();
    }

    // Visualizador de audio del escritorio: "off" o un estilo de Visualizer.styles
    readonly property string visualizerStyle: settings.visualizerStyle
    function setVisualizerStyle(style) {
        settings.visualizerStyle = style;
        settingsFile.writeAdapter();
    }
    // Color del visualizador: "theme", "gradient" o "white"
    readonly property string visualizerColor: settings.visualizerColor
    function setVisualizerColor(mode) {
        settings.visualizerColor = mode;
        settingsFile.writeAdapter();
    }

    function setBarPosition(position) {
        settings.barPosition = position;
        settingsFile.writeAdapter();
    }

    // Al iniciar se coloca directamente, sin animación
    property bool settingsLoaded: false

    // Entrada del escritorio (fondo y barra). Al iniciar la sesión el monitor tarda
    // un par de segundos en volver a dar imagen tras el cambio de modo; si Hyprland
    // acaba de arrancar, se espera para que las animaciones se vean. Al reiniciar
    // Quickshell a mitad de sesión, no se espera.
    property bool introReady: false
    readonly property int sessionStartDelay: 2500
    onIntroReadyChanged: if (introReady && settingsLoaded) introAnim.start()
    onSettingsLoadedChanged: {
        if (introReady && settingsLoaded) introAnim.start();
        if (settingsLoaded) applyTranslucentApps();
    }

    Process {
        command: ["sh", "-c", "ps -o etimes= -p \"$(pidof Hyprland | cut -d' ' -f1)\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const seconds = parseInt(this.text.trim());
                if (seconds >= 0 && seconds < 15) introDelay.start();
                else root.introReady = true;
            }
        }
        // Si no se pudo saber, sin esperar
        onExited: code => { if (code !== 0) root.introReady = true; }
    }
    Timer {
        id: introDelay
        interval: root.sessionStartDelay
        onTriggered: root.introReady = true
    }

    // Al cambiar la posición (desde el panel o editando el archivo):
    // sale por su borde, cambia de lado y entra por el nuevo
    Connections {
        target: settings
        function onBarPositionChanged() {
            if (!root.settingsLoaded) return;
            if (root.savedPosition !== root.barPosition || moveAnim.running) {
                introAnim.stop();
                moveAnim.restart();
            }
        }
    }

    // Entrada al iniciar la sesión, junto con el fundido del fondo (ver introReady)
    SequentialAnimation {
        id: introAnim
        PauseAnimation { duration: 350 }
        NumberAnimation {
            target: root
            property: "barHide"
            to: 0
            duration: 500
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: moveAnim

        NumberAnimation {
            target: root
            property: "barHide"
            to: 1
            duration: 200
            easing.type: Easing.InCubic
        }
        ScriptAction { script: root.barPosition = root.savedPosition }
        // Deja que la barra se recoloque en el borde nuevo antes de entrar
        PauseAnimation { duration: 100 }
        NumberAnimation {
            target: root
            property: "barHide"
            to: 0
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    // Espacio que ocupa la barra en un borde del monitor (0 si no está ahí).
    // Los paneles que ignoran la zona exclusiva lo suman a su margen.
    function reserve(edge) {
        return barPosition === edge ? Theme.barHeight : 0;
    }

    // Posición de un popup de la barra, en coordenadas de la ventana de la barra:
    // pegado a su borde interior, centrado en "center" (el centro del elemento que
    // lo abre) y sin salirse del monitor.
    function popupPos(win, center, w, h) {
        if (!win) return Qt.point(0, 0);
        const gap = 8;
        const clamp = (v, size, max) => Math.round(Math.max(gap, Math.min(max - size - gap, v)));
        if (barVertical)
            return Qt.point(barPosition === "left" ? win.width + gap : -w - gap, clamp(center.y - h / 2, h, win.height));
        return Qt.point(clamp(center.x - w / 2, w, win.width), barPosition === "top" ? win.height + gap : -h - gap);
    }

    FileView {
        id: settingsFile
        path: Quickshell.statePath("settings.json")
        blockLoading: true
        // Aún no existe hasta el primer cambio: no es un error
        printErrors: false
        // Editar el archivo a mano también mueve la barra
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (root.settingsLoaded) return;
            root.barPosition = root.savedPosition;
            root.settingsLoaded = true;
        }
        onLoadFailed: root.settingsLoaded = true

        JsonAdapter {
            id: settings
            property string barPosition: "top"
            // Selector de fondos: "carousel" o "grid"
            property string wallpaperPicker: "carousel"
            // Monitor principal elegido en el módulo de pantallas ("" = automático)
            property string primaryMonitor: ""
            // Temperatura de la luz nocturna en K (0 = la de por defecto)
            property int nightLightTemp: 0
            // Barra y paneles translúcidos con desenfoque
            property bool translucent: false
            // Estilo del visualizador de audio del escritorio ("off" = apagado)
            property string visualizerStyle: "bars"
            property string visualizerColor: "theme"
            // Módulos de la barra ocultos (claves de barModules)
            property list<string> barHidden: []
        }
    }

    function toggle() {
        // Evita reabrir si el mismo clic en el engranaje acaba de cerrarlo
        if (!open && Date.now() - closedAt < 300) return;
        open = !open;
    }

    function close() {
        if (!open) return;
        open = false;
        closedAt = Date.now();
    }

    IpcHandler {
        target: "config"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.close(); }
    }

}
