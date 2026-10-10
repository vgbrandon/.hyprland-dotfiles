import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Pantalla de inicio de sesión (greeter de greetd), con el mismo diseño que la
// pantalla de bloqueo. Corre en un Hyprland mínimo
// como el usuario "greeter"; ver hyprland.lua y config.toml en esta carpeta.
ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            // Monitor principal: el que se eligió en el módulo de pantallas de la sesión.
            // Si no está conectado, el más grande; si hay varios del mismo tamaño, el de
            // más a la izquierda (y luego el de más arriba). Solo ese muestra la tarjeta
            // y pide el teclado.
            readonly property bool main: {
                const chosen = Quickshell.screens.find(s => s.name === Theme.primaryMonitor);
                if (chosen) return modelData === chosen;
                const area = s => s.width * s.height;
                const better = (a, b) => area(b) !== area(a) ? area(b) > area(a)
                    : b.x !== a.x ? b.x < a.x : b.y < a.y;
                const primary = Quickshell.screens.reduce((a, b) => better(a, b) ? b : a, Quickshell.screens[0]);
                return modelData === primary;
            }

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

            // Al arrancar, el cursor (y con él el foco de Hyprland) va al centro del principal
            Component.onCompleted: {
                if (!main) return;
                const x = Math.round(modelData.x + modelData.width / 2);
                const y = Math.round(modelData.y + modelData.height / 2);
                Hyprland.dispatch(`hl.dsp.cursor.move({ x = ${x}, y = ${y} })`);
            }

            GreeterContent {
                anchors.fill: parent
                screen: win.modelData
                main: win.main
            }

            // Al entrar: fundido a negro antes de lanzar la sesión (que empieza en negro)
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: Auth.launching ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 600; easing.type: Easing.InOutQuad }
                }
            }
        }
    }
}
