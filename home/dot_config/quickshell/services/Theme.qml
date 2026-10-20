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
    property color panelBg: pick("surface", "#121214")
    property color surface: pick("surface_container", "#1f1e22")
    property color surfaceHigh: pick("surface_container_highest", "#2b2a30")
    property color primary: pick("primary", "#d6d4dc")
    property color primaryFg: pick("on_primary", "#1c1b1f")
    property color text: pick("on_surface", "#e6e1e5")
    property color subtext: pick("on_surface_variant", "#9e9aa3")
    property color dot: scheme.outline_variant ? Qt.lighter(scheme.outline_variant, 1.25) : "#5a5860"
    property color error: pick("error", "#ffb4ab")
    // Aviso (amarillo armonizado con el fondo, de los custom_colors de matugen)
    property color warning: pick("yellow", "#e5c07b")
    // Azul armonizado con el fondo (custom_colors de matugen)
    property color blue: pick("blue", "#61afef")

    Behavior on panelBg { ColorAnimation { duration: 600 } }
    Behavior on surface { ColorAnimation { duration: 600 } }
    Behavior on surfaceHigh { ColorAnimation { duration: 600 } }
    Behavior on primary { ColorAnimation { duration: 600 } }
    Behavior on primaryFg { ColorAnimation { duration: 600 } }
    Behavior on text { ColorAnimation { duration: 600 } }
    Behavior on subtext { ColorAnimation { duration: 600 } }
    Behavior on dot { ColorAnimation { duration: 600 } }
    Behavior on error { ColorAnimation { duration: 600 } }
    Behavior on warning { ColorAnimation { duration: 600 } }
    Behavior on blue { ColorAnimation { duration: 600 } }

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
                    root.shareWithGreeter();
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
                    root.shareWithGreeter();
                }
            } catch (e) {}
        }
    }

    // Comparte fondo, colores, usuario, nombre y foto con la pantalla de inicio de sesión (greetd):
    // el usuario "greeter" no puede leer esta carpeta personal. Si la carpeta
    // compartida no existe (greeter sin instalar), no hace nada.
    function shareWithGreeter() {
        if (wallpaper === "") return;
        const data = JSON.stringify({ wallpaper: true, user: Quickshell.env("USER"), name: Profile.name,
            avatar: Profile.hasAvatar, radius: radius, primary: Displays.primary, scheme: scheme });
        // También la foto del perfil (o se borra si ya no hay)
        shareProc.command = ["sh", "-c", `d=/var/lib/qs-greeter
            [ -w "$d" ] || exit 0
            cp -f "$1" "$d/wallpaper.tmp" && mv -f "$d/wallpaper.tmp" "$d/wallpaper"
            if [ -s "$3" ]; then cp -f "$3" "$d/avatar.tmp" && mv -f "$d/avatar.tmp" "$d/avatar"; else rm -f "$d/avatar"; fi
            printf '%s' "$2" > "$d/theme.json"`, "sh", wallpaper, data, Profile.avatarPath];
        shareProc.running = true;
    }
    Process {
        id: shareProc
    }

    // Redondeo de los paneles: el mismo que las ventanas de Hyprland
    // (decoration:rounding), leído al iniciar. Los elementos de dentro usan uno menor.
    property int radius: 10
    // Elementos de dentro de los paneles: el radio del diseño nuevo (Design.radiusSm)
    readonly property int radiusSmall: 8

    Process {
        command: ["hyprctl", "getoption", "decoration:rounding", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const value = JSON.parse(this.text).int;
                    if (value >= 0) root.radius = value;
                    root.shareWithGreeter();
                } catch (e) {}
            }
        }
    }

    // Alto de la barra
    readonly property int barHeight: 38

    // Fuentes (la de la interfaz es la del diseño, Design.font)
    readonly property string font: "Adwaita Sans"
    readonly property string monoFont: "JetBrainsMono Nerd Font Mono"
    readonly property string iconFont: "JetBrainsMono Nerd Font Propo"
    // Fuente de iconos propia (Prisma Icons), para los que no trae la Nerd Font, como el
    // logo de Bitwarden. Se genera con scripts/build-icons.py desde assets/icons/*.svg;
    // Icon la usa cuando la otra no tiene el carácter.
    FontLoader {
        id: prismaIcons
        source: Quickshell.shellPath("assets/fonts/PrismaIcons.otf")
    }
    readonly property string prismaIconFont: prismaIcons.name
    readonly property string iBitwarden: String.fromCodePoint(0x100000)
    readonly property string iOpenCode: String.fromCodePoint(0x100001)
    readonly property int fontSize: 11

    // Iconos (Nerd Font, Material Design)
    readonly property string iLogo: ""
    readonly property string iCpu: String.fromCodePoint(0xF061A)
    readonly property string iRam: String.fromCodePoint(0xF035B)
    readonly property string iPlay: String.fromCodePoint(0xF040A)
    readonly property string iPause: String.fromCodePoint(0xF03E4)
    readonly property string iVolume: String.fromCodePoint(0xF057E)
    readonly property string iMuted: String.fromCodePoint(0xF0581)
    readonly property string iHeadphones: String.fromCodePoint(0xF02CB)
    readonly property string iSpeaker: String.fromCodePoint(0xF04C3)
    readonly property string iTv: String.fromCodePoint(0xF0502)
    readonly property string iApps: String.fromCodePoint(0xF003B)
    readonly property string iEthernet: String.fromCodePoint(0xF0200)
    readonly property string iWifi: String.fromCodePoint(0xF05A9)
    readonly property string iNoNet: String.fromCodePoint(0xF0318)
    readonly property string iWifi1: String.fromCodePoint(0xF091F)
    readonly property string iWifi2: String.fromCodePoint(0xF0922)
    readonly property string iWifi3: String.fromCodePoint(0xF0925)
    readonly property string iWifi4: String.fromCodePoint(0xF0928)
    readonly property string iWifiOff: String.fromCodePoint(0xF05AA)
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
    readonly property string iPicker: String.fromCodePoint(0xF020A)
    readonly property string iPacman: String.fromCodePoint(0xF0BAF)
    readonly property string iGhost: String.fromCodePoint(0xF02A0)
    readonly property string iVideo: String.fromCodePoint(0xF0567)
    readonly property string iMic: String.fromCodePoint(0xF036C)
    readonly property string iMicOff: String.fromCodePoint(0xF036D)
    readonly property string iVolumeLow: String.fromCodePoint(0xF057F)
    readonly property string iVolumeMedium: String.fromCodePoint(0xF0580)
    readonly property string iBrightnessLow: String.fromCodePoint(0xF00DE)
    readonly property string iBrightnessMedium: String.fromCodePoint(0xF00DF)
    readonly property string iBrightnessHigh: String.fromCodePoint(0xF00E0)
    readonly property string iBell: String.fromCodePoint(0xF009A)
    readonly property string iBellBadge: String.fromCodePoint(0xF116B)
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
    readonly property string iSettings: String.fromCodePoint(0xF0493)
    readonly property string iAnimation: String.fromCodePoint(0xF05D8)
    readonly property string iBlur: String.fromCodePoint(0xF00B5)
    readonly property string iShadow: String.fromCodePoint(0xF0637)
    readonly property string iGaps: String.fromCodePoint(0xF084E)
    readonly property string iStar: String.fromCodePoint(0xF04CE)
    readonly property string iStarOutline: String.fromCodePoint(0xF04D2)
    readonly property string iGpu: String.fromCodePoint(0xF08AE)
    readonly property string iDisk: String.fromCodePoint(0xF02CA)
    readonly property string iThermometer: String.fromCodePoint(0xF050F)
    readonly property string iSpeed: String.fromCodePoint(0xF04C5)
    readonly property string iArrowDown: String.fromCodePoint(0xF0045)
    readonly property string iArrowUp: String.fromCodePoint(0xF005D)
    readonly property string iList: String.fromCodePoint(0xF0279)
    readonly property string iKeyboard: String.fromCodePoint(0xF030C)
    readonly property string iTimer: String.fromCodePoint(0xF051B)
    readonly property string iCoffee: String.fromCodePoint(0xF0176)
    readonly property string iBrain: String.fromCodePoint(0xF09D1)
    readonly property string iPlus: String.fromCodePoint(0xF0415)
    readonly property string iMinus: String.fromCodePoint(0xF0374)
    readonly property string iClipboard: String.fromCodePoint(0xF0147)
    readonly property string iSend: String.fromCodePoint(0xF048A)
    readonly property string iStop: String.fromCodePoint(0xF04DB)
    readonly property string iCopy: String.fromCodePoint(0xF018F)
    readonly property string iChevronDown: String.fromCodePoint(0xF0140)
    readonly property string iChevronUp: String.fromCodePoint(0xF0143)
    readonly property string iPencil: String.fromCodePoint(0xF03EB)
    readonly property string iNote: String.fromCodePoint(0xF082E)
    readonly property string iEye: String.fromCodePoint(0xF0208)
    readonly property string iEyeOff: String.fromCodePoint(0xF0209)
    readonly property string iAccount: String.fromCodePoint(0xF0004)
    readonly property string iKey: String.fromCodePoint(0xF0306)
    readonly property string iTwoFactor: String.fromCodePoint(0xF09AF)
    readonly property string iLockOpen: String.fromCodePoint(0xF0FC6)
    readonly property string iShieldKey: String.fromCodePoint(0xF0BC4)
    readonly property string iDelete: String.fromCodePoint(0xF01B4)
    readonly property string iAlert: String.fromCodePoint(0xF0026)
    readonly property string iConsole: String.fromCodePoint(0xF018D)
    readonly property string iFolder: String.fromCodePoint(0xF024B)
    readonly property string iShield: String.fromCodePoint(0xF0498)
    readonly property string iDots: String.fromCodePoint(0xF01D8)
    readonly property string iUndo: String.fromCodePoint(0xF054C)
    readonly property string iCompress: String.fromCodePoint(0xF0615)
    readonly property string iAttach: String.fromCodePoint(0xF0066)
    readonly property string iAt: String.fromCodePoint(0xF0065)
    readonly property string iSlash: String.fromCodePoint(0xF0FDF)
    readonly property string iGithub: String.fromCodePoint(0xF02A4)
    readonly property string iOpacity: String.fromCodePoint(0xF05CC)
    readonly property string iServer: String.fromCodePoint(0xF048B)
    readonly property string iWeb: String.fromCodePoint(0xF059F)
    readonly property string iDatabase: String.fromCodePoint(0xF01BC)
    readonly property string iOpenNew: String.fromCodePoint(0xF03CC)
    readonly property string iDockTop: String.fromCodePoint(0xF1513)
    readonly property string iDockBottom: String.fromCodePoint(0xF10A9)
    readonly property string iDockLeft: String.fromCodePoint(0xF10AA)
    readonly property string iDockRight: String.fromCodePoint(0xF10AB)

    readonly property color warm: "#ffb870"
}
