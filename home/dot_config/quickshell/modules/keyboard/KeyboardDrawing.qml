import QtQuick
import Quickshell
import qs.services
import "KeyboardLayout.js" as Layout

// El AULA F75 Max dibujado en Velure, con las posiciones del layout oficial: carcasa,
// teclas, la pantalla (con la imagen que tiene o la hora) y la rueda. Previsualiza la
// iluminación (color, brillo y una aproximación animada de cada efecto). Con
// interactive, las teclas se pueden pulsar (keyClicked) y highlight resalta códigos.
//   KeyboardDrawing { Layout.fillWidth: true; Layout.preferredHeight: width * ratio }
Item {
    id: root

    property var light: AulaKeyboard.light
    property bool animate: true
    property bool interactive: false
    property var highlight: []
    property string screenFile: AulaKeyboard.screen.file ?? ""
    property string screenFit: AulaKeyboard.screen.fit ?? "fill"
    signal keyClicked(var key)

    // Márgenes de la carcasa (en unidades del layout)
    readonly property real pad: 16
    readonly property real u: width / (Layout.width + pad * 2)
    // Alto / ancho (en un layout: Layout.preferredHeight: width * ratio)
    readonly property real ratio: (Layout.height + pad * 2) / (Layout.width + pad * 2)
    implicitWidth: 360
    implicitHeight: Math.round(360 * ratio)

    // --- Iluminación ---
    readonly property string mode: light.mode ?? "off"
    readonly property bool lit: mode !== "off"
    readonly property color ledColor: light.color ?? "#ffffff"
    readonly property bool multicolor: light.multicolor ?? false
    readonly property real level: 0.3 + 0.7 * ((light.brightness ?? 3) - 1) / 4
    readonly property real speed: 0.4 + (light.speed ?? 3) * 0.3
    readonly property int dir: ["right", "down", "left", "up"].indexOf(light.direction ?? "right")

    property real t: 0
    FrameAnimation {
        running: root.visible && root.animate && root.lit
        onTriggered: root.t += frameTime * root.speed
    }

    // Pseudoaleatorio estable por tecla (destellos, lluvia)
    function hash(n) {
        const s = Math.sin(n * 12.9898) * 43758.5453;
        return s - Math.floor(s);
    }
    // Posición 0..1 de la tecla en la dirección del efecto
    function along(k) {
        const x = (k[4] + k[6] / 2) / Layout.width, y = (k[5] + k[7] / 2) / Layout.height;
        return [x, y, 1 - x, 1 - y][Math.max(0, dir)];
    }
    // Brillo 0..1 de cada tecla según el efecto (aproximación de lo que hace el firmware)
    function intensity(k) {
        const t = root.t, p = along(k), h = hash(k[3]);
        switch (mode) {
        case "off": return 0;
        case "breathing": return 0.25 + 0.75 * (0.5 + 0.5 * Math.sin(t * 2));
        case "reactive": case "reactive-fade": case "explode": case "launch": case "ripple":
            return 0.25 + 0.75 * Math.max(0, Math.sin(t * 1.5 - p * 6 + h * 2));
        case "glitter": case "rain":
            return 0.2 + 0.8 * Math.pow(0.5 + 0.5 * Math.sin(t * 3 + h * 40), 6);
        case "pulse": return 0.3 + 0.7 * Math.abs(Math.sin(t * 1.5));
        case "wave": case "rolling": case "flowing": case "tilt": case "outward":
        case "rotating": case "shuttle":
            return 0.3 + 0.7 * (0.5 + 0.5 * Math.sin(p * 8 - t * 3));
        default: return 1;
        }
    }
    // Color de cada tecla: el elegido o, con multicolor y en los efectos de colores,
    // un arcoíris que se mueve
    function keyColor(k) {
        const rainbow = multicolor || mode === "colourful" || mode === "spectrum";
        if (!rainbow) return ledColor;
        const hue = mode === "spectrum" ? (root.t * 0.1) % 1 : (along(k) * 0.8 + root.t * 0.08) % 1;
        return Qt.hsla(hue, 0.9, 0.6, 1);
    }

    // --- Carcasa ---
    Rectangle {
        anchors.fill: parent
        radius: 14 * root.u
        color: Design.surface2
        border.color: Design.border
        border.width: 1
        // Brillo de los LED bajo las teclas
        Rectangle {
            anchors.fill: parent
            anchors.margins: root.pad * root.u * 0.6
            radius: 10 * root.u
            color: root.lit ? Design.alpha(root.multicolor ? Design.accent : root.ledColor, 0.08 * root.level) : "transparent"
        }
    }

    // --- Teclas ---
    Repeater {
        model: Layout.keys

        Rectangle {
            id: key
            required property var modelData
            readonly property var k: modelData
            readonly property bool picked: root.highlight.includes(k[3])
            readonly property real glow: root.lit ? root.intensity(k) * root.level : 0
            readonly property color led: root.keyColor(k)

            x: (root.pad + k[4]) * root.u
            y: (root.pad + k[5]) * root.u
            width: k[6] * root.u
            height: k[7] * root.u
            radius: 4 * root.u
            color: picked ? Design.selection : Design.mix(Design.surface3, Qt.color(led), glow * 0.28)
            border.width: 1
            border.color: picked ? Design.accent : glow > 0.05 ? Design.alpha(led, 0.25 + glow * 0.6) : Design.border

            // Etiquetas: una centrada o el símbolo arriba y el de abajo
            Text {
                anchors.centerIn: parent
                visible: key.k[0] !== ""
                text: key.k[0]
                color: key.picked ? Design.accent : Design.onSurface
                font.family: Design.font
                font.pixelSize: Math.max(6, (key.k[0].length > 4 ? 6.5 : 8.5) * root.u)
                font.weight: Font.Medium
            }
            Column {
                anchors.centerIn: parent
                visible: key.k[0] === "" && key.k[1] !== ""
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: key.k[1]
                    color: Design.onSurfaceVariant
                    font.family: Design.font
                    font.pixelSize: Math.max(5, 7 * root.u)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: key.k[2]
                    color: Design.onSurface
                    font.family: Design.font
                    font.pixelSize: Math.max(6, 8.5 * root.u)
                    font.weight: Font.Medium
                }
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.interactive
                hoverEnabled: root.interactive
                cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.keyClicked(key.k)
            }
        }
    }

    // --- Pantalla ---
    Rectangle {
        x: (root.pad + Layout.screen[0]) * root.u
        y: (root.pad + Layout.screen[1]) * root.u
        width: Layout.screen[2] * root.u
        height: Layout.screen[3] * root.u
        radius: 3 * root.u
        color: "#000000"
        border.color: Design.border
        clip: true

        AnimatedImage {
            anchors.centerIn: parent
            // La pantalla es cuadrada: el recuadro, más ancho, la muestra centrada
            width: parent.height
            height: parent.height
            visible: root.screenFile !== ""
            source: root.screenFile !== "" ? "file://" + root.screenFile : ""
            fillMode: ({ fit: Image.PreserveAspectFit, fill: Image.PreserveAspectCrop, stretch: Image.Stretch })[root.screenFit] ?? Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 128
            sourceSize.height: 128
        }
        Text {
            anchors.centerIn: parent
            visible: root.screenFile === ""
            text: Qt.formatTime(clock.date, "hh:mm")
            color: Design.accent
            font.family: Design.monoFont
            font.pixelSize: 8 * root.u
        }
        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }
    }

    // --- Rueda ---
    Rectangle {
        x: (root.pad + Layout.knob[0]) * root.u
        y: (root.pad + Layout.knob[1] + (Layout.knob[3] - Layout.knob[2]) / 2) * root.u
        width: Layout.knob[2] * root.u
        height: width
        radius: width / 2
        gradient: Gradient {
            GradientStop { position: 0; color: Design.mix(Design.surface3, Qt.color("#ffffff"), 0.12) }
            GradientStop { position: 1; color: Design.surface1 }
        }
        border.color: Design.border
    }
}
