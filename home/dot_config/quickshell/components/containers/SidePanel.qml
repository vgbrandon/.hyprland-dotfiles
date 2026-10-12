import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services

// Panel que entra deslizándose desde la derecha del monitor enfocado y ocupa todo el
// alto libre (deja sitio a la barra). Clic fuera o Esc = closeRequested().
//   SidePanel { open: Servicio.open; onCloseRequested: Servicio.close(); Label { … } }
PanelWindow {
    id: panel

    required property bool open
    signal closeRequested()
    default property alias content: column.data
    property alias spacing: column.spacing
    // Nombre de la capa (para las reglas de Hyprland)
    property string namespace: "quickshell"

    // Se mantiene mapeado mientras dura la animación de salida
    visible: open || slide.running
    screen: Hypr.focusedScreen
    anchors {
        top: true
        bottom: true
        right: true
    }
    // Deja libre el borde donde esté la barra
    margins {
        top: Config.reserve("top") + 8
        bottom: Config.reserve("bottom") + 8
        right: Config.reserve("right") + 8
    }
    implicitWidth: 400
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: panel.namespace

    // Clic fuera = cerrar
    HyprlandFocusGrab {
        id: grab
        windows: [panel]
        onCleared: panel.closeRequested()
    }
    onOpenChanged: {
        grab.active = false;
        if (open) grabTimer.restart();
    }
    Timer {
        id: grabTimer
        interval: 50
        onTriggered: {
            grab.active = panel.open;
            keys.forceActiveFocus();
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: panel.closeRequested()
    }

    Rectangle {
        width: parent.width
        height: parent.height
        radius: Theme.radius
        x: panel.open ? 0 : panel.implicitWidth + 16
        Behavior on x {
            NumberAnimation {
                id: slide
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        color: Theme.panelBg
        border.color: Theme.surfaceHigh
        border.width: 1

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10
        }
    }
}
