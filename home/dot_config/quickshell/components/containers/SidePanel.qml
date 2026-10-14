import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services

// Panel que entra deslizándose desde un lado (edge: "right" o "left") del monitor
// enfocado y ocupa todo el alto libre (deja sitio a la barra). Clic fuera o Esc =
// closeRequested().
//   SidePanel { open: Servicio.open; onCloseRequested: Servicio.close(); Label { … } }
PanelWindow {
    id: panel

    required property bool open
    signal closeRequested()
    default property alias content: column.data
    property alias spacing: column.spacing
    // Nombre de la capa (para las reglas de Hyprland)
    property string namespace: "quickshell"
    property string edge: "right"
    readonly property bool fromLeft: edge === "left"

    // Se mantiene mapeado mientras dura la animación de salida
    visible: open || slide.running
    screen: Hypr.focusedScreen
    anchors {
        top: true
        bottom: true
        right: !fromLeft
        left: fromLeft
    }
    // Deja libre el borde donde esté la barra
    margins {
        top: Config.reserve("top") + 8
        bottom: Config.reserve("bottom") + 8
        right: Config.reserve("right") + 8
        left: Config.reserve("left") + 8
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
        x: panel.open ? 0 : (panel.fromLeft ? -1 : 1) * (panel.implicitWidth + 16)
        Behavior on x {
            NumberAnimation {
                id: slide
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        color: Theme.glass(Theme.panelBg)
        border.color: Theme.surfaceHigh
        border.width: 1

        // Si el contenido no cabe (monitores bajos), se desplaza con la rueda
        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 12
            contentHeight: column.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: column
                width: flick.width
                // Al menos el alto visible: lo que se estira (p. ej. un espaciador) llega al pie
                height: Math.max(flick.height, implicitHeight)
                spacing: 10
            }
        }
    }
}
