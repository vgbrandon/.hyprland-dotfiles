import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Selector de color en un monitor: pantalla congelada, lupa y muestra del color
PanelWindow {
    id: win

    required property ShellScreen modelData
    readonly property bool focusedScreen: Hyprland.monitorFor(modelData) === Hyprland.focusedMonitor
    // Posición de este monitor dentro de la imagen congelada
    readonly property int offX: modelData.x - Screenshot.originX
    readonly property int offY: modelData.y - Screenshot.originY
    readonly property string frozenUrl: ColorPicker.active && ColorPicker.frozen !== "" ? "file://" + ColorPicker.frozen : ""
    // Píxel bajo el cursor (coordenadas locales)
    property int mx: -1
    property int my: -1
    readonly property bool hovering: mx >= 0
    readonly property int zoom: 12
    readonly property int cells: 11 // píxeles visibles en la lupa (impar: uno en el centro)

    screen: modelData
    visible: ColorPicker.active
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: focusedScreen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:colorpicker"

    onVisibleChanged: {
        mx = -1;
        my = -1;
        if (visible && focusedScreen) keys.forceActiveFocus();
    }

    // Lee el color del píxel bajo el cursor (queda tapado por la imagen de fondo)
    Canvas {
        id: sampler

        width: 1
        height: 1
        onAvailableChanged: if (available && win.frozenUrl !== "") loadImage(win.frozenUrl)
        onImageLoaded: requestPaint()
        onPaint: {
            if (!win.hovering || !isImageLoaded(win.frozenUrl)) return;
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, 1, 1);
            ctx.drawImage(win.frozenUrl, win.mx + win.offX, win.my + win.offY, 1, 1, 0, 0, 1, 1);
            const d = ctx.getImageData(0, 0, 1, 1).data;
            ColorPicker.current = Qt.rgba(d[0] / 255, d[1] / 255, d[2] / 255, 1);
        }

        Connections {
            target: win
            function onFrozenUrlChanged() {
                if (win.frozenUrl !== "") sampler.loadImage(win.frozenUrl);
            }
        }
    }

    // Pantalla congelada
    Image {
        x: -win.offX
        y: -win.offY
        source: win.frozenUrl
        cache: true // la lupa reutiliza esta misma imagen decodificada
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.CrossCursor

        onPositionChanged: e => {
            win.mx = Math.floor(e.x);
            win.my = Math.floor(e.y);
            sampler.requestPaint();
        }
        onExited: win.mx = -1
        onClicked: e => {
            const c = ColorPicker.current;
            const text = e.button === Qt.RightButton ? ColorPicker.rgb(c) : ColorPicker.hex(c);
            swatch.color = c;
            swatch.grabToImage(result => {
                // Un archivo por color: con el mismo nombre la notificación mostraría
                // la imagen anterior (queda en caché). Son PNG diminutos en /tmp (RAM).
                const file = `/tmp/qs-colorpicker-swatch-${Date.now()}.png`;
                result.saveToFile(file);
                ColorPicker.accept(text, file);
            });
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: ColorPicker.cancel()
    }

    // Muestra del color para la notificación (tapada por la imagen de fondo).
    // Cuadrada y llena: la notificación la recorta con su propio radio.
    Rectangle {
        id: swatch
        z: -1
        width: 64
        height: 64
        // Sin redondeo: la notificación ya recorta la imagen con su propio radio
    }

    // Lupa que sigue al cursor (se pasa al otro lado cerca del borde)
    Rectangle {
        id: loupe

        readonly property int size: win.cells * win.zoom

        visible: win.hovering
        x: win.mx + 24 + width > win.width ? win.mx - 24 - width : win.mx + 24
        y: win.my + 24 + height > win.height ? win.my - 24 - height : win.my + 24
        width: size + 16
        height: size + info.implicitHeight + 28
        radius: Theme.radius
        color: Theme.panelBg
        border.color: Theme.surfaceHigh
        border.width: 1

        // Píxeles ampliados sin suavizado
        Item {
            id: lens
            x: 8
            y: 8
            width: loupe.size
            height: loupe.size
            clip: true

            Image {
                source: win.frozenUrl
                cache: true
                smooth: false
                width: sourceSize.width * win.zoom
                height: sourceSize.height * win.zoom
                x: -(win.mx + win.offX - Math.floor(win.cells / 2)) * win.zoom
                y: -(win.my + win.offY - Math.floor(win.cells / 2)) * win.zoom
            }

            // Recuadro del píxel elegido
            Rectangle {
                x: Math.floor(win.cells / 2) * win.zoom
                y: Math.floor(win.cells / 2) * win.zoom
                width: win.zoom
                height: win.zoom
                color: "transparent"
                border.color: "white"
                border.width: 2

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    color: "transparent"
                    border.color: "black"
                    border.width: 1
                }
            }
        }

        RowLayout {
            id: info
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            spacing: 8

            Rectangle {
                implicitWidth: 20
                implicitHeight: 20
                radius: 6
                color: ColorPicker.current
                border.color: Theme.surfaceHigh
                border.width: 1
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    text: ColorPicker.hex(ColorPicker.current)
                    font.family: Theme.iconFont
                }
                Label {
                    text: ColorPicker.rgb(ColorPicker.current)
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 1
                }
            }
        }
    }

    // Ayuda (solo en el monitor enfocado)
    Rectangle {
        visible: win.focusedScreen
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24
        width: help.implicitWidth + 32
        height: 40
        radius: height / 2
        color: Theme.panelBg
        border.color: Theme.surfaceHigh
        border.width: 1

        Label {
            id: help
            anchors.centerIn: parent
            text: "Clic: copiar HEX  •  Clic derecho: copiar RGB  •  Esc: cancelar"
            color: Theme.subtext
        }
    }
}
