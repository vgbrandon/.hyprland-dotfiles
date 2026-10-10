pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

// Pantalla de bloqueo (protocolo de bloqueo de Wayland + contraseña por PAM).
//   quickshell ipc call lock lock
// Si Quickshell se cerrara con la sesión bloqueada, Hyprland la mantiene bloqueada.
Singleton {
    id: root

    property bool locked: false
    property string buffer: ""
    property bool checking: false
    property string error: ""
    // Aumenta en cada intento fallido (lo usa la animación de temblor)
    property int failCount: 0
    // Contraseña correcta: animación de salida antes de quitar el bloqueo
    property bool unlocking: false

    function lock() {
        if (locked) return;
        buffer = "";
        error = "";
        unlocking = false;
        locked = true;
    }

    // Tras la animación de salida (el contenido se va; el fondo se queda): quita el bloqueo
    Timer {
        id: unlockTimer
        interval: 500
        onTriggered: {
            root.locked = false;
            root.unlocking = false;
        }
    }

    function submit() {
        if (checking || buffer === "") return;
        checking = true;
        error = "";
        if (!pam.start()) {
            checking = false;
            error = "No se pudo iniciar la autenticación";
        }
    }

    // Usa la configuración PAM "login": la misma contraseña que al iniciar sesión
    PamContext {
        id: pam

        onPamMessage: {
            if (responseRequired) respond(root.buffer);
        }
        onCompleted: result => {
            root.checking = false;
            root.buffer = "";
            if (result === PamResult.Success) {
                root.unlocking = true;
                unlockTimer.restart();
            } else {
                root.error = result === PamResult.MaxTries
                    ? "Demasiados intentos, espera unos minutos"
                    : "Contraseña incorrecta";
                root.failCount++;
            }
        }
        onError: {
            root.checking = false;
            root.buffer = "";
            root.error = "Error de autenticación";
            root.failCount++;
        }
    }

    WlSessionLock {
        locked: root.locked

        LockSurface {}
    }

    IpcHandler {
        target: "lock"

        function lock(): void { root.lock(); }
    }
}
