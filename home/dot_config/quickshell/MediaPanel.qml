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
    // Duración de la pista. Algunos reproductores (Firefox con YouTube) a ratos dejan
    // de informarla (lengthSupported falso) y Quickshell pone la posición como duración:
    // se recuerda la última conocida de la misma pista y se usa mientras falte.
    readonly property string trackKey: `${player?.identity ?? ""}|${player?.trackTitle ?? ""}`
    readonly property real reportedLength: (player?.lengthSupported ?? false) ? (player.length ?? 0) : 0
    property real cachedLength: 0
    property string cachedKey: ""
    onReportedLengthChanged: rememberLength()
    onTrackKeyChanged: rememberLength()
    function rememberLength() {
        if (reportedLength > 0) {
            cachedLength = reportedLength;
            cachedKey = trackKey;
        }
    }
    readonly property real trackLength: reportedLength > 0 ? reportedLength : cachedKey === trackKey ? cachedLength : 0

    // Sin duración conocida, no se muestra progreso. Las transmisiones en vivo
    // reportan duraciones absurdas.
    readonly property bool live: trackLength >= 86400
    readonly property bool hasLength: trackLength > 0 && !live

    // m:ss, o h:mm:ss si pasa de una hora
    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), sec = String(s % 60).padStart(2, "0");
        return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${sec}` : `${m}:${sec}`;
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
                        text: panel.hasLength ? `${panel.fmt(panel.player.position)} / ${panel.fmt(panel.trackLength)}`
                            : panel.live ? "En vivo" : panel.fmt(panel.player?.position ?? 0)
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
                        // Sin duración conocida (o en vivo): de lado a lado, y tenue si se
                        // desconoce, para no fingir un progreso
                        progress: panel.hasLength ? Math.max(0, Math.min(1, panel.player.position / panel.trackLength)) : 1
                        lineColor: panel.hasLength || panel.live ? Theme.text : Theme.withAlpha(Theme.text, 0.35)
                        animating: panel.visible && (panel.player?.isPlaying ?? false)
                        onSeek: f => {
                            if (panel.hasLength && panel.player.canSeek)
                                panel.player.position = f * panel.trackLength;
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
