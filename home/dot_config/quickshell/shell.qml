import QtQuick
import Quickshell
import qs.modules.ai
import qs.modules.bar
import qs.modules.clipboard
import qs.modules.colorpicker
import qs.modules.config
import qs.modules.displays
import qs.modules.keyboard
import qs.modules.launcher
import qs.modules.lock
import qs.modules.notifications
import qs.modules.power
import qs.modules.screenshot
import qs.modules.wallpaper

// Solo instancia la interfaz: la lógica está en services/ y cada ventana en modules/.
// Las ventanas usan sus servicios, así que estos se crean (y registran su IPC) al iniciar.
ShellRoot {
    // Por monitor: fondo (con el reloj del escritorio) y barra
    Variants {
        model: Quickshell.screens

        WallpaperWindow {}
    }
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }

    // Capturas y selector de color (uno por monitor). La capa que oculta el cursor
    // va antes: la usan los dos mientras congelan la pantalla.
    Variants {
        model: Quickshell.screens

        CursorHider {}
    }
    Variants {
        model: Quickshell.screens

        CaptureWindow {}
    }
    Variants {
        model: Quickshell.screens

        PickerWindow {}
    }

    // Paneles laterales y popups de notificaciones
    AIPanel {}
    ConfigPanel {}
    NotificationCenter {}
    NotificationPopups {}

    // Ventanas sobre todo lo demás
    LauncherWindow {}
    ClipboardWindow {}
    PowerMenuWindow {}
    DisplaysWindow {}
    KeyboardWindow {}
    WallpaperPicker {}

    LockScreen {}
}
