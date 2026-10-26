pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Diseño Velure, «Elegante»: contención. Fondo profundo teñido del color del fondo de
// pantalla (paleta), un único acento oscuro y desaturado (nunca pastel) solo para lo
// principal, lo demás que se resalta en blanco roto; sin brillos ni resplandores,
// títulos ligeros, controles finos. Transparencia de Windows 11 (Mica en la barra,
// acrílico en los paneles, casi opacos), bordes de 1 px, sombras amplias, esquinas
// contenidas y movimiento suave, sin rebotes.
// Lo usan la guía de estilo (modules/styleguide), los componentes de components/design
// y toda la shell (la barra, los paneles…). Documentado en docs/velure.md de los dotfiles.
//   quickshell ipc call styleguide toggle
Singleton {
    id: root

    property bool guideOpen: false
    // Desplaza la guía (para revisarla con capturas): quickshell ipc call styleguide scrollTo 900
    signal guideScroll(int y)
    // Guarda una captura de la guía: quickshell ipc call styleguide capture /tmp/guia.png
    signal guideCapture(string path)

    function c(name, fallback) {
        return Theme.scheme[name] ?? fallback;
    }
    // Un papel de la paleta (paleta aplicar: p_background, p_accent…) o, mientras no hay
    // paleta cargada, lo de la fórmula
    function p(name, otherwise) {
        const v = Theme.scheme["p_" + name];
        return v !== undefined ? Qt.color(v) : otherwise;
    }
    function alpha(color, a) {
        const q = Qt.tint(color, "transparent");
        return Qt.rgba(q.r, q.g, q.b, a);
    }
    function mix(a, b, t) {
        a = Qt.color(a);
        b = Qt.color(b);
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }
    // El color hacia su gris (t = 1: sin color)
    function neutral(color, t) {
        const q = Qt.color(color);
        const g = 0.2126 * q.r + 0.7152 * q.g + 0.0722 * q.b;
        return Qt.rgba(q.r + (g - q.r) * t, q.g + (g - q.g) * t, q.b + (g - q.b) * t, 1);
    }

    // --- Color: roles tonales ---
    // El fondo de todo: un tono muy oscuro y apagado del color del fondo de pantalla.
    // Las superficies suben desde él con un poco de blanco
    readonly property color background: p("background", mix(neutral(c("primary_container", "#4f378b"), 0.45), "#000000", 0.74))
    readonly property color surface0: p("surface0", mix(background, "#ffffff", 0.035))
    readonly property color surface1: p("surface1", mix(background, "#ffffff", 0.06))
    readonly property color surface2: p("surface2", mix(background, "#ffffff", 0.09))
    readonly property color surface3: p("surface3", mix(background, "#ffffff", 0.13))
    // Texto: blanco roto y gris suave
    readonly property color onSurface: p("text", mix(neutral(c("on_surface", "#e6e1e5"), 0.7), "#ffffff", 0.2))
    readonly property color onSurfaceVariant: p("subtext", alpha(neutral(c("on_surface_variant", "#c9c4cc"), 0.6), 0.75))
    readonly property color muted: alpha(onSurfaceVariant, 0.6)
    // Acento: el primario oscurecido y algo desaturado (burdeos, petróleo…), solo para
    // la acción principal, el interruptor encendido y lo lleno de deslizadores y barras
    readonly property color accent: p("accent", mix(neutral(c("primary", "#d0bcff"), 0.3), c("primary_container", "#4f378b"), 0.55))
    // (con Binding: declarada con su valor, QML la deja en negro al llamarse on + otra propiedad)
    property color onAccent
    Binding { target: root; property: "onAccent"; value: p("onAccent", Qt.color("#ffffff")) }
    // Acentos 2 y 3 de la paleta propia (lo que suena, recursos…) y el degradado del
    // visualizador
    readonly property color second: p("accent2", Qt.color(c("secondary", "#ccc2dc")))
    readonly property color third: p("accent3", Qt.color(c("tertiary", "#efb8c8")))
    readonly property var gradient: {
        const g = [];
        for (let i = 0; Theme.scheme["p_gradient_" + i] !== undefined; i++) g.push(Qt.color(Theme.scheme["p_gradient_" + i]));
        return g.length > 0 ? g : [accent, second];
    }
    // Igual que el acento: sin degradado (se mantiene por compatibilidad)
    readonly property color accent2: accent
    // Énfasis secundario (escritorio activo, mosaicos encendidos, casillas, insignias):
    // blanco roto (AccentFill { secondary: true })
    readonly property color hi: p("hi", onSurface)
    // (con Binding: declarada con su valor, QML la deja en negro al llamarse on + otra propiedad)
    property color onHi
    Binding { target: root; property: "onHi"; value: Qt.color("#0e0e10") }
    // Selección: un velo blanco discreto
    readonly property color selection: alpha("#ffffff", 0.06)
    readonly property color selectionBorder: alpha("#ffffff", 0.12)
    // Contenedores tonales: lo activo y lo seleccionado
    readonly property color tonal: surface3
    // (con Binding: declarada con su valor, QML la deja en negro al llamarse on + otra propiedad)
    property color onTonal
    Binding { target: root; property: "onTonal"; value: onSurface }
    readonly property color accentContainer: p("container", alpha(accent, 0.35))
    // (con Binding: declarada con su valor, QML la deja en negro al llamarse on + otra propiedad)
    property color onAccentContainer
    Binding { target: root; property: "onAccentContainer"; value: p("onContainer", onSurface) }
    // Contorno y separadores
    readonly property color outline: p("outline", neutral(c("outline", "#938f99"), 0.6))
    readonly property color outlineVariant: p("outlineVariant", alpha("#ffffff", 0.1))
    // Estados (armonizados con el fondo)
    readonly property color error: p("error", c("error", "#ffb4ab"))
    // (con Binding: declarada con su valor, QML la deja en negro al llamarse on + otra propiedad)
    property color onError
    Binding { target: root; property: "onError"; value: c("on_error", "#690005") }
    readonly property color errorContainer: c("error_container", "#93000a")
    readonly property color success: p("success", c("green", "#98c379"))
    readonly property color warning: p("warning", c("yellow", "#e5c07b"))
    readonly property color info: p("info", c("blue", "#61afef"))
    // Capas de estado (encima de cualquier color): pasar el ratón y pulsar
    readonly property color hoverLayer: alpha(onSurface, 0.08)
    readonly property color pressLayer: alpha(onSurface, 0.12)
    // Hundido (campos, pistas, segmentado)
    readonly property color sunken: alpha("#000000", 0.22)
    // Elevado sobre el vidrio (botones tonales, pistas apagadas)
    readonly property color raised: alpha("#ffffff", 0.07)

    // --- Materiales ---
    // Solo con "Barra y paneles translúcidos" encendido en Ajustes; si no, opacos.
    // Transparencia de Windows 11, casi opaca para que se lea con cualquier fondo.
    // Mica (barra, fondos grandes), con el tinte del fondo
    readonly property color micaTint: background
    property real micaOpacity: Config.translucent ? 0.88 : 1
    // Acrílico (paneles y menús flotantes): el mismo fondo que la barra; lo de dentro
    // se distingue por los tonos elevados (raised, surface1…3) y hundidos (sunken)
    readonly property color glassTint: background
    property real glassOpacity: Config.translucent ? 0.9 : 1
    Behavior on micaOpacity { NumberAnimation { duration: 250 } }
    Behavior on glassOpacity { NumberAnimation { duration: 250 } }
    readonly property real blur: 1.0
    // Canto del vidrio: borde de 1 px y un brillo algo más claro arriba
    readonly property color border: alpha("#ffffff", 0.08)
    // Sin brillo arriba (GlassEdge queda invisible)
    readonly property color borderHighlight: "transparent"

    // --- Tipografía ---
    readonly property string font: "Adwaita Sans"
    readonly property string monoFont: "JetBrainsMono Nerd Font"
    // Escala fija: tamaño, peso y espaciado (los títulos, un poco más juntos)
    readonly property var display: ({ size: 38, weight: Font.Light, spacing: -0.8 })
    readonly property var title: ({ size: 24, weight: Font.Light, spacing: -0.3 })
    readonly property var headline: ({ size: 15, weight: Font.Medium })
    readonly property var body: ({ size: 13, weight: Font.Normal })
    readonly property var label: ({ size: 12, weight: Font.Medium, spacing: 0.2 })
    readonly property var caption: ({ size: 11, weight: Font.Normal })

    // --- Forma: esquinas contenidas, lo de dentro más pequeño que lo de fuera ---
    readonly property int radiusXs: 3
    readonly property int radiusSm: 6
    readonly property int radiusMd: 10
    readonly property int radiusLg: 12

    // Ancho de los paneles que se abren desde la barra (todos iguales; los menús, no)
    readonly property int popupWidth: 360

    // --- Espaciado (escala de 4) ---
    readonly property var space: [0, 4, 8, 12, 16, 20, 24, 32]

    // --- Elevación: sombras suaves y amplias (desenfoque, opacidad, desplazamiento) ---
    readonly property var elevation: [
        { blur: 0, opacity: 0, offset: 0 },
        { blur: 0.4, opacity: 0.35, offset: 2 },
        { blur: 0.8, opacity: 0.5, offset: 6 },
        { blur: 1.0, opacity: 0.7, offset: 12 }
    ]

    // --- Movimiento: rápido y suave, sin rebotes ---
    readonly property int fast: 120
    readonly property int normal: 200
    readonly property int slow: 320
    readonly property int easing: Easing.OutCubic
    // Lo que se desliza (interruptores, segmentado, escritorio activo): suave, sin rebote
    readonly property int spring: Easing.OutQuint
    readonly property real overshoot: 1.0
    readonly property int springDuration: 320

    IpcHandler {
        target: "styleguide"

        function toggle(): void { root.guideOpen = !root.guideOpen; }
        function open(): void { root.guideOpen = true; }
        function close(): void { root.guideOpen = false; }
        function scrollTo(y: int): void { root.guideScroll(y); }
        function capture(path: string): void { root.guideCapture(path); }
    }
}
