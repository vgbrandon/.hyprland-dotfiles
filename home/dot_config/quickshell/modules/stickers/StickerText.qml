import QtQuick
import qs.services

// Un texto del sticker: letra con borde grueso (copias desplazadas alrededor, en dos
// anillos; el contorno de Text es de 1 px), centrado en (cx, cy) del lienzo y girado.
// Se arrastra con el ratón; al pulsarlo se elige (selected) para editarlo.
Item {
    id: t

    // Datos (del ListModel de la ventana)
    property string text
    property string family
    property int size: 64
    property int weight: Font.Black
    property color fill: "#ffffff"
    property color stroke: "#000000"
    property int strokeWidth: 6
    property real angle: 0
    property real cx: 256
    property real cy: 256

    property bool selected: false
    // Mientras se guarda la capa de textos no se dibuja el marco de selección
    property bool clean: false

    signal pressed()
    signal moved(real cx, real cy)

    width: label.implicitWidth + strokeWidth * 2 + 8
    height: label.implicitHeight + strokeWidth * 2 + 4
    x: cx - width / 2
    y: cy - height / 2
    rotation: angle

    // El borde: un anillo exterior y otro a media distancia (sin huecos en bordes gruesos)
    Repeater {
        model: t.strokeWidth > 0 ? 24 : 0
        Text {
            required property int index
            readonly property real r: index < 16 ? t.strokeWidth : t.strokeWidth / 2
            readonly property real a: (index < 16 ? index / 16 : (index - 16) / 8) * 2 * Math.PI
            x: label.x + Math.cos(a) * r
            y: label.y + Math.sin(a) * r
            text: t.text
            color: t.stroke
            font: label.font
            horizontalAlignment: Text.AlignHCenter
            renderType: Text.QtRendering
        }
    }
    Text {
        id: label
        anchors.centerIn: parent
        text: t.text
        color: t.fill
        font.family: t.family
        font.pixelSize: t.size
        font.weight: t.weight
        horizontalAlignment: Text.AlignHCenter
        renderType: Text.QtRendering
    }

    // Marco de selección (no sale en el sticker)
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        visible: t.selected && !t.clean
        color: "transparent"
        radius: 4
        border.width: 1
        border.color: Design.accent
    }

    // Arrastrar: se mueve el centro en las coordenadas del lienzo (el padre)
    MouseArea {
        anchors.fill: parent
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        property point from
        property real startX
        property real startY
        onPressed: e => {
            t.pressed();
            from = mapToItem(t.parent, e.x, e.y);
            startX = t.cx;
            startY = t.cy;
        }
        onPositionChanged: e => {
            if (!pressed) return;
            const p = mapToItem(t.parent, e.x, e.y);
            t.moved(startX + p.x - from.x, startY + p.y - from.y);
        }
    }
}
