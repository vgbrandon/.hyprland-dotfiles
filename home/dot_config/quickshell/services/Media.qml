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

    // El que está sonando; si ninguno, el primero
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    // Pide abrir/cerrar el panel (lo abre la píldora del monitor enfocado)
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
