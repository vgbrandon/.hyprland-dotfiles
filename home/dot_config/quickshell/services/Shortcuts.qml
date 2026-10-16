pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Atajos de teclado de Hyprland, leídos en vivo (hyprctl binds -j). Cada atajo lleva en
// hyprland.lua una descripción "Grupo: Acción"; aquí se agrupan y se juntan los que
// solo cambian en un número (Ir al escritorio 1…10) o hacen lo mismo con otra tecla.
// La ventana está en modules/shortcuts (Super + F1).
//   quickshell ipc call shortcuts toggle
Singleton {
    id: root

    property bool open: false
    function toggle() {
        open = !open;
    }
    onOpenChanged: if (open) proc.running = true

    // Grupos en este orden; los que no estén, al final
    readonly property var order: ["Aplicaciones", "Herramientas", "Sistema", "Ventanas", "Escritorios", "Multimedia"]

    // [{ name, items: [{ text, keys: [[tecla, …], …] }] }]
    property var groups: []

    // Nombres legibles de modificadores y teclas
    readonly property var modBits: [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]]
    readonly property var keyNames: ({
        left: "←", right: "→", up: "↑", down: "↓", Escape: "Esc", Return: "Enter", space: "Espacio",
        "mouse:272": "Clic izquierdo", "mouse:273": "Clic derecho", mouse_down: "Rueda ↓", mouse_up: "Rueda ↑",
        XF86AudioRaiseVolume: "Volumen +", XF86AudioLowerVolume: "Volumen −", XF86AudioMute: "Silencio",
        XF86AudioMicMute: "Micrófono", XF86MonBrightnessUp: "Brillo +", XF86MonBrightnessDown: "Brillo −",
        XF86AudioNext: "Siguiente", XF86AudioPrev: "Anterior", XF86AudioPlay: "Reproducir", XF86AudioPause: "Pausa"
    })
    function combo(b) {
        const keys = modBits.filter(([bit]) => b.modmask & bit).map(([, name]) => name);
        keys.push(keyNames[b.key] ?? (b.key.length === 1 ? b.key.toUpperCase() : b.key));
        return keys;
    }

    function last(a) {
        return a[a.length - 1];
    }

    function build(binds) {
        const byGroup = {};
        for (const b of binds) {
            const desc = b.description || "";
            const sep = desc.indexOf(": ");
            const group = sep > 0 ? desc.slice(0, sep) : "Otros";
            const text = sep > 0 ? desc.slice(sep + 2) : (desc || "Sin descripción");
            if (!byGroup[group]) byGroup[group] = [];
            byGroup[group].push({ text, keys: combo(b), modmask: b.modmask });
        }

        const result = [];
        for (const name of Object.keys(byGroup).sort((a, b) => (order.indexOf(a) + 1 || 99) - (order.indexOf(b) + 1 || 99))) {
            const items = [];
            for (const it of byGroup[name]) {
                // "Ir al escritorio 3": se junta con los demás números (mismos modificadores)
                const num = it.text.match(/^(.*\D)\s(\d+)$/);
                if (num) {
                    const base = num[1];
                    let row = items.find(r => r.base === base && r.modmask === it.modmask);
                    if (!row) {
                        row = { base, modmask: it.modmask, numbers: [], keys: [] };
                        items.push(row);
                    }
                    row.numbers.push(Number(num[2]));
                    row.keys.push(it.keys);
                    continue;
                }
                // La misma acción con otra tecla: una sola fila con varias combinaciones
                const same = items.find(r => r.text === it.text);
                if (same) same.combos.push(it.keys);
                else items.push({ text: it.text, combos: [it.keys] });
            }
            result.push({
                name,
                items: items.map(r => r.base === undefined ? r : {
                    text: `${r.base} ${Math.min(...r.numbers)}–${Math.max(...r.numbers)}`,
                    // Primera y última tecla: "Super + 1 … 0"
                    combos: [r.keys[0].slice(0, -1).concat([`${last(r.keys[0])} … ${last(last(r.keys))}`])]
                })
            });
        }
        groups = result;
    }

    Process {
        id: proc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.build(JSON.parse(this.text));
                } catch (e) {
                    root.groups = [];
                }
            }
        }
    }

    IpcHandler {
        target: "shortcuts"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }
}
