import QtQuick
import Quickshell
import qs.modules.ai
import qs.modules.bar
import qs.modules.clipboard
import qs.modules.colorpicker
import qs.modules.config
import qs.modules.displays
import qs.modules.iconeditor
import qs.modules.kblayout
import qs.modules.keyboard
import qs.modules.launcher
import qs.modules.lock
import qs.modules.notes
import qs.modules.notifications
import qs.modules.palettes
import qs.modules.osd
import qs.modules.polkit
import qs.modules.stickers
import qs.modules.power
import qs.modules.profile
import qs.modules.screenshot
import qs.modules.shortcuts
import qs.modules.velureguide
import qs.modules.visualizer
import qs.modules.wallpaper
import qs.services

// Solo instancia la interfaz: la lógica está en services/ y cada ventana en modules/.
// Las ventanas usan sus servicios, así que estos se crean (y registran su IPC) al iniciar.
ShellRoot {
    // Por monitor: fondo (con el reloj del escritorio)
    Variants {
        model: Quickshell.screens

        WallpaperWindow {}
    }
    // La barra solo en el monitor principal: los demás son extensiones
    Bar {
        screen: Hypr.mainScreen
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
    OsdWindow {}

    // Ventanas sobre todo lo demás
    LauncherWindow {}
    ClipboardWindow {}
    PowerMenuWindow {}
    PolkitWindow {}
    ProfileWindow {}
    ShortcutsWindow {}
    NotesWindow {}
    VisualizerPicker {}
    DisplaysWindow {}
    KeyboardWindow {}
    LayoutMapWindow {}
    VelureGuideWindow {}
    PaletteGuideWindow {}
    StickerWindow {}
    IconEditor {}
    // Selector de fondos: carrusel o cuadrícula (Ajustes → Selector de fondos)
    WallpaperCarousel {}
    WallpaperGrid {}

    LockScreen {}
}
