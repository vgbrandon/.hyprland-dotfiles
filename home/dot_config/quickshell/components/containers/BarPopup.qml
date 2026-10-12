import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.services

// Panel que se abre junto a la barra, pegado al elemento que lo abre (anchorItem),
// esté la barra donde esté. Clic fuera = cerrar. El contenido va en una columna con
// margen "padding"; el alto se ajusta a él (hasta maxHeight, si se indica).
//   BarPopup { id: panel; anchorItem: boton; implicitWidth: 360; Label { … } }
//   boton: onClicked: panel.toggle()
PopupWindow {
    id: popup

    required property Item anchorItem
    default property alias content: column.data
    property alias spacing: column.spacing
    property int padding: 12
    // Alto máximo (0 = sin límite). El contenido con Layout.fillHeight se encoge.
    property int maxHeight: 0
    // Fondo y borde del panel (MediaPanel pone el suyo)
    property alias background: background
    property real closedAt: 0

    // Abre/cierra desde la barra. Si el mismo clic acaba de cerrarlo, no lo reabre.
    function toggle() {
        if (!visible && Date.now() - closedAt < 300) return;
        visible = !visible;
    }

    function close() {
        if (!visible) return;
        visible = false;
        closedAt = Date.now();
    }

    // Para el IPC: solo lo abre la barra del monitor enfocado
    function toggleOnFocusedScreen() {
        if (Hypr.isFocused(anchorItem.QsWindow.window?.screen)) toggle();
    }

    visible: false
    anchor.item: anchorItem
    anchor.rect.x: popupPos.x
    anchor.rect.y: popupPos.y
    // Junto a la barra, esté donde esté
    readonly property point popupPos: Config.popupPos(anchorItem, implicitWidth, implicitHeight, visible)
    implicitHeight: {
        const h = column.implicitHeight + padding * 2;
        return maxHeight > 0 ? Math.min(maxHeight, h) : h;
    }
    color: "transparent"

    // Clic fuera del panel = cerrar. El grab se activa cuando la ventana ya está mapeada.
    HyprlandFocusGrab {
        id: grab
        windows: [popup]
        onCleared: popup.close()
    }
    onVisibleChanged: {
        grab.active = false;
        if (visible) grabTimer.restart();
    }
    Timer {
        id: grabTimer
        interval: 50
        onTriggered: grab.active = popup.visible
    }

    Rectangle {
        id: background
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panelBg
        border.color: Theme.surfaceHigh
        border.width: 1
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: popup.padding
        spacing: 10
    }
}
