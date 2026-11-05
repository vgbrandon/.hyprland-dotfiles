pragma Singleton

import QtQuick
import Quickshell

// Solo para Design.qml (copiado de la sesión normal): la translucidez de los materiales,
// la misma que en la sesión (la comparte en theme.json; ver Theme)
Singleton {
    readonly property bool rounded: Theme.rounded
    readonly property bool translucent: Theme.translucent
    readonly property real translucentOpacity: Theme.translucentOpacity
    readonly property real blurSize: Theme.blurSize
    readonly property real blurPasses: Theme.blurPasses
    readonly property real blurBrightness: Theme.blurBrightness
    readonly property real blurContrast: Theme.blurContrast
    readonly property real blurVibrancy: Theme.blurVibrancy
}
