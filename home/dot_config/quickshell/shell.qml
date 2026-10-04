import QtQuick
import Quickshell

ShellRoot {
    // Crea el lanzador, el menú de energía y las capturas al inicio para que respondan a IPC
    Component.onCompleted: {
        Launcher.open = false;
        PowerMenu.open = false;
        Screenshot.active = false;
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        DesktopClock {
            required property var modelData
            screen: modelData
        }
    }
}
