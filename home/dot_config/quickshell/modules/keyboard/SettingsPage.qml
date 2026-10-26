import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// --- Ajustes ---
RowLayout {
    spacing: 16

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16

        Box {
            Layout.fillWidth: true
            title: "Teclado"
            SegRow {
                label: "Tiempo de respuesta (1 = más rápido)"
                options: ["1", "2", "3", "4", "5"]
                current: (AulaKeyboard.settings.response ?? 1) - 1
                onPicked: i => AulaKeyboard.setSettings({ response: i + 1 })
            }
            SegRow {
                label: "Suspender las luces tras"
                options: ["Nunca", "1 min", "5 min", "30 min"]
                current: Math.max(0, ["never", "1", "5", "30"].indexOf(AulaKeyboard.settings.sleep ?? "5"))
                onPicked: i => AulaKeyboard.setSettings({ sleep: ["never", "1", "5", "30"][i] })
            }
        }
        Box {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Restablecer"
            subtitle: "No se puede deshacer"
            OptionText {
                title: "Teclas e iluminación"
                subtitle: "Quita las reasignaciones y deja las luces de fábrica. No toca la pantalla."
                DangerBtn {
                    action: "data"
                    text: "Restablecer"
                    onConfirmed: AulaKeyboard.reset("data")
                }
            }
            OptionText {
                title: "Todo de fábrica"
                subtitle: "Lo anterior y además borra la imagen de la pantalla."
                DangerBtn {
                    action: "factory"
                    text: "De fábrica"
                    onConfirmed: AulaKeyboard.reset("factory")
                }
            }
        Item { Layout.fillHeight: true }
        }
    }
    Box {
        Layout.preferredWidth: 360
        Layout.fillHeight: true
        title: "Dispositivo"
        InfoRow { label: "Estado"; value: AulaKeyboard.connected ? "Conectado" : "Desconectado" }
        InfoRow { label: "Conexión"; value: "Cable USB-C" }
        InfoRow { label: "Modelo"; value: AulaKeyboard.device.model ?? "AULA F75 Max" }
        InfoRow { label: "Firmware"; value: AulaKeyboard.device.firmware ?? "—" }
        InfoRow { label: "Comandos"; value: AulaKeyboard.device.commandPath ?? "—"; mono: true }
        InfoRow { label: "Pantalla"; value: AulaKeyboard.device.displayPath ?? "—"; mono: true }
        InfoRow {
            label: "Permisos"
            value: AulaKeyboard.device.access ? "Correctos (regla de udev)" : "Sin acceso: chezmoi apply y reconectar"
            valueColor: AulaKeyboard.device.access ? Design.success : Design.error
        }
        RowLayout {
            Layout.topMargin: 6
            spacing: 8
            Btn {
                kind: "tonal"
                text: "Probar la conexión"
                small: true
                onClicked: AulaKeyboard.probe()
            }
            Txt {
                visible: AulaKeyboard.probeResult !== ""
                text: AulaKeyboard.probeResult === "ok" ? "Responde" : "No responde"
                textStyle: Design.label
                color: AulaKeyboard.probeResult === "ok" ? Design.success : Design.error
            }
        }
        Item { Layout.fillHeight: true }
        Txt {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: "El teclado no deja leer su configuración: lo que se ve es lo último que se aplicó desde aquí (~/.local/state/aula/state.json)."
            textStyle: Design.caption
            color: Design.muted
        }
    }
}
