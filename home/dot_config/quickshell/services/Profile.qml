pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Perfil del usuario: foto, nombre que se muestra, equipo y tiempo encendido. La
// foto se guarda en ~/.face (el sitio estándar que leen otras apps) recortada en
// cuadrado; el nombre, en profile.json. Los dos se comparten con la pantalla de
// inicio de sesión (Theme.shareWithGreeter). La ventana está en modules/profile.
//   quickshell ipc call profile toggle
Singleton {
    id: root

    property bool open: false
    function toggle() {
        open = !open;
    }

    readonly property string user: Quickshell.env("USER") ?? ""
    readonly property string home: Quickshell.env("HOME") ?? ""
    property string host: ""
    // Nombre real del sistema (campo GECOS de /etc/passwd), si lo hay
    property string realName: ""
    // El que se muestra: el elegido aquí, el real o el usuario
    readonly property string name: store.name || realName || user
    readonly property string initial: name.charAt(0).toUpperCase()

    // --- Foto ---
    readonly property string avatarPath: home + "/.face"
    property bool hasAvatar: false
    // Cambia con cada foto nueva: las imágenes la añaden a la URL para no usar la anterior en caché
    property int avatarRev: 0
    readonly property string avatarUrl: hasAvatar ? `file://${avatarPath}?${avatarRev}` : ""
    property bool working: false

    // Recorta al centro en cuadrado, a 512 px, y la guarda como PNG en ~/.face
    function setAvatar(path) {
        working = true;
        avatarProc.command = ["sh", "-c", 'ffmpeg -loglevel error -y -i "$1" -frames:v 1 '
            + '-vf "crop=min(iw\\,ih):min(iw\\,ih),scale=512:512:flags=lanczos" -f image2 -c:v png "$2.tmp" '
            + '&& mv -f "$2.tmp" "$2"', "sh", path, avatarPath];
        avatarProc.running = true;
    }
    function removeAvatar() {
        avatarProc.command = ["rm", "-f", avatarPath];
        avatarProc.running = true;
    }
    Process {
        id: avatarProc
        onExited: {
            root.working = false;
            root.avatarRev++;
            checkAvatar.running = true;
        }
    }
    Process {
        id: checkAvatar
        command: ["test", "-s", root.avatarPath]
        running: true
        onExited: code => {
            root.hasAvatar = code === 0;
            Theme.shareWithGreeter();
        }
    }

    // --- Nombre ---
    function setName(n) {
        store.name = n.trim() === root.user ? "" : n.trim();
        file.writeAdapter();
        Theme.shareWithGreeter();
    }

    FileView {
        id: file
        path: Quickshell.statePath("profile.json")
        blockLoading: true
        printErrors: false

        JsonAdapter {
            id: store
            property string name: ""
        }
    }

    // Equipo y nombre real
    Process {
        command: ["sh", "-c", 'cat /etc/hostname; getent passwd "$USER" | cut -d: -f5 | cut -d, -f1']
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n");
                root.host = (lines[0] ?? "").trim();
                root.realName = (lines[1] ?? "").trim();
            }
        }
    }

    // --- Tiempo encendido (se actualiza cada minuto) ---
    property int uptime: 0 // segundos
    readonly property string uptimeText: {
        const m = Math.floor(uptime / 60), h = Math.floor(m / 60), d = Math.floor(h / 24);
        if (d > 0) return `${d} d ${h % 24} h`;
        if (h > 0) return `${h} h ${m % 60} min`;
        return `${m} min`;
    }
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptime = Math.floor(parseFloat(text().split(" ")[0]))
    }
    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeFile.reload()
    }

    // Cambiar la contraseña: passwd necesita una terminal
    function changePassword() {
        open = false;
        Quickshell.execDetached(["kitty", "--class", "qs-passwd", "--title", "Cambiar contraseña",
            "sh", "-c", 'echo "Cambiar la contraseña de $USER"; echo; passwd; echo; read -p "Pulsa Enter para cerrar" _']);
    }

    IpcHandler {
        target: "profile"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }
}
