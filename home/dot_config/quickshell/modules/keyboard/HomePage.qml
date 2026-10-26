import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// --- Inicio: el teclado, luces rápidas y el dispositivo ---
ColumnLayout {
    spacing: 16

    Box {
        Layout.fillWidth: true
        Layout.fillHeight: true
        KeyboardDrawing {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 760
            Layout.preferredHeight: width * ratio
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 16

        Box {
            Layout.fillWidth: true
            title: "Iluminación"
            subtitle: AulaKeyboard.mode.name + (AulaKeyboard.mode.color && !AulaKeyboard.light.multicolor
                ? " · " + String(AulaKeyboard.light.color).toUpperCase() : "")
            trailing: Toggle {
                checked: AulaKeyboard.light.mode !== "off"
                follow: false
                onToggled: AulaKeyboard.setLight({ mode: checked ? "off" : (AulaKeyboard.lastMode || "static") })
            }
            SegRow {
                label: "Brillo"
                options: ["1", "2", "3", "4", "5"]
                current: (AulaKeyboard.light.brightness ?? 3) - 1
                onPicked: i => AulaKeyboard.setLight({ brightness: i + 1 })
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: ["static", "breathing", "spectrum", "rolling", "wave", "ripple"]
                    Chip {
                        required property string modelData
                        text: AulaKeyboard.modes.find(m => m.id === modelData)?.name ?? modelData
                        selected: AulaKeyboard.light.mode === modelData
                        onClicked: AulaKeyboard.setLight({ mode: modelData })
                    }
                }
            }
        }
        Box {
            Layout.preferredWidth: 320
            Layout.fillHeight: true
            title: "Dispositivo"
            InfoRow { label: "Modelo"; value: AulaKeyboard.device.model ?? "AULA F75 Max" }
            InfoRow { label: "Conexión"; value: "Cable USB-C" }
            InfoRow { label: "Firmware"; value: AulaKeyboard.device.firmware ?? "—" }
            InfoRow { label: "Interfaz"; value: AulaKeyboard.device.commandPath ?? "—"; mono: true }
            Btn {
                Layout.topMargin: 4
                kind: "tonal"
                text: "Ajustes del dispositivo"
                small: true
                onClicked: AulaKeyboard.tab = 4
            }
        }
    }
}
