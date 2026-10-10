import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Pantalla de inicio de sesión (greeter de greetd). Corre en un Hyprland mínimo
// como el usuario "greeter"; ver hyprland.lua y config.toml en esta carpeta.
ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            // Por nombre: al arrancar, monitorFor() aún no conoce los monitores y no se reevalúa
            readonly property bool main: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "black"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            // El teclado va al monitor enfocado (donde está el campo de contraseña)
            WlrLayershell.keyboardFocus: main ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell:greeter"

            GreeterContent {
                anchors.fill: parent
                screen: win.modelData
                main: win.main
            }
        }
    }
}
