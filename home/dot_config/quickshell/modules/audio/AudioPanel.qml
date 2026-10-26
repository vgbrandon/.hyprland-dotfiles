import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.components.base
import qs.components.containers
import qs.components.controls
import qs.components.design
import qs.services

// Panel de sonido (clic en el volumen de la barra), con el diseño Velure: volumen y
// dispositivo de salida, volumen y dispositivo de entrada, y el volumen de cada app que
// suena. Lógica en services/Audio.qml.
BarPopup {
    id: panel

    padding: 14
    spacing: 12

    PanelHeader {
        icon: Theme.iVolume
        title: "Sonido"
        subtitle: Audio.nameOf(Audio.sink)
    }

    // --- Salida ---
    Section {
        title: "Salida"
        contentSpacing: 6

        VolumeRow {
            node: Audio.sink
            icon: Audio.sink?.audio?.muted ? Theme.iMuted : Audio.iconOf(Audio.sink)
        }
        Repeater {
            model: Audio.sinks
            DeviceRow {
                required property var modelData
                node: modelData
            }
        }
    }

    // --- Entrada ---
    Section {
        title: "Entrada"
        contentSpacing: 6
        visible: Audio.sources.length > 0

        VolumeRow {
            node: Audio.source
            icon: Audio.source?.audio?.muted ? Theme.iMicOff : Theme.iMic
        }
        Repeater {
            model: Audio.sources
            DeviceRow {
                required property var modelData
                node: modelData
            }
        }
    }

    // --- Aplicaciones ---
    Section {
        title: "Aplicaciones"
        contentSpacing: 6
        visible: Audio.playing.length > 0

        Repeater {
            model: Audio.playing
            AppRow {
                required property var modelData
                node: modelData
            }
        }
    }

}
