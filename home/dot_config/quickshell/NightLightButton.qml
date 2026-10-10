import QtQuick

// Icono de luz nocturna: clic = activar/desactivar. La intensidad se ajusta en el
// panel de ajustes (Luz nocturna).
Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Icon {
        id: icon
        text: NightLight.enabled ? Theme.iNight : Theme.iSun
        color: !NightLight.available ? Theme.dot : NightLight.enabled ? Theme.warm : Theme.text
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: NightLight.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: NightLight.toggle()
    }
}
