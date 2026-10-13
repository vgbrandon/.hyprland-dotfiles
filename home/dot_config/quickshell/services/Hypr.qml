pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland: monitor enfocado y acciones (dispatch). Con la config en Lua
// (hyprland.lua) los dispatch son llamadas a hl.dsp; con la clásica, los de siempre.
Singleton {
    id: root

    readonly property bool lua: Hyprland.usingLua !== false

    // Por nombre: al arrancar, monitorFor() aún no conoce los monitores y no se reevalúa
    function isFocused(screen) {
        return !!screen && Hyprland.focusedMonitor?.name === screen.name;
    }

    // Monitor enfocado (donde se abren los paneles y las ventanas)
    readonly property ShellScreen focusedScreen: Quickshell.screens.find(s => isFocused(s)) ?? Quickshell.screens[0] ?? null

    function focusWorkspace(ws) {
        Hyprland.dispatch(lua ? `hl.dsp.focus({ workspace = "${ws}" })` : `workspace ${ws}`);
    }

    function exec(cmd) {
        Hyprland.dispatch(lua ? `hl.dsp.exec_cmd(${JSON.stringify(cmd)})` : `exec ${cmd}`);
    }

    function exit() {
        Hyprland.dispatch(lua ? "hl.dsp.exit()" : "exit");
    }

    // Encender o apagar las pantallas
    function dpms(on) {
        Hyprland.dispatch(lua ? `hl.dsp.dpms({ action = "${on ? "on" : "off"}" })` : `dpms ${on ? "on" : "off"}`);
    }

    // Atajo de teclado en la ventana activa, p. ej. sendShortcut("CTRL", "V")
    function sendShortcut(mods, key) {
        Hyprland.dispatch(lua ? `hl.dsp.send_shortcut({ mods = "${mods}", key = "${key}" })` : `sendshortcut ${mods}, ${key},`);
    }

    // Comando de shell que mueve el cursor a ($x, $y) (para scripts con hyprctl)
    function cursorMoveCommand(x, y) {
        return lua ? `hyprctl dispatch "hl.dsp.cursor.move({ x = ${x}, y = ${y} })"` : `hyprctl dispatch movecursor ${x} ${y}`;
    }
}
