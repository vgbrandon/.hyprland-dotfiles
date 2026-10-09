import QtQuick

// Píldora de actualizaciones: Pac-Man = pacman, fantasma = AUR. Sin números:
// cada icono pasa de blanco a amarillo / azul según cuántas haya. Clic = panel.
Item {
    id: root

    property bool compact: false

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Pill {
        id: pill
        compact: root.compact

        anchors.fill: parent
        spacing: 10
        opacity: Updates.checking && Updates.lastCheck.getTime() === 0 ? 0.5 : 1

        Icon {
            text: Theme.iPacman
            color: Updates.pacmanColor()
            font.pixelSize: 16
            Behavior on color { ColorAnimation { duration: 400 } }
        }
        Icon {
            text: Theme.iGhost
            color: Updates.aurColor()
            font.pixelSize: 16
            Behavior on color { ColorAnimation { duration: 400 } }
        }
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
