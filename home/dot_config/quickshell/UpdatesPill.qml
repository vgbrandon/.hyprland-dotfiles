import QtQuick

// Actualizaciones: solo el Pac-Man (sin píldora), sin números. Pasa de blanco a
// amarillo según cuántas haya entre pacman y AUR. Clic = panel (con las dos listas).
Item {
    id: root

    property bool compact: false

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    // Icono suelto, sin píldora (como los de red o Bluetooth)
    Icon {
        id: icon
        anchors.centerIn: parent
        text: Theme.iPacman
        color: Updates.totalColor()
        font.pixelSize: 16
        opacity: Updates.checking && Updates.lastCheck.getTime() === 0 ? 0.5 : 1
        Behavior on color { ColorAnimation { duration: 400 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.toggle()
    }

    UpdatesPanel {
        id: panel
        anchorItem: root
        visible: false
    }
}
