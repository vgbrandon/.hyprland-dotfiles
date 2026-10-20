import QtQuick
import qs.services

// Dibujo del visualizador de audio en el tamaño que se le dé (el escritorio o una
// miniatura del selector). Estilos:
//   bars     barras desde abajo           mirror  barras desde el centro
//   digital  líneas finas en espejo       dots    columnas de puntos
//   wave     onda rellena                 line    líneas que ondulan, con eco
//   circle   barras alrededor de un aro   ring    aro que ondula
//   blob     burbuja que late con los graves
// Color: "theme" (el principal del tema), "gradient" (degradado iridiscente con los
// colores del fondo) o "white". Los datos llegan de services/Visualizer.qml.
//   VisualizerView { anchors.fill: parent; style: "ring"; colorMode: "gradient" }
Item {
    id: root

    property string style: Visualizer.style
    property string colorMode: Visualizer.colorMode
    property var values: Visualizer.values
    // Cuántas barras o puntos se dibujan (menos que las bandas, p. ej. en la barra: cada
    // una es la media de varias bandas)
    property int count: Visualizer.bands
    // Curva de los niveles: < 1 levanta los bajos (en tamaños pequeños, como la barra)
    property real curve: 1

    readonly property bool radial: style === "circle" || style === "ring" || style === "blob"
    readonly property real step: width / count
    readonly property real gap: Math.max(1, step * 0.3)
    // Barras redondeadas, más finas en "digital"
    readonly property real thick: style === "digital" ? Math.max(1, Math.round(step * 0.35)) : Math.max(2, Math.round(step - gap))
    readonly property real radius0: Math.min(width, height) * 0.27

    // Nivel de una barra (0–1): su banda o la media de las que le tocan
    function v(i) {
        const n = values.length;
        if (n === 0) return 0;
        let x;
        if (count >= n) {
            x = values[i] ?? 0;
        } else {
            const a = Math.floor(i * n / count), b = Math.max(a + 1, Math.floor((i + 1) * n / count));
            x = 0;
            for (let j = a; j < b; j++) x += values[j];
            x /= b - a;
        }
        return Math.min(1, curve === 1 ? x : Math.pow(x, curve));
    }
    // Graves: media de las primeras bandas (para la burbuja)
    readonly property real bass: {
        let s = 0;
        for (let i = 0; i < 6; i++) s += v(i);
        return s / 6;
    }

    // Color en la posición t (0–1) del dibujo
    // (Qt.tint convierte el texto "#rrggbb" del tema en un color con sus componentes)
    readonly property var palette: ["cyan", "primary", "magenta", "tertiary"].map(k => Qt.tint(Design.c(k, "#c3c0ff"), "transparent"))
    function colorAt(t) {
        if (colorMode === "white") return "#ffffff";
        if (colorMode !== "gradient") return Design.accent;
        const p = palette, x = Math.max(0, Math.min(1, t)) * (p.length - 1);
        const i = Math.min(p.length - 2, Math.floor(x));
        return Design.mix(p[i], p[i + 1], x - i);
    }

    // --- Barras, espejo y digital ---
    Repeater {
        model: root.style === "bars" || root.style === "mirror" || root.style === "digital" ? root.count : 0

        Rectangle {
            required property int index
            readonly property bool fromCenter: root.style !== "bars"
            width: root.thick
            height: Math.round(Math.max(width, root.v(index) * root.height))
            x: Math.round(index * root.step + (root.step - width) / 2)
            y: Math.round(fromCenter ? (root.height - height) / 2 : root.height - height)
            radius: width / 2
            color: root.colorAt(index / (root.count - 1))
        }
    }

    // --- Puntos ---
    Repeater {
        model: root.style === "dots" ? root.count : 0

        Column {
            id: dotColumn
            required property int index
            readonly property real size: root.thick
            readonly property int max: Math.max(1, Math.floor(root.height / (size + 3)))
            x: Math.round(index * root.step + (root.step - size) / 2)
            anchors.bottom: parent.bottom
            spacing: 3

            Repeater {
                model: Math.max(1, Math.round(root.v(dotColumn.index) * dotColumn.max))
                Rectangle {
                    width: dotColumn.size
                    height: dotColumn.size
                    radius: width / 2
                    color: root.colorAt(dotColumn.index / (root.count - 1))
                }
            }
        }
    }

    // --- Círculo: barras hacia fuera alrededor de un aro ---
    Repeater {
        model: root.style === "circle" ? root.count : 0

        Item {
            required property int index
            // Medio aro con las bandas y el otro medio en espejo: graves arriba
            readonly property real angle: index / root.count * 360
            readonly property int band: index < root.count / 2 ? index * 2 : (root.count - 1 - index) * 2
            x: root.width / 2
            y: root.height / 2
            rotation: angle

            Rectangle {
                readonly property real len: Math.max(width, root.v(parent.band) * root.radius0 * 0.9)
                width: Math.max(2, Math.round(root.radius0 * 2 * Math.PI / root.count * 0.55))
                height: len
                x: -width / 2
                y: -root.radius0 - len
                radius: width / 2
                color: root.colorAt(parent.index / root.count)
            }
        }
    }

    // --- Onda, líneas, aro y burbuja: con Canvas ---
    Canvas {
        id: canvas
        anchors.fill: parent
        visible: root.style === "wave" || root.style === "line" || root.style === "ring" || root.style === "blob"
        renderStrategy: Canvas.Cooperative

        // Fotogramas anteriores, para el eco de "line"
        property var echoes: []
        property var values: visible ? root.values : []
        onValuesChanged: {
            // Se guardan ya con el número de barras y la curva de este dibujo
            if (root.style === "line" && values.length > 0) {
                const now = [];
                for (let i = 0; i < root.count; i++) now.push(root.v(i));
                echoes = [now].concat(echoes).slice(0, 4);
            }
            requestPaint();
        }

        function grad(ctx, x0, y0, x1, y1, a) {
            const g = ctx.createLinearGradient(x0, y0, x1, y1);
            for (let i = 0; i <= 4; i++) {
                const c = root.colorAt(i / 4);
                g.addColorStop(i / 4, Qt.rgba(c.r, c.g, c.b, a));
            }
            return g;
        }
        // Curva suave por los puntos (por los puntos medios)
        function smooth(ctx, pts, closed) {
            const n = pts.length;
            if (closed) {
                const m0 = [(pts[n - 1][0] + pts[0][0]) / 2, (pts[n - 1][1] + pts[0][1]) / 2];
                ctx.moveTo(m0[0], m0[1]);
                for (let i = 0; i < n; i++) {
                    const a = pts[i], b = pts[(i + 1) % n];
                    ctx.quadraticCurveTo(a[0], a[1], (a[0] + b[0]) / 2, (a[1] + b[1]) / 2);
                }
                ctx.closePath();
            } else {
                ctx.moveTo(pts[0][0], pts[0][1]);
                for (let i = 1; i < n - 1; i++)
                    ctx.quadraticCurveTo(pts[i][0], pts[i][1], (pts[i][0] + pts[i + 1][0]) / 2, (pts[i][1] + pts[i + 1][1]) / 2);
                ctx.lineTo(pts[n - 1][0], pts[n - 1][1]);
            }
        }
        // Puntos de un aro: la mitad con las bandas y la otra en espejo
        function ringPoints(vals, base, amp) {
            const n = root.count, pts = [];
            for (let i = 0; i < n; i++) {
                const band = i < n / 2 ? i * 2 : (n - 1 - i) * 2;
                const r = base + Math.min(1, vals[band] ?? 0) * amp;
                const a = i / n * 2 * Math.PI - Math.PI / 2;
                pts.push([width / 2 + Math.cos(a) * r, height / 2 + Math.sin(a) * r]);
            }
            return pts;
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width, h = height, n = root.count;
            if (values.length < n) return;

            if (root.style === "wave") {
                const pts = [];
                for (let i = 0; i < n; i++) pts.push([i * w / (n - 1), h - 3 - root.v(i) * (h - 6)]);
                ctx.beginPath();
                smooth(ctx, pts, false);
                ctx.lineTo(w, h);
                ctx.lineTo(0, h);
                ctx.closePath();
                const fill = ctx.createLinearGradient(0, 0, 0, h);
                const c = root.colorAt(0.5);
                fill.addColorStop(0, Qt.rgba(c.r, c.g, c.b, 0.45));
                fill.addColorStop(1, Qt.rgba(c.r, c.g, c.b, 0));
                ctx.fillStyle = root.colorMode === "gradient" ? grad(ctx, 0, 0, w, 0, 0.35) : fill;
                ctx.fill();
                ctx.beginPath();
                smooth(ctx, pts, false);
                ctx.lineWidth = 3;
                ctx.lineJoin = "round";
                ctx.strokeStyle = grad(ctx, 0, 0, w, 0, 1);
                ctx.stroke();
            } else if (root.style === "line") {
                // La línea actual y, detrás, las de los fotogramas anteriores más tenues
                for (let k = echoes.length - 1; k >= 0; k--) {
                    // Una onda que se curva con el nivel de cada banda (cada eco, desfasado)
                    const vals = echoes[k], pts = [];
                    for (let i = 0; i < n; i++) {
                        const s = Math.sin(i / n * Math.PI * 7 + k * 0.7) * Math.min(1, vals[i] ?? 0);
                        pts.push([i * w / (n - 1), h / 2 + s * h * 0.45]);
                    }
                    ctx.beginPath();
                    smooth(ctx, pts, false);
                    ctx.lineWidth = k === 0 ? 2.5 : 1.5;
                    ctx.strokeStyle = grad(ctx, 0, 0, w, 0, k === 0 ? 1 : 0.4 - k * 0.08);
                    ctx.stroke();
                }
            } else if (root.style === "ring") {
                const base = root.radius0, amp = root.radius0 * 0.7;
                ctx.beginPath();
                smooth(ctx, ringPoints(values, base, amp), true);
                ctx.fillStyle = grad(ctx, 0, 0, w, h, 0.12);
                ctx.fill();
                ctx.lineWidth = 3;
                ctx.lineJoin = "round";
                ctx.strokeStyle = grad(ctx, w / 2 - base, h / 2 - base, w / 2 + base, h / 2 + base, 1);
                ctx.stroke();
                // Aro interior fijo y fino
                ctx.beginPath();
                ctx.arc(w / 2, h / 2, base * 0.82, 0, 2 * Math.PI);
                ctx.lineWidth = 1.5;
                ctx.strokeStyle = grad(ctx, 0, 0, w, h, 0.5);
                ctx.stroke();
            } else if (root.style === "blob") {
                // Crece con los graves y se deforma un poco con el resto de bandas
                const base = root.radius0 * (0.75 + root.bass * 0.45), amp = root.radius0 * 0.35;
                ctx.beginPath();
                smooth(ctx, ringPoints(values, base, amp), true);
                ctx.fillStyle = grad(ctx, w / 2 - base, h / 2 - base, w / 2 + base, h / 2 + base, 0.9);
                ctx.fill();
                ctx.beginPath();
                ctx.arc(w / 2, h / 2, base * 0.55, 0, 2 * Math.PI);
                ctx.fillStyle = Qt.rgba(0, 0, 0, 0.35);
                ctx.fill();
            }
        }
    }
}
