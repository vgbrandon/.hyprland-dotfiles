import QtQuick

// Engranaje de la barra: abre/cierra el panel de ajustes rápidos.
Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Icon {
        id: icon
        text: Theme.iSettings

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Config.toggle()
        }
    }
}
