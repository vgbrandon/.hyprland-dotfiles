pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Visualizador de audio del escritorio: cava analiza lo que suena (la salida de
// PipeWire) y da el nivel de cada banda de frecuencia. Solo corre con un estilo elegido
// (o con el selector abierto) y mientras suena algo en un reproductor. El dibujo está
// en modules/visualizer (VisualizerView); el selector, en VisualizerPicker.
//   quickshell ipc call visualizer picker
Singleton {
    id: root

    // Estilos que se pueden elegir (además de "off", apagado) y colores
    readonly property var styles: [
        { key: "bars", label: "Barras" },
        { key: "mirror", label: "Espejo" },
        { key: "digital", label: "Digital" },
        { key: "dots", label: "Puntos" },
        { key: "wave", label: "Onda" },
        { key: "line", label: "Líneas" },
        { key: "circle", label: "Círculo" },
        { key: "ring", label: "Anillo" },
        { key: "blob", label: "Burbuja" }
    ]
    readonly property var colors: [
        { key: "theme", label: "Tema" },
        { key: "gradient", label: "Degradado" },
        { key: "white", label: "Blanco" }
    ]
    readonly property string style: Config.visualizerStyle
    readonly property string colorMode: Config.visualizerColor
    function labelOf(key) {
        return key === "off" ? "Apagado" : styles.find(st => st.key === key)?.label ?? key;
    }

    // Selector de estilos (con vista previa en vivo)
    property bool pickerOpen: false

    readonly property int bands: 64

    // Corre si hay estilo y suena algo (rawPlaying arranca enseguida; isPlaying, que
    // tarda en apagarse, evita pararlo al pasar de una canción a otra)
    readonly property bool active: (style !== "off" || pickerOpen) && (Media.rawPlaying || Media.isPlaying)

    // Nivel de cada banda (0–1) y el total, para atenuar el dibujo en silencio
    property var values: []
    property real level: 0

    readonly property string configPath: Quickshell.cachePath("cava.conf")

    FileView {
        id: configFile
        path: root.configPath
        printErrors: false
    }
    // Salida en texto: una línea por fotograma, con los valores (0–1000) separados por ;
    function writeConfig() {
        configFile.setText(`[general]
bars = ${bands}
framerate = 60
autosens = 1

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 1000
bar_delimiter = 59
frame_delimiter = 10
channels = mono

[smoothing]
noise_reduction = 77
`);
    }
    Component.onCompleted: writeConfig()

    IpcHandler {
        target: "visualizer"

        function picker(): void { root.pickerOpen = !root.pickerOpen; }
    }

    Process {
        id: cava
        running: root.active
        command: ["cava", "-p", root.configPath]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";");
                const v = new Array(root.bands);
                let sum = 0;
                for (let i = 0; i < root.bands; i++) {
                    const x = (parseInt(parts[i]) || 0) / 1000;
                    v[i] = x;
                    sum += x;
                }
                root.values = v;
                root.level = sum / root.bands;
            }
        }
        onRunningChanged: if (!running) {
            root.values = [];
            root.level = 0;
        }
    }
}
