pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // Colores (tonos oscuros estilo Material, como en la captura)
    readonly property color barBg: Qt.rgba(0.07, 0.07, 0.08, 0.85)
    readonly property color surface: "#1f1e22"
    readonly property color surfaceHigh: "#2b2a30"
    readonly property color primary: "#d6d4dc"
    readonly property color primaryFg: "#1c1b1f"
    readonly property color text: "#e6e1e5"
    readonly property color subtext: "#9e9aa3"
    readonly property color dot: "#5a5860"

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

    readonly property color warm: "#ffb870"
}
