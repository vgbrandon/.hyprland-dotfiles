import QtQuick

// Panel de vidrio "liquid glass" (shader en shaders/glass.frag).
// Necesita una textura del fondo ya desenfocada que cubra toda la pantalla.
Item {
    id: root

    default property alias content: contentArea.data
    required property Item glassSource
    property real radius: height / 2
    property real bezel: 18
    property real refraction: 16
    property color tint: Theme.withAlpha(Theme.surface, 0.22)
    // Desplazamiento extra (p. ej. la animación de temblor del campo de contraseña)
    property real shiftX: 0
    // Posición en la pantalla; se recalcula cuando cambia el tamaño o la ventana
    property point screenPos: Qt.point(0, 0)

    function updatePos() {
        screenPos = mapToItem(null, 0, 0);
    }

    Component.onCompleted: Qt.callLater(updatePos)
    onWidthChanged: Qt.callLater(updatePos)
    onHeightChanged: Qt.callLater(updatePos)

    Connections {
        target: root.Window.window
        function onWidthChanged() { Qt.callLater(root.updatePos); }
        function onHeightChanged() { Qt.callLater(root.updatePos); }
    }

    ShaderEffect {
        anchors.fill: parent

        property var source: root.glassSource
        property size itemSize: Qt.size(width, height)
        property point itemPos: Qt.point(root.screenPos.x + root.shiftX, root.screenPos.y)
        property size screenSize: Qt.size(root.glassSource.width, root.glassSource.height)
        property real radius: root.radius
        property real bezel: root.bezel
        property real refraction: root.refraction
        property color tint: root.tint

        fragmentShader: Qt.resolvedUrl("shaders/glass.frag.qsb")
    }

    Item {
        id: contentArea
        anchors.fill: parent
    }
}
