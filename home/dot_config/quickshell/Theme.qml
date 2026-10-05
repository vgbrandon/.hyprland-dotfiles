pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Paleta Material You generada por matugen a partir del fondo de pantalla.
    // Mientras no haya paleta se usan los grises originales.
    property var scheme: ({})
    property string wallpaper: ""

    function pick(name, fallback) {
        return scheme[name] ?? fallback;
    }

    function withAlpha(c, a) {
        const q = Qt.tint(c, "transparent");
        return Qt.rgba(q.r, q.g, q.b, a);
    }

    // Colores (cambian con una transición suave al cambiar el fondo)
    property color barBg: withAlpha(pick("surface", "#121214"), 0.85)
    property color panelBg: withAlpha(pick("surface", "#121214"), 0.97)
    property color surface: pick("surface_container", "#1f1e22")
    property color surfaceHigh: pick("surface_container_highest", "#2b2a30")
    property color primary: pick("primary", "#d6d4dc")
    property color primaryFg: pick("on_primary", "#1c1b1f")
    property color text: pick("on_surface", "#e6e1e5")
    property color subtext: pick("on_surface_variant", "#9e9aa3")
    property color dot: scheme.outline_variant ? Qt.lighter(scheme.outline_variant, 1.25) : "#5a5860"
    property color error: pick("error", "#ffb4ab")
    // Vidrio de los paneles (translúcido: Hyprland desenfoca lo que hay detrás)
    property color glassFill: withAlpha(pick("surface", "#121214"), 0.45)

    Behavior on barBg { ColorAnimation { duration: 600 } }
    Behavior on panelBg { ColorAnimation { duration: 600 } }
    Behavior on surface { ColorAnimation { duration: 600 } }
    Behavior on surfaceHigh { ColorAnimation { duration: 600 } }
    Behavior on primary { ColorAnimation { duration: 600 } }
    Behavior on primaryFg { ColorAnimation { duration: 600 } }
    Behavior on text { ColorAnimation { duration: 600 } }
    Behavior on subtext { ColorAnimation { duration: 600 } }
    Behavior on dot { ColorAnimation { duration: 600 } }
    Behavior on error { ColorAnimation { duration: 600 } }
    Behavior on glassFill { ColorAnimation { duration: 600 } }

    // Genera la paleta para un fondo nuevo (lo llama Wallpaper). matugen también
    // genera las plantillas de ~/.config/matugen/config.toml (tema de Zed)
    function setWallpaper(path) {
        if (path === "" || path === wallpaper) return;
        wallpaper = path;
        matugenProc.command = ["matugen", "image", path, "--json", "hex", "--prefer", "saturation", "-m", "dark", "-q"];
        matugenProc.running = true;
    }

    Process {
        id: matugenProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const colors = JSON.parse(this.text).colors;
                    const s = {};
                    for (const k in colors) s[k] = colors[k].dark.color;
                    root.scheme = s;
                    cache.setText(JSON.stringify({ wallpaper: root.wallpaper, scheme: s }));
                } catch (e) {
                    console.warn("matugen:", e);
                }
            }
        }
    }

    // Última paleta guardada: se aplica al iniciar sin esperar a matugen
    FileView {
        id: cache
        path: Quickshell.statePath("theme.json")
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (root.wallpaper === "") {
                    root.wallpaper = d.wallpaper;
                    root.scheme = d.scheme;
                }
            } catch (e) {}
        }
    }

    // Tamaños
    readonly property int barHeight: 38
    readonly property int pillHeight: 28
    readonly property int gap: 6

    // Fuentes
    readonly property string font: "sans-serif"
    readonly property string iconFont: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize: 11

    // Iconos (Nerd Font, Material Design)
    readonly property string iLogo: ""
    readonly property string iCpu: String.fromCodePoint(0xF061A)
    readonly property string iRam: String.fromCodePoint(0xF035B)
    readonly property string iPlay: String.fromCodePoint(0xF040A)
    readonly property string iPause: String.fromCodePoint(0xF03E4)
    readonly property string iVolume: String.fromCodePoint(0xF057E)
    readonly property string iMuted: String.fromCodePoint(0xF0581)
    readonly property string iEthernet: String.fromCodePoint(0xF0200)
    readonly property string iWifi: String.fromCodePoint(0xF05A9)
    readonly property string iNoNet: String.fromCodePoint(0xF0318)
    readonly property string iBt: String.fromCodePoint(0xF00AF)
    readonly property string iBtOn: String.fromCodePoint(0xF00B1)
    readonly property string iBtOff: String.fromCodePoint(0xF00B2)
    readonly property string iPrev: String.fromCodePoint(0xF04AE)
    readonly property string iNext: String.fromCodePoint(0xF04AD)
    readonly property string iMusic: String.fromCodePoint(0xF075A)
    readonly property string iNight: String.fromCodePoint(0xF0594)
    readonly property string iSun: String.fromCodePoint(0xF05A8)
    readonly property string iSearch: String.fromCodePoint(0xF0349)
    readonly property string iPower: String.fromCodePoint(0xF0425)
    readonly property string iReboot: String.fromCodePoint(0xF0709)
    readonly property string iLogout: String.fromCodePoint(0xF0343)
    readonly property string iSleep: String.fromCodePoint(0xF04B2)
    readonly property string iRegion: String.fromCodePoint(0xF0489)
    readonly property string iWindow: String.fromCodePoint(0xF05AF)
    readonly property string iMonitor: String.fromCodePoint(0xF0379)
    readonly property string iCamera: String.fromCodePoint(0xF0100)
    readonly property string iBell: String.fromCodePoint(0xF009A)
    readonly property string iBellEmpty: String.fromCodePoint(0xF009C)
    readonly property string iBellOff: String.fromCodePoint(0xF009B)
    readonly property string iClose: String.fromCodePoint(0xF0156)
    readonly property string iRestore: String.fromCodePoint(0xF099B)
    readonly property string iRefresh: String.fromCodePoint(0xF0450)
    readonly property string iChevronLeft: String.fromCodePoint(0xF0141)
    readonly property string iChevronRight: String.fromCodePoint(0xF0142)
    readonly property string iImage: String.fromCodePoint(0xF02E9)
    readonly property string iCheck: String.fromCodePoint(0xF012C)
    readonly property string iLock: String.fromCodePoint(0xF033E)

    readonly property color warm: "#ffb870"
}
