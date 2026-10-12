import QtQuick
import qs.components.base
import qs.services

// Botón redondo con un icono. Sin fondo hasta pasar el ratón (filled = siempre con
// fondo); accent = relleno de color (accentColor). Desactivado, el icono se apaga.
//   CircleButton { icon: Theme.iRefresh; onClicked: … }
Rectangle {
    id: root

    property string icon
    property int size: 30
    property int iconSize: 16
    property bool filled: false
    property bool accent: false
    property color accentColor: Theme.primary
    property color hoverColor: Theme.surfaceHigh
    property color iconColor: accent ? Theme.primaryFg : Theme.text
    property alias acceptedButtons: mouse.acceptedButtons
    readonly property bool hovered: mouse.containsMouse
    // El icono, por si hay que animarlo (p. ej. que gire mientras busca)
    property alias iconItem: label
    signal clicked(int button)

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: accent ? (hovered ? Qt.lighter(accentColor, 1.1) : accentColor)
        : hovered ? hoverColor : filled ? Theme.surface : "transparent"

    Icon {
        id: label
        anchors.centerIn: parent
        text: root.icon
        color: root.enabled ? root.iconColor : Theme.dot
        font.pixelSize: root.iconSize
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: e => root.clicked(e.button)
    }
}
