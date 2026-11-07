pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Diseño Velure, «Elegante»: contención. Fondo profundo teñido del color del fondo de
// pantalla (velure), un único acento oscuro y desaturado (nunca pastel) solo para lo
// principal, lo demás que se resalta en blanco roto; sin brillos ni resplandores,
// títulos ligeros, controles finos. Transparencia de Windows 11 (Mica en la barra,
// acrílico en los paneles, casi opacos), bordes de 1 px, sombras amplias, esquinas
// contenidas y movimiento suave, sin rebotes.
// Lo usan los componentes de components/design y toda la shell (la barra, los paneles…).
// Documentado en docs/velure.md de los dotfiles.
Singleton {
    id: root

    // La guía de velure (modules/velureguide): quickshell ipc call guia toggle
    property bool guideOpen: false
    // La imagen que explica la guía; vacía, el fondo actual
    property string guideImage: ""
    // Desplaza la guía (para revisarla con capturas): quickshell ipc call guia scrollTo 900
    signal guideScroll(int y)
    // Guarda una captura de la guía entera: quickshell ipc call guia capture /tmp/guia.png
    signal guideCapture(string path)

    // Un token de velure o, mientras no los hay, un gris neutro
    function t(name, otherwise) {
        const v = Theme.tokens[name];
        return Qt.color(v !== undefined ? v : otherwise);
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
    // --- Color: tokens de velure ---
    readonly property color background: t("bg", "#17161a")
    readonly property color surface0: t("surface_low", "#1d1c20")
    readonly property color surface1: t("surface", "#232226")
    readonly property color surface2: t("surface_high", "#29282c")
    readonly property color surface3: t("overlay", "#2f2e33")
    // Texto
    readonly property color onSurface: t("text", "#dedde1")
    readonly property color onSurfaceVariant: t("subtext", "#b4b3b8")
    readonly property color muted: t("muted", "#8f8e94")
    // Acento: solo para la acción principal, el interruptor encendido y lo lleno de
    // deslizadores y barras
    readonly property color accent: t("primary", "#a9a8b0")
    // (con Binding: declarada con su valor, QML la deja en negro al llamarse on + otra propiedad)
    property color onAccent
    Binding { target: root; property: "onAccent"; value: t("on_primary", "#141416") }
    // Acentos 2 y 3 (lo que suena, recursos…) y el degradado del visualizador
    readonly property color second: t("secondary", "#9c9ba3")
    readonly property color third: t("tertiary", "#8f8e96")
    readonly property var gradient: {
        const g = [];
        for (let i = 0; Theme.tokens["gradient_" + i] !== undefined; i++) g.push(Qt.color(Theme.tokens["gradient_" + i]));
        return g.length > 0 ? g : [accent, second];
    }
    // Igual que el acento: sin degradado (se mantiene por compatibilidad)
    readonly property color accent2: accent
    // Énfasis secundario (escritorio activo, mosaicos encendidos, casillas, insignias):
    // blanco roto (AccentFill { secondary: true })
    readonly property color hi: t("emphasis", "#d8d8dc")
    // (con Binding: declarada con su valor, QML la deja en negro al llamarse on + otra propiedad)
    property color onHi
    Binding { target: root; property: "onHi"; value: t("on_emphasis", "#101012") }
    // Selección: un velo blanco discreto
    readonly property color selection: alpha("#ffffff", 0.06)
    readonly property color selectionBorder: alpha("#ffffff", 0.12)
    // Contenedores tonales: lo activo y lo seleccionado
    readonly property color tonal: surface3
    // (con Binding: declarada con su valor, QML la deja en negro al llamarse on + otra propiedad)
    property color onTonal
    Binding { target: root; property: "onTonal"; value: onSurface }
    readonly property color accentContainer: t("primary_container", "#3a393f")
    // (con Binding: declarada con su valor, QML la deja en negro al llamarse on + otra propiedad)
    property color onAccentContainer
    Binding { target: root; property: "onAccentContainer"; value: t("on_primary_container", "#e6e5ea") }
    // Contorno y separadores
    readonly property color outline: t("outline", "#716f76")
    readonly property color outlineVariant: t("border", "#46454b")
    // Estados
    readonly property color error: t("error", "#c98078")
    // (con Binding: declarada con su valor, QML la deja en negro al llamarse on + otra propiedad)
    property color onError
    Binding { target: root; property: "onError"; value: t("on_error", "#1d0c0a") }
    readonly property color errorContainer: t("error_container", "#502d29")
    readonly property color success: t("success", "#9cc9a4")
    readonly property color warning: t("warning", "#c9b574")
    readonly property color info: t("info", "#7a9cc6")
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
    property real micaOpacity: Config.translucent ? Config.translucentOpacity : 1
    // Acrílico (paneles y menús flotantes): el mismo fondo que la barra; lo de dentro
    // se distingue por los tonos elevados (raised, surface1…3) y hundidos (sunken)
    readonly property color glassTint: background
    property real glassOpacity: Config.translucent ? Config.translucentOpacity : 1
    Behavior on micaOpacity { NumberAnimation { duration: 250 } }
    Behavior on glassOpacity { NumberAnimation { duration: 250 } }
    readonly property real blur: 1.0
    // El vidrio que pinta Quickshell (Surface con backdrop) sigue el desenfoque de
    // Ajustes, como el de Hyprland; con los valores por defecto queda como siempre
    readonly property real backdropBlurMax: Math.max(8, Math.min(128, 64 * Config.blurSize * Config.blurPasses / 12))
    readonly property real backdropBrightness: Math.max(-1, Math.min(1, (Config.blurBrightness - 1) * 0.5))
    readonly property real backdropContrast: Math.max(-1, Math.min(1, (Config.blurContrast - 0.8916) * 0.6))
    readonly property real backdropSaturation: Math.max(-1, Math.min(1, 0.2 + (Config.blurVibrancy - 0.1696) * 1.5))
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
    // Con Ajustes → Esquinas redondeadas apagado, todos valen 0
    readonly property int radiusXs: corner(3)
    readonly property int radiusSm: corner(6)
    readonly property int radiusMd: corner(10)
    readonly property int radiusLg: corner(12)
    // Para los radios que no son un token (r). No pasan por aquí los círculos puros,
    // los interruptores, los deslizadores, las barras de progreso ni los escritorios
    function corner(r) {
        return Config.rounded ? r : 0;
    }

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
        target: "guia"

        function toggle(): void { root.guideOpen = !root.guideOpen; }
        function open(): void { root.guideOpen = true; }
        function close(): void { root.guideOpen = false; }
        // Abre la guía con otra imagen, sin cambiar el fondo: quickshell ipc call guia ver /ruta.jpg
        function ver(path: string): void { root.guideImage = path; root.guideOpen = true; }
        function scrollTo(y: int): void { root.guideScroll(y); }
        function capture(path: string): void { root.guideCapture(path); }
    }
}
