import QtQuick
import Quickshell

ShellRoot {
    // Crea el lanzador, el menú de energía y las capturas al inicio para que respondan a IPC
    Component.onCompleted: {
        Launcher.open = false;
        PowerMenu.open = false;
        Screenshot.active = false;
        Notifs.dnd = false; // inicia el servidor de notificaciones
        Wallpaper.open = false; // crea el fondo (y el reloj del escritorio)
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
