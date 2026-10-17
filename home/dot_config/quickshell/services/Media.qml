pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Reproductor multimedia general: controla por MPRIS lo que esté sonando
// (Spotify, Tidal, Firefox, mpv…). Lo usan la píldora multimedia y su panel.
//   quickshell ipc call media toggle | playpause | next | previous
Singleton {
    id: root

    // El que está sonando; si ninguno, el último que sonó (si sigue abierto) y, si no,
    // el primero. Si el que suena se para un instante (TikTok o YouTube al pasar de un
    // vídeo a otro), espera un poco antes de cambiar de reproductor, para que la píldora
    // no salte a otro y vuelva.
    property MprisPlayer player: null
    readonly property var players: Mpris.players.values
    readonly property var playing: players.filter(p => p.isPlaying)

    function pick() {
        // Si suenan varios, se queda con el actual
        if (player && playing.includes(player)) {
            hold.stop();
        } else if (playing.length > 0) {
            hold.stop();
            player = playing[0];
        } else if (!player || !players.includes(player)) {
            hold.restart();
        }
    }
    onPlayingChanged: pick()
    onPlayersChanged: pick()
    Component.onCompleted: {
        player = playing[0] ?? players[0] ?? null;
        applyShown();
    }

    Timer {
        id: hold
        interval: 1500
        onTriggered: root.player = root.playing[0] ?? (root.player && root.players.includes(root.player) ? root.player : null) ?? root.players[0] ?? null
    }

    // Lo que muestra la píldora. Firefox tiene un solo reproductor para todas las
    // pestañas: al pasar de un vídeo de TikTok a otro, un instante enseña la pestaña de
    // YouTube en pausa. Así que una pista distinta que no suena espera un poco antes de
    // mostrarse; si suena, o es la misma pista (pausar/reanudar), se muestra al momento.
    property string title: ""
    property string artist: ""
    property bool isPlaying: false

    readonly property string rawTitle: player?.trackTitle ?? ""
    readonly property string rawArtist: player?.trackArtist ?? ""
    readonly property bool rawPlaying: player?.isPlaying ?? false

    function applyShown() {
        settle.stop();
        title = rawTitle;
        artist = rawArtist;
        isPlaying = rawPlaying;
    }
    function rawChanged() {
        if (rawPlaying || (rawTitle === title && rawArtist === artist)) applyShown();
        else settle.restart();
    }
    onRawTitleChanged: rawChanged()
    onRawArtistChanged: rawChanged()
    onRawPlayingChanged: rawChanged()

    Timer {
        id: settle
        interval: 1200
        onTriggered: root.applyShown()
    }

    // Pide abrir/cerrar el panel (lo abre la barra del monitor principal)
    signal panelRequested()

    function togglePlaying() {
        if (player?.canTogglePlaying) player.togglePlaying();
    }
    function previous() {
        if (player?.canGoPrevious) player.previous();
    }
    function next() {
        if (player?.canGoNext) player.next();
    }

    IpcHandler {
        target: "media"

        function toggle(): void { root.panelRequested(); }
        function playpause(): void { root.togglePlaying(); }
        function next(): void { root.next(); }
        function previous(): void { root.previous(); }
    }
}
