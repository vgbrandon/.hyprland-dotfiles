import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components.design
import qs.services

// Ventana a pantalla completa en el monitor principal, por encima de todo: fondo
// oscurecido y una tarjeta con el contenido (en columna). Clic fuera de la tarjeta
// o Esc (si nada dentro lo usa) = closeRequested().
//   OverlayWindow { open: Servicio.open; onCloseRequested: Servicio.open = false; cardWidth: 600; … }
PanelWindow {
    id: win

    required property bool open
    signal closeRequested()
    default property alias content: column.data
    property alias spacing: column.spacing
    // Nombre de la capa (para las reglas de Hyprland)
    property string namespace: "quickshell"
    // Opacidad del oscurecido del fondo
    property real dim: 0.35
    property int focusMode: WlrKeyboardFocus.Exclusive
    // Tarjeta: ancho (0 = el del contenido), margen y color
    property int cardWidth: 0
    property int padding: 16
    property color cardColor: Design.glassTint
    // Alto con el que se centra la tarjeta (0 = el suyo). Con listas que se filtran,
    // centrarla según su alto máximo evita que el buscador se mueva al escribir.
    property int centerHeight: 0

    visible: open
    screen: Hypr.mainScreen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Qt.rgba(0, 0, 0, dim)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? focusMode : WlrKeyboardFocus.None
    WlrLayershell.namespace: win.namespace

    // Recibe las teclas que no usa el contenido (Esc = cerrar)
    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.closeRequested()

        // Clic fuera de la tarjeta = cerrar
        MouseArea {
            anchors.fill: parent
            onClicked: win.closeRequested()
        }

        Rectangle {
            id: card

            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(0, Math.round((parent.height - (win.centerHeight > 0 ? win.centerHeight : height)) / 2))
            width: win.cardWidth > 0 ? win.cardWidth : column.implicitWidth + win.padding * 2
            height: column.implicitHeight + win.padding * 2
            // Vidrio casi opaco: estas capas no las desenfoca Hyprland (docs/prisma.md)
            radius: Design.radiusMd
            color: Design.alpha(win.cardColor, Design.glassOpacity < 1 ? 0.94 : 1)
            border.color: Design.border
            border.width: 1

            GlassEdge {
                inset: Design.radiusMd
            }

            opacity: win.open ? 1 : 0
            scale: win.open ? 1 : 0.96
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            // Evita que el clic llegue al fondo
            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: column
                anchors.fill: parent
                anchors.margins: win.padding
                spacing: 12
            }
        }
    }
}
