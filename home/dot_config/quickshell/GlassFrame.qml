import QtQuick

// Fondo de vidrio para paneles (shaders/glassframe.frag). El desenfoque de lo
// que hay detrás lo hace Hyprland con las layer rules de quickshell.
Item {
    id: root

    default property alias content: contentArea.data
    property real radius: 24
    property color fill: Theme.glassFill
    property real rim: 1

    ShaderEffect {
        anchors.fill: parent

        property size itemSize: Qt.size(width, height)
        property real radius: root.radius
        property color fill: root.fill
        property real rim: root.rim

        fragmentShader: Qt.resolvedUrl("shaders/glassframe.frag.qsb")
    }

    Item {
        id: contentArea
        anchors.fill: parent
    }
}
