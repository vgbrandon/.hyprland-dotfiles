import QtQuick
import qs.modules.visualizer
import qs.services

// Visualizador de audio sobre el fondo del monitor principal (va en la capa del fondo,
// debajo de las ventanas): los estilos en línea, al pie; los redondos (círculo, anillo,
// burbuja), en el centro. Aparece con un fundido cuando suena algo y se apaga en
// silencio. Estilo y color: Ajustes → Visualizador (modules/visualizer).
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

    VisualizerView {
        id: view
        x: radial ? Math.round((root.width - width) / 2) : 40
        y: radial ? Math.round((root.height - height) / 2) : root.height - height - 24
        width: radial ? 560 : root.width - 80
        height: radial ? 560 : 200
    }
}
