import QtQuick
import qs.components.base

// Icono que se puede pulsar, sin fondo: cursor de mano y clicked(botón).
// "hovered" sirve para cambiar el color al pasar el ratón.
//   IconButton { text: Theme.iClose; color: hovered ? Theme.text : Theme.subtext; onClicked: … }
Icon {
    id: root

    signal clicked(int button)
    property alias acceptedButtons: mouse.acceptedButtons
    readonly property bool hovered: mouse.containsMouse
    // Agranda la zona de clic alrededor del icono
    property int hitMargin: 0

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -root.hitMargin
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: e => root.clicked(e.button)
    }
}
