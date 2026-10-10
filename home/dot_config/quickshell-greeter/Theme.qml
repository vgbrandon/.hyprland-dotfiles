pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Tema de la pantalla de inicio. Los colores (matugen), el fondo y el usuario los
// deja la sesión normal en /var/lib/qs-greeter (el usuario "greeter" no puede leer
// la carpeta personal). Si no están, usa grises y negro.
Singleton {
    id: root

    readonly property string shared: Quickshell.env("QS_GREETER_SHARED") || "/var/lib/qs-greeter"

    property var scheme: ({})
    property string wallpaper: ""
    property string user: ""

    function pick(name, fallback) {
        return scheme[name] ?? fallback;
    }

    function withAlpha(c, a) {
        const q = Qt.tint(c, "transparent");
        return Qt.rgba(q.r, q.g, q.b, a);
    }

    readonly property color panelBg: pick("surface", "#121214")
    readonly property color surface: pick("surface_container", "#1f1e22")
    readonly property color surfaceHigh: pick("surface_container_highest", "#2b2a30")
    readonly property color primary: pick("primary", "#d6d4dc")
    readonly property color primaryFg: pick("on_primary", "#1c1b1f")
    readonly property color text: pick("on_surface", "#e6e1e5")
    readonly property color subtext: pick("on_surface_variant", "#9e9aa3")
    readonly property color dot: scheme.outline_variant ? Qt.lighter(scheme.outline_variant, 1.25) : "#5a5860"
    readonly property color error: pick("error", "#ffb4ab")

    FileView {
        path: root.shared + "/theme.json"
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.scheme = d.scheme ?? {};
                root.user = d.user ?? "";
                if (d.radius >= 0) root.radius = d.radius;
                if (d.wallpaper) root.wallpaper = root.shared + "/wallpaper";
            } catch (e) {}
        }
    }

    // Redondeo de los paneles (el de las ventanas de Hyprland, lo comparte la sesión)
    property int radius: 10
    readonly property int radiusSmall: Math.max(4, radius - 4)

    // Tamaños (los mismos que la barra)
    readonly property int pillHeight: 28
    readonly property int gap: 6

    // Fuentes
    readonly property string font: "sans-serif"
    readonly property string iconFont: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize: 11

    // Iconos (Nerd Font, Material Design)
    readonly property string iLock: String.fromCodePoint(0xF033E)
    readonly property string iAccount: String.fromCodePoint(0xF0004)
    readonly property string iSleep: String.fromCodePoint(0xF04B2)
    readonly property string iReboot: String.fromCodePoint(0xF0709)
    readonly property string iPower: String.fromCodePoint(0xF0425)
    readonly property string iMonitor: String.fromCodePoint(0xF0379)
    readonly property string iChevronLeft: String.fromCodePoint(0xF0141)
    readonly property string iChevronRight: String.fromCodePoint(0xF0142)
}
