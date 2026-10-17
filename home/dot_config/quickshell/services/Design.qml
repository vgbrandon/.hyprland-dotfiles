pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Diseño Prisma. Colores tonales de Material You
// (de matugen), materiales Mica (barra) y vidrio esmerilado (paneles) y detalles finos
// de macOS: bordes de 1 px con brillo arriba, sombras suaves, tipografía nítida.
// Lo usan la guía de estilo (modules/styleguide), los componentes de components/design
// y toda la shell (la barra, los paneles…). Documentado en docs/prisma.md de los dotfiles.
//   quickshell ipc call styleguide toggle
Singleton {
    id: root

    property bool guideOpen: false
    // Desplaza la guía (para revisarla con capturas): quickshell ipc call styleguide scrollTo 900
    signal guideScroll(int y)

    function c(name, fallback) {
        return Theme.scheme[name] ?? fallback;
    }
    function alpha(color, a) {
        const q = Qt.tint(color, "transparent");
        return Qt.rgba(q.r, q.g, q.b, a);
    }
    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    // --- Color: roles tonales ---
    // Superficies de menos a más elevadas (todas con un poco del tono del fondo)
    readonly property color background: c("surface_dim", "#121214")
    readonly property color surface0: c("surface_container_low", "#1a191d")
    readonly property color surface1: c("surface_container", "#1f1e22")
    readonly property color surface2: c("surface_container_high", "#29282c")
    readonly property color surface3: c("surface_container_highest", "#343337")
    // Texto
    readonly property color onSurface: c("on_surface", "#e6e1e5")
    readonly property color onSurfaceVariant: c("on_surface_variant", "#c9c4cc")
    readonly property color muted: alpha(onSurfaceVariant, 0.7)
    // Acento sólido (solo lo más importante)
    readonly property color accent: c("primary", "#d0bcff")
    readonly property color onAccent: c("on_primary", "#381e72")
    // Contenedores tonales: lo activo y lo seleccionado
    readonly property color tonal: c("secondary_container", "#4a4458")
    readonly property color onTonal: c("on_secondary_container", "#e8def8")
    readonly property color accentContainer: c("primary_container", "#4f378b")
    readonly property color onAccentContainer: c("on_primary_container", "#eaddff")
    // Contorno y separadores
    readonly property color outline: c("outline", "#938f99")
    readonly property color outlineVariant: c("outline_variant", "#49454f")
    // Estados (armonizados con el fondo)
    readonly property color error: c("error", "#ffb4ab")
    readonly property color onError: c("on_error", "#690005")
    readonly property color errorContainer: c("error_container", "#93000a")
    readonly property color success: c("green", "#98c379")
    readonly property color warning: c("yellow", "#e5c07b")
    readonly property color info: c("blue", "#61afef")
    // Capas de estado (encima de cualquier color): pasar el ratón y pulsar
    readonly property color hoverLayer: alpha(onSurface, 0.08)
    readonly property color pressLayer: alpha(onSurface, 0.12)

    // --- Materiales ---
    // Solo con "Barra y paneles translúcidos" encendido en Ajustes; si no, opacos.
    // Mica (barra, fondos grandes): poco transparente, con el tinte del fondo
    readonly property color micaTint: background
    property real micaOpacity: Config.translucent ? 0.86 : 1
    // Vidrio esmerilado (paneles y menús flotantes): más translúcido
    readonly property color glassTint: background
    property real glassOpacity: Config.translucent ? 0.68 : 1
    Behavior on micaOpacity { NumberAnimation { duration: 250 } }
    Behavior on glassOpacity { NumberAnimation { duration: 250 } }
    readonly property real blur: 1.0
    // Canto del vidrio: borde de 1 px y un brillo algo más claro arriba
    readonly property color border: alpha(onSurface, 0.10)
    readonly property color borderHighlight: alpha(onSurface, 0.20)

    // --- Tipografía ---
    readonly property string font: "Adwaita Sans"
    readonly property string monoFont: "JetBrainsMono Nerd Font"
    // Escala fija: [tamaño, peso]
    readonly property var display: ({ size: 34, weight: Font.Light })
    readonly property var title: ({ size: 22, weight: Font.Medium })
    readonly property var headline: ({ size: 16, weight: Font.DemiBold })
    readonly property var body: ({ size: 13, weight: Font.Normal })
    readonly property var label: ({ size: 12, weight: Font.Medium })
    readonly property var caption: ({ size: 11, weight: Font.Normal })

    // --- Forma ---
    readonly property int radiusXs: 4
    readonly property int radiusSm: 8
    readonly property int radiusMd: 12
    readonly property int radiusLg: 16

    // --- Espaciado (escala de 4) ---
    readonly property var space: [0, 4, 8, 12, 16, 20, 24, 32]

    // --- Elevación: sombras suaves y amplias (desenfoque, opacidad, desplazamiento) ---
    readonly property var elevation: [
        { blur: 0, opacity: 0, offset: 0 },
        { blur: 0.4, opacity: 0.25, offset: 2 },
        { blur: 0.8, opacity: 0.35, offset: 6 },
        { blur: 1.0, opacity: 0.5, offset: 12 }
    ]

    // --- Movimiento: rápido y suave, sin rebotes ---
    readonly property int fast: 120
    readonly property int normal: 200
    readonly property int slow: 320
    readonly property int easing: Easing.OutCubic

    IpcHandler {
        target: "styleguide"

        function toggle(): void { root.guideOpen = !root.guideOpen; }
        function open(): void { root.guideOpen = true; }
        function close(): void { root.guideOpen = false; }
        function scrollTo(y: int): void { root.guideScroll(y); }
    }
}
