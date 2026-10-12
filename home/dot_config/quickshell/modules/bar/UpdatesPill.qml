import QtQuick
import qs.components.buttons
import qs.modules.updates
import qs.services

// Actualizaciones: solo el Pac-Man (sin píldora), sin números. Pasa de blanco a
// amarillo según cuántas haya entre pacman y AUR. Clic = panel (con las dos listas).
IconButton {
    id: root

    property bool compact: false

    text: Theme.iPacman
    color: Updates.totalColor()
    opacity: Updates.checking && Updates.lastCheck.getTime() === 0 ? 0.5 : 1
    Behavior on color { ColorAnimation { duration: 400 } }
    onClicked: panel.toggle()

    UpdatesPanel {
        id: panel
        anchorItem: root
    }
}
