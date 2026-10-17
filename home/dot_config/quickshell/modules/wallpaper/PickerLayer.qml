import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components.design
import qs.services

// Capa a pantalla completa de los selectores de fondos, en el monitor principal:
// oscurece el escritorio y pone el contenido encima (aparece con un fundido). Clic en
// el fondo o Esc (si el contenido no la usa) = cerrar.
PanelWindow {
    id: win

    required property bool open
    default property alias content: stage.data
    // Opacidad del oscurecido
    property real dim: 0.6

    visible: open || fade.running
    screen: Hypr.mainScreen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    // El oscurecido es el color de la propia ventana (con un fundido)
    property real shade: open ? dim : 0
    Behavior on shade { NumberAnimation { duration: Design.normal; easing.type: Design.easing } }
    color: Design.alpha(Design.background, shade)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:wallpaper"

    function close() {
        Wallpaper.open = false;
    }

    Item {
        anchors.fill: parent
        opacity: win.open ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                id: fade
                duration: Design.normal
                easing.type: Design.easing
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: win.close()
        }

        FocusScope {
            id: stage
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: win.close()
        }
    }
}
