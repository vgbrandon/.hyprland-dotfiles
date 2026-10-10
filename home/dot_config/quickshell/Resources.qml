import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// CPU y RAM (datos en SystemStats). Clic = panel del sistema
Pill {
    id: root

    // Sin sitio en la barra vertical de un monitor bajo
    visible: !compact

    Icon { text: Theme.iCpu; color: Theme.subtext }
    Label { text: SystemStats.cpu }
    Icon { text: Theme.iRam; color: Theme.subtext }
    Label { text: SystemStats.ram }

    // Clic = panel del sistema
    MouseArea {
        parent: root
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.toggle()
    }

    // IPC: abre el panel en el monitor enfocado
    Connections {
        target: SystemStats
        function onPanelRequested() {
            if (Hyprland.monitorFor(root.QsWindow.window?.screen) === Hyprland.focusedMonitor) panel.toggle();
        }
    }

    SystemPanel {
        id: panel
        anchorItem: root
        visible: false
    }
}
