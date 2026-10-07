import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.barBg

    // Izquierda: logo + ventana activa
    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Rectangle {
            implicitWidth: Theme.pillHeight
            implicitHeight: Theme.pillHeight
            radius: width / 2
            color: Theme.surface
            Icon {
                anchors.centerIn: parent
                text: Theme.iLogo
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Launcher.toggle()
            }
        }
        ActiveWindow { screen: bar.screen }
    }

    // Centro: recursos/media, workspaces, reloj
    RowLayout {
        anchors.centerIn: parent
        spacing: Theme.gap

        Resources {}
        Workspaces { screen: bar.screen }
        ClockPill {}
    }

    // Derecha: actualizaciones, red, bluetooth, notificaciones y energía
    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        UpdatesPill {}
        StatusIcons {}
    }
}
