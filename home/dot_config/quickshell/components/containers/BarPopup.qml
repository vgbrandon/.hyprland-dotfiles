import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.components.design
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
    // No se cierra al hacer clic fuera (p. ej. para ir a copiar algo a otra ventana);
    // al volver, un clic en el panel le devuelve el foco del teclado
    property bool keepOpen: false

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
        fitWindow();
        place();
        visible = true;
    }

    // Centro del elemento al abrir. Se fija aquí y no se sigue después: si el
    // elemento cambia de tamaño con el panel abierto (p. ej. el pomodoro pasa del
    // icono al tiempo), el panel no se mueve.
    property point anchorCenter
    function place() {
        // Elemento oculto (quitado de la barra en Ajustes): junto al final de la barra
        if (!anchorItem.visible) {
            const win = anchorItem.QsWindow.window;
            anchorCenter = Config.barVertical ? Qt.point(win.width / 2, win.height - 1) : Qt.point(win.width - 1, win.height / 2);
            return;
        }
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

    // Para el IPC: solo lo abre la barra del monitor principal
    function toggleOnMainScreen() {
        const win = anchorItem.QsWindow.window;
        if (win?.visible && win.screen === Hypr.mainScreen) toggle();
    }

    visible: false
    // Anclado a la ventana de la barra (no al elemento), junto a la barra esté donde esté
    anchor.window: anchorItem.QsWindow.window
    anchor.rect.x: popupPos.x
    anchor.rect.y: popupPos.y
    readonly property point popupPos: Config.popupPos(anchorItem.QsWindow.window, anchorCenter, implicitWidth, implicitHeight)
    // --- Alto: si el contenido cambia de tamaño con el panel abierto, el panel crece o
    // se encoge con animación. La ventana no cambia de tamaño mientras se anima (en
    // Wayland, redimensionar un popup lo recoloca y parpadea): al abrir toma el alto
    // máximo (maxHeight, si lo hay) y solo crece si el contenido no cabe; el vidrio se
    // anima dentro y lo de fuera de él deja pasar los clics (mask).
    readonly property real contentHeight: {
        const h = column.implicitHeight + padding * 2;
        return maxHeight > 0 ? Math.min(maxHeight, h) : h;
    }
    property real shownHeight: contentHeight
    Behavior on shownHeight {
        enabled: popup.visible && popup.reveal >= 1 && !popup.closing
        NumberAnimation {
            duration: Design.normal
            easing.type: Design.easing
        }
    }
    property real windowHeight: contentHeight
    onContentHeightChanged: if (!visible || contentHeight > windowHeight) windowHeight = contentHeight
    function fitWindow() {
        windowHeight = Math.max(contentHeight, maxHeight);
    }
    implicitWidth: Design.popupWidth
    implicitHeight: windowHeight
    color: "transparent"
    mask: Region {
        item: frame
    }

    // Clic fuera del panel = cerrar. El grab se activa cuando la ventana ya está mapeada.
    HyprlandFocusGrab {
        id: grab
        windows: [popup]
        onCleared: if (!popup.keepOpen) popup.close()
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

        // El panel con su alto animado: pegado al lado de la barra (abajo si la barra
        // está abajo) y recortando el contenido mientras cambia
        ClippingRectangle {
            id: frame
            width: parent.width
            height: popup.shownHeight
            y: Config.barPosition === "bottom" ? parent.height - height : 0
            radius: Design.radiusMd
            color: "transparent"

            // Vidrio (docs/velure.md): tinte translúcido, borde de 1 px y brillo en el canto
            Rectangle {
                id: background
                anchors.fill: parent
                radius: Design.radiusMd
                color: Design.alpha(Design.glassTint, Design.glassOpacity)
                border.color: Design.border
                border.width: 1

                GlassEdge {
                    inset: background.radius
                }
            }

            // El contenido con su alto final (lo que aún no cabe queda recortado)
            ColumnLayout {
                id: column
                x: popup.padding
                y: popup.padding
                width: frame.width - popup.padding * 2
                height: popup.contentHeight - popup.padding * 2
                spacing: 10
            }
        }

        // Con keepOpen, un clic en el panel recupera el foco (el clic sigue a lo de debajo)
        MouseArea {
            anchors.fill: parent
            enabled: popup.keepOpen
            onPressed: mouse => {
                if (!grab.active) grab.active = true;
                mouse.accepted = false;
            }
        }
    }
}
