import QtQuick
import Quickshell.Wayland

// Superficie de bloqueo de un monitor (el contenido está en LockContent.qml)
WlSessionLockSurface {
    id: surface

    color: "black"

    LockContent {
        anchors.fill: parent
        screen: surface.screen
    }
}
