import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Clase de la app (pequeño) + título de la ventana activa en este monitor
ColumnLayout {
    id: root

    required property ShellScreen screen
    readonly property HyprlandWorkspace ws: Hyprland.monitorFor(screen)?.activeWorkspace ?? null
    readonly property Toplevel active: ToplevelManager.activeToplevel
    // Ventana enfocada si está en este monitor; si no, la primera del workspace visible
    readonly property Toplevel win: {
        if (!ws || ws.toplevels.values.length === 0) return null;
        if (active && active.screens.includes(screen)) return active;
        return ws.toplevels.values[0].wayland ?? null;
    }

    spacing: -2

    Label {
        Layout.maximumWidth: 260
        text: root.win ? root.win.appId : "Escritorio"
        color: Theme.subtext
        font.pixelSize: Theme.fontSize - 1
    }
    Label {
        Layout.maximumWidth: 260
        text: root.win ? root.win.title : `Workspace ${root.ws?.id ?? 1}`
    }
}
