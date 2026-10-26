import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// --- Teclas ---
ColumnLayout {
    spacing: 16

    Box {
        Layout.fillWidth: true
        title: "Mapa de teclas"
        subtitle: "Resaltadas, las que cambian los ajustes de abajo"
        KeyboardDrawing {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 760
            Layout.preferredHeight: width * ratio
            light: ({ mode: "off" })
            // Caps Lock (57), Win (227), Alt (226), F4 (61), Tab (43), Fn (175)
            highlight: {
                const h = [];
                if (AulaKeyboard.keys.capsCtrl) h.push(57);
                if (AulaKeyboard.settings.winLock) h.push(227);
                if (AulaKeyboard.settings.altF4Lock) h.push(226, 61);
                if (AulaKeyboard.settings.altTabLock) h.push(226, 43);
                if (AulaKeyboard.settings.fnSwitch) h.push(175);
                return h;
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16

        Box {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Reasignar"
            OptionRow {
                title: "Caps Lock como Ctrl"
                subtitle: "En el firmware del teclado: funciona en cualquier equipo"
                checked: AulaKeyboard.keys.capsCtrl ?? false
                onToggled: AulaKeyboard.setCapsCtrl(!checked)
            }
            OptionRow {
                title: "Intercambiar Fn"
                subtitle: "F1–F12 sin pulsar Fn (las multimedia, con Fn)"
                checked: AulaKeyboard.settings.fnSwitch ?? false
                onToggled: AulaKeyboard.setSettings({ fnSwitch: !checked })
            }
            Item { Layout.fillHeight: true }
            Txt {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "Las macros no están: el formato que usa el programa oficial aún no está verificado y se guardan junto a la memoria de la pantalla."
                textStyle: Design.caption
                color: Design.muted
            }
        }
        Box {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Bloquear"
            subtitle: "Para jugar sin salirte por accidente"
            OptionRow {
                title: "Tecla Windows"
                checked: AulaKeyboard.settings.winLock ?? false
                onToggled: AulaKeyboard.setSettings({ winLock: !checked })
            }
            OptionRow {
                title: "Alt + F4"
                checked: AulaKeyboard.settings.altF4Lock ?? false
                onToggled: AulaKeyboard.setSettings({ altF4Lock: !checked })
            }
            OptionRow {
                title: "Alt + Tab"
                checked: AulaKeyboard.settings.altTabLock ?? false
                onToggled: AulaKeyboard.setSettings({ altTabLock: !checked })
            }
        }
    }
}
