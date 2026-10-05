import QtQuick
import Quickshell

ShellRoot {
    // Crea al inicio los módulos que se controlan por IPC para que respondan a IPC
    Component.onCompleted: {
        Launcher.open = false;
        PowerMenu.open = false;
        Screenshot.active = false;
        Notifs.dnd = false; // inicia el servidor de notificaciones
        Wallpaper.open = false; // crea el fondo (y el reloj del escritorio)
        Lock.locked = false; // registra el IPC de la pantalla de bloqueo
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
