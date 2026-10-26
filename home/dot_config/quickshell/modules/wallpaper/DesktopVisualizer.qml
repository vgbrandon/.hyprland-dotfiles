import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.modules.visualizer
import qs.services

// Visualizador de audio sobre el fondo del monitor principal (va en la capa del fondo,
// debajo de las ventanas): los estilos en línea, al pie; los redondos (círculo, anillo,
// burbuja), en el centro. Aparece con un fundido cuando suena algo y se apaga en
// silencio. Los estilos en línea ocupan todo el ancho, con el mismo margen que las
// ventanas (gaps_out de Hyprland). Estilo y color: Ajustes → Visualizador
// (modules/visualizer).
Item {
    id: root

    anchors.fill: parent
    anchors.leftMargin: Config.reserve("left")
    anchors.rightMargin: Config.reserve("right")
    anchors.topMargin: Config.reserve("top")
    anchors.bottomMargin: Config.reserve("bottom")

    visible: opacity > 0
    opacity: Visualizer.active && Visualizer.style !== "off" && Visualizer.level > 0.005 ? 0.85 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: Design.slow
        }
    }

    // Margen exterior de las ventanas; se vuelve a leer al aparecer (por si cambió en
    // Ajustes) y al recargar la configuración de Hyprland
    HyprOption {
        id: gapsOut
        option: "general:gaps_out"
        fallback: 10
    }
    readonly property int gap: gapsOut.intValue
    onVisibleChanged: if (visible) gapsOut.refresh()
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") gapsOut.refresh();
        }
    }

    VisualizerView {
        id: view
        x: radial ? Math.round((root.width - width) / 2) : root.gap
        y: radial ? Math.round((root.height - height) / 2) : root.height - height - root.gap
        width: radial ? 560 : root.width - root.gap * 2
        height: radial ? 560 : 200
    }
}
