import QtQuick
import Quickshell

ShellRoot {
    // Crea al inicio los módulos que se controlan por IPC para que respondan a IPC
    Component.onCompleted: {
        Launcher.open = false;
        PowerMenu.open = false;
        Screenshot.active = false;
        Notifs.dnd = false; // inicia el servidor de notificaciones
        Config.open = false; // crea el panel de ajustes rápidos
        Wallpaper.open = false; // crea el fondo (y el reloj del escritorio)
        Lock.locked = false; // registra el IPC de la pantalla de bloqueo
        ColorPicker.active = false; // registra el IPC del selector de color
        Updates.checking; // empieza a buscar actualizaciones
        Recorder.recording; // registra el IPC de la grabación de pantalla
        Media.player; // registra el IPC del reproductor multimedia
        Displays.open = false; // registra el IPC del módulo de pantallas
        SystemStats.cpu; // registra el IPC del panel del sistema
        AulaKeyboard.open = false; // teclado AULA: IPC y sincronización del reloj al conectarlo
        Pomodoro.running; // registra el IPC del pomodoro (y avisa si terminó con Quickshell cerrado)
        Clipboard.open = false; // historial del portapapeles: IPC y vigilancia de lo copiado
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
