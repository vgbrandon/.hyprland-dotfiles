import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Widgets

// Panel del reproductor: carátula, título, artista, progreso y controles
PopupWindow {
    id: panel

    required property MprisPlayer player
    required property Item anchorItem
    // Las transmisiones en vivo reportan duraciones absurdas
    readonly property bool hasLength: (player?.length ?? 0) > 0 && player.length < 86400

    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    anchor.item: anchorItem
    anchor.rect.x: popupPos.x
    anchor.rect.y: popupPos.y
    // Junto a la barra, esté donde esté
    readonly property point popupPos: Config.popupPos(anchorItem, implicitWidth, implicitHeight, visible)
    implicitWidth: 380
    implicitHeight: 124
    color: "transparent"

    property real closedAt: 0

    // Abre/cierra desde el botón de la barra. Si el mismo clic acaba de
    // cerrarlo (clic fuera del panel), no lo vuelve a abrir.
    function toggle() {
        if (!visible && Date.now() - closedAt < 300) return;
        visible = !visible;
    }

    // Clic fuera del panel = cerrar
    HyprlandFocusGrab {
        id: grab
        windows: [panel]
        onCleared: {
            panel.visible = false;
            panel.closedAt = Date.now();
        }
    }

    // Activa el grab cuando la ventana ya está mapeada
    onVisibleChanged: {
        grab.active = false;
        if (visible) grabTimer.restart();
    }
    Timer {
        id: grabTimer
        interval: 50
        onTriggered: grab.active = panel.visible
    }

    // Mpris no actualiza la posición solo
    Timer {
        interval: 1000
        repeat: true
        running: panel.visible && (panel.player?.isPlaying ?? false)
        onTriggered: panel.player.positionChanged()
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.surface

        // Fondo: carátula desenfocada
        Image {
            id: bgArt
            anchors.fill: parent
            source: panel.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: bgArt
            blurEnabled: true
            blur: 1
            blurMax: 64
            opacity: 0.3
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 14

            ClippingRectangle {
                implicitWidth: 100
                implicitHeight: 100
                radius: Theme.radiusSmall
                color: Theme.surfaceHigh

                Icon {
                    anchors.centerIn: parent
                    text: Theme.iMusic
                    color: Theme.subtext
                    font.pixelSize: 36
                }
                Image {
                    anchors.fill: parent
                    source: panel.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Label {
                    Layout.fillWidth: true
                    text: panel.player?.trackTitle || "Sin título"
                    font.pixelSize: 16
                }
                Label {
                    Layout.fillWidth: true
                    text: panel.player?.trackArtist ?? ""
                    color: Theme.subtext
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Label {
                        Layout.fillWidth: true
                        text: panel.hasLength ? `${panel.fmt(panel.player.position)} / ${panel.fmt(panel.player.length)}` : "En vivo"
                        color: Theme.subtext
                    }

                    // Play / pausa
                    Rectangle {
                        implicitWidth: 38
                        implicitHeight: 38
                        radius: Theme.radiusSmall
                        color: Theme.surfaceHigh

                        Icon {
                            anchors.centerIn: parent
                            text: panel.player?.isPlaying ? Theme.iPause : Theme.iPlay
                            font.pixelSize: 20
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panel.player?.togglePlaying()
                        }
                    }
                }

                RowLayout {
                    spacing: 6

                    Icon {
                        text: Theme.iPrev
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panel.player?.previous()
                        }
                    }

                    WavyProgress {
                        Layout.fillWidth: true
                        progress: panel.hasLength ? panel.player.position / panel.player.length : 1
                        animating: panel.visible && (panel.player?.isPlaying ?? false)
                        onSeek: f => {
                            if (panel.hasLength && panel.player.canSeek)
                                panel.player.position = f * panel.player.length;
                        }
                    }

                    Icon {
                        text: Theme.iNext
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panel.player?.next()
                        }
                    }
                }
            }
        }
    }
}
