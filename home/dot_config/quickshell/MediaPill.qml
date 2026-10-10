import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris

// Píldora multimedia: controla lo que esté sonando en cualquier app.
// Anterior, play/pausa, siguiente + título (clic = panel).
// Clic derecho en play/pausa = panel (en la barra vertical no hay título).
// Sin nada abierto, todo se ve apagado.
Pill {
    id: root

    readonly property MprisPlayer player: Media.player
    readonly property bool active: player !== null
    // Ancho máximo del título (menor en monitores estrechos)
    property int titleWidth: 200

    spacing: 10
    // Barra vertical en un monitor bajo: solo si hay algo que controlar
    visible: !compact || active

    // En la barra vertical de un monitor bajo solo cabe play/pausa
    Icon {
        visible: !root.compact
        text: Theme.iPrev
        color: root.player?.canGoPrevious ? Theme.text : Theme.dot

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Media.previous()
        }
    }
    Icon {
        text: root.player?.isPlaying ? Theme.iPause : Theme.iPlay
        color: root.player?.canTogglePlaying ? Theme.text : Theme.dot

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: e => {
                if (e.button === Qt.RightButton) {
                    if (root.active) panel.toggle();
                } else {
                    Media.togglePlaying();
                }
            }
        }
    }
    Icon {
        visible: !root.compact
        text: Theme.iNext
        color: root.player?.canGoNext ? Theme.text : Theme.dot

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Media.next()
        }
    }

    // Título • artista (no cabe en la barra vertical)
    Label {
        visible: root.active && !root.vertical
        Layout.maximumWidth: root.titleWidth
        text: {
            const p = root.player;
            if (!p) return "";
            return p.trackArtist ? `${p.trackTitle} • ${p.trackArtist}` : p.trackTitle;
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: panel.toggle()
        }
    }

    // IPC: abre el panel en el monitor enfocado
    Connections {
        target: Media
        function onPanelRequested() {
            if (root.active && Hyprland.monitorFor(root.QsWindow.window?.screen) === Hyprland.focusedMonitor) panel.toggle();
        }
    }

    MediaPanel {
        id: panel
        player: root.player
        anchorItem: root
        visible: false
    }
}
