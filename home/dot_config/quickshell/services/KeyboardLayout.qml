pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Distribuciones de teclado (idiomas): las que tiene Hyprland, cuál está activa,
// cambiar entre ellas y añadir o quitar. Se guardan en ~/.config/hypr/keyboard.lua
// (lo carga hyprland.lua después de su bloque input) y se aplican al momento. El
// catálogo para añadir sale de scripts/xkb-layouts.py. Panel en modules/kblayout.
//   quickshell ipc call kblayout toggle | next | map | add <layout> <variant> | remove <índice>
Singleton {
    id: root

    readonly property string luaPath: Quickshell.env("HOME") + "/.config/hypr/keyboard.lua"

    // [{ layout, variant }] tal como están en Hyprland; la primera es la de arranque
    property var layouts: []
    property int active: 0
    // Todas las del sistema: [{ layout, variant, name, short }]
    property var catalog: []

    signal panelRequested()

    // --- Ver la distribución (modules/kblayout/LayoutMapWindow.qml) ---
    property bool mapOpen: false
    // La que se muestra ({ layout, variant }) y qué escribe cada tecla:
    // { "AE01": [normal, Mayús, AltGr, AltGr + Mayús], … }
    property var mapLayout: null
    property var mapKeys: ({})
    function showMap(l) {
        mapLayout = l ?? current;
        mapOpen = true;
    }
    onMapLayoutChanged: {
        if (!mapLayout) return;
        mapKeys = {};
        keysProc.command = ["python3", "-I", Quickshell.shellPath("scripts/xkb-keys.py"), mapLayout.layout, mapLayout.variant];
        keysProc.running = true;
    }
    Process {
        id: keysProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.mapKeys = JSON.parse(this.text);
                } catch (e) {}
            }
        }
    }

    function find(l) {
        return catalog.find(c => c.layout === l.layout && c.variant === l.variant) ?? null;
    }
    // Nombre legible ("Spanish (Latin American)") y código corto ("ES")
    function nameOf(l) {
        const c = find(l);
        return c ? c.name : l.variant ? `${l.layout} (${l.variant})` : l.layout;
    }
    function shortOf(l) {
        return (find(l)?.short ?? l.layout).toUpperCase();
    }
    readonly property var current: layouts[active] ?? null
    readonly property string currentName: current ? nameOf(current) : ""

    function refresh() {
        if (!devicesProc.running) devicesProc.running = true;
    }

    function switchTo(i) {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", String(i)]);
    }
    function next() {
        if (layouts.length > 1) Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]);
    }

    function has(l) {
        return layouts.some(x => x.layout === l.layout && x.variant === l.variant);
    }
    function add(l) {
        if (has(l)) return;
        save(layouts.concat([{ layout: l.layout, variant: l.variant }]));
    }
    function remove(i) {
        if (layouts.length <= 1) return;
        save(layouts.filter((_, j) => j !== i));
    }
    // Mueve una distribución (d = -1 arriba, 1 abajo); la primera es la de arranque
    function move(i, d) {
        const j = i + d;
        if (j < 0 || j >= layouts.length) return;
        const list = layouts.slice();
        [list[i], list[j]] = [list[j], list[i]];
        save(list);
    }

    function toLua(list) {
        const layout = list.map(l => l.layout).join(",");
        const variant = list.map(l => l.variant).join(",");
        return `hl.config({ input = { kb_layout = "${layout}", kb_variant = "${variant}" } })`;
    }
    function save(list) {
        layouts = list;
        luaFile.setText([
            "-- Distribuciones de teclado: lo genera el módulo de teclado de Quickshell",
            "-- (KeyboardLayout.qml). La primera es la que se usa al arrancar.",
            "",
            toLua(list),
            ""
        ].join("\n"));
        Quickshell.execDetached(["hyprctl", "eval", toLua(list)]);
        chezmoiProc.running = true;
        refreshLater.restart();
    }

    // Distribuciones y la activa, del teclado principal
    Process {
        id: devicesProc
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(this.text).keyboards;
                    const kb = kbs.find(k => k.main) ?? kbs[0];
                    if (!kb) return;
                    const ls = kb.layout.split(",");
                    const vs = kb.variant.split(",");
                    root.layouts = ls.map((l, i) => ({ layout: l, variant: vs[i] ?? "" }));
                    root.active = Math.max(0, kb.active_layout_index ?? 0);
                } catch (e) {}
            }
        }
    }
    Component.onCompleted: {
        refresh();
        catalogProc.running = true;
    }
    // Hyprland tarda un momento en aplicar la config nueva
    Timer {
        id: refreshLater
        interval: 400
        onTriggered: root.refresh()
    }

    Timer {
        id: afterEvents
        interval: 120
        onTriggered: root.refresh()
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            // Llega uno por cada teclado a medida que cambian: se espera a que acabe la ráfaga
            if (event.name === "activelayout" || event.name === "configreloaded") afterEvents.restart();
        }
    }

    Process {
        id: catalogProc
        command: ["python3", "-I", Quickshell.shellPath("scripts/xkb-layouts.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.catalog = JSON.parse(this.text);
                } catch (e) {}
            }
        }
    }

    FileView {
        id: luaFile
        path: root.luaPath
        printErrors: false
    }

    // keyboard.lua está en los dotfiles: se sincroniza con chezmoi
    Process {
        id: chezmoiProc
        command: ["sh", "-c", `sleep 0.5
            command -v chezmoi >/dev/null || exit 0
            chezmoi managed --include=files | grep -qx ".config/hypr/keyboard.lua" || exit 0
            chezmoi add "$HOME/.config/hypr/keyboard.lua"`]
    }

    IpcHandler {
        target: "kblayout"

        function toggle(): void { root.panelRequested(); }
        function next(): void { root.next(); }
        // Ver la distribución activa
        function map(): void { root.showMap(); }
        // p. ej. add latam "" | add us intl
        function add(layout: string, variant: string): void { root.add({ layout: layout, variant: variant }); }
        function remove(index: int): void { root.remove(index); }
    }
}
