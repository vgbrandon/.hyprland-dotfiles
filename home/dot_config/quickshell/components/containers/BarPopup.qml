import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.services

// Panel que se abre junto a la barra, pegado al elemento que lo abre (anchorItem),
// esté la barra donde esté. Clic fuera = cerrar. El contenido va en una columna con
// margen "padding"; el alto se ajusta a él (hasta maxHeight, si se indica).
// Al abrir sale desde la barra (desde arriba si está arriba, etc.) con un fundido;
// al cerrar vuelve hacia ella y después se oculta la ventana.
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

    // Abre/cierra desde la barra. Si el mismo clic acaba de cerrarlo (o se está
    // cerrando), no lo reabre.
    function toggle() {
        if (closing) return;
        if (!visible && Date.now() - closedAt < 300) return;
        if (visible) close();
        else open();
    }
    function open() {
        hideAnim.stop();
        closing = false;
        place();
        visible = true;
    }

    // Centro del elemento al abrir. Se fija aquí y no se sigue después: si el
    // elemento cambia de tamaño con el panel abierto (p. ej. el pomodoro pasa del
    // icono al tiempo), el panel no se mueve.
    property point anchorCenter
    function place() {
        anchorCenter = anchorItem.mapToItem(null, anchorItem.width / 2, anchorItem.height / 2);
    }

    function close() {
        if (!visible || closing) return;
        closing = true;
        closedAt = Date.now();
        grab.active = false;
        hideAnim.start();
    }

    // --- Animación: 0 = escondido junto a la barra, 1 = en su sitio ---
    property real reveal: 0
    property bool closing: false
    // Hacia dónde se esconde: hacia la barra
    readonly property point toBar: ({
        top: Qt.point(0, -1), bottom: Qt.point(0, 1), left: Qt.point(-1, 0), right: Qt.point(1, 0)
    })[Config.barPosition] ?? Qt.point(0, -1)

    NumberAnimation {
        id: showAnim
        target: popup
        property: "reveal"
        from: 0
        to: 1
        duration: 200
        easing.type: Easing.OutCubic
    }
    SequentialAnimation {
        id: hideAnim
        NumberAnimation {
            target: popup
            property: "reveal"
            to: 0
            duration: 130
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: {
                popup.visible = false;
                popup.closing = false;
            }
        }
    }

    // Para el IPC: solo lo abre la barra del monitor enfocado
    function toggleOnFocusedScreen() {
        if (Hypr.isFocused(anchorItem.QsWindow.window?.screen)) toggle();
    }

    visible: false
    // Anclado a la ventana de la barra (no al elemento), junto a la barra esté donde esté
    anchor.window: anchorItem.QsWindow.window
    anchor.rect.x: popupPos.x
    anchor.rect.y: popupPos.y
    readonly property point popupPos: Config.popupPos(anchorItem.QsWindow.window, anchorCenter, implicitWidth, implicitHeight)
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
        if (visible) {
            reveal = 0;
            showAnim.restart();
            grabTimer.restart();
        }
    }
    Timer {
        id: grabTimer
        interval: 50
        onTriggered: grab.active = popup.visible && !popup.closing
    }

    // Todo el contenido se mueve y se funde junto (lo que sale de la ventana no se ve)
    Item {
        anchors.fill: parent
        opacity: popup.reveal
        transform: Translate {
            x: (1 - popup.reveal) * popup.toBar.x * 24
            y: (1 - popup.reveal) * popup.toBar.y * 24
        }

        Rectangle {
            id: background
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.glass(Theme.panelBg)
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
}
