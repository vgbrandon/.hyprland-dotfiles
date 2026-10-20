import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.components.base
import qs.components.buttons
import qs.components.containers
import qs.services

// Panel del reproductor: carátula, título, artista, progreso y controles
BarPopup {
    id: panel

    required property MprisPlayer player
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

    padding: 0
    // El fondo es la carátula desenfocada
    background.visible: false

    // Mpris no actualiza la posición solo
    Timer {
        interval: 1000
        repeat: true
        running: panel.visible && (panel.player?.isPlaying ?? false)
        onTriggered: panel.player.positionChanged()
    }

    ClippingRectangle {
        Layout.fillWidth: true
        implicitHeight: 124
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
                    CircleButton {
                        icon: panel.player?.isPlaying ? Theme.iPause : Theme.iPlay
                        size: 38
                        iconSize: 20
                        filled: true
                        color: hovered ? Theme.surfaceHigh : Theme.withAlpha(Theme.surfaceHigh, 0.8)
                        onClicked: panel.player?.togglePlaying()
                    }
                }

                RowLayout {
                    spacing: 6

                    IconButton {
                        text: Theme.iPrev
                        onClicked: panel.player?.previous()
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

                    IconButton {
                        text: Theme.iNext
                        onClicked: panel.player?.next()
                    }
                }
            }
        }
    }
}
