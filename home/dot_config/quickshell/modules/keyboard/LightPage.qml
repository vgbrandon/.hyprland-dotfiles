import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// --- Luces ---
RowLayout {
    spacing: 16

    // Efectos
    Box {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "Efecto"
        subtitle: "Se aplica al momento"
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 8
            rowSpacing: 8
            Repeater {
                model: AulaKeyboard.modes
                ModeTile {
                    required property var modelData
                    mode: modelData
                }
            }
        }
        Item { Layout.fillHeight: true }
    }

    // Color, brillo, velocidad y dirección, con la vista previa arriba
    ColumnLayout {
        Layout.preferredWidth: 400
        Layout.maximumWidth: 400
        Layout.fillHeight: true
        spacing: 16

        Box {
            Layout.fillWidth: true
            KeyboardDrawing {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.maximumWidth: 760
                Layout.preferredHeight: width * ratio
            }
        }
        Box {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Color"
            enabledContent: AulaKeyboard.mode.color === true
            Flow {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: AulaKeyboard.swatches
                    Rectangle {
                        required property string modelData
                        readonly property bool picked: !AulaKeyboard.light.multicolor
                            && String(AulaKeyboard.light.color).toLowerCase() === modelData
                        width: 26
                        height: 26
                        radius: 13
                        color: modelData
                        border.width: picked ? 2 : 1
                        border.color: picked ? Design.onSurface : Design.border
                        scale: swatchMouse.containsMouse ? 1.1 : 1
                        Behavior on scale { NumberAnimation { duration: Design.fast } }
                        MouseArea {
                            id: swatchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AulaKeyboard.setLight({ color: parent.modelData, multicolor: false })
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: Design.radiusSm
                    color: AulaKeyboard.light.color ?? "#ffffff"
                    border.color: Design.border
                }
                Field {
                    id: hexField
                    Layout.fillWidth: true
                    icon: Theme.iPicker
                    placeholder: "#RRGGBB"
                    text: String(AulaKeyboard.light.color ?? "").toUpperCase()
                    onKeyPressed: e => {
                        if (e.key !== Qt.Key_Return && e.key !== Qt.Key_Enter) return;
                        const v = hexField.text.trim().replace(/^#?/, "#");
                        if (/^#[0-9a-fA-F]{6}$/.test(v)) AulaKeyboard.setLight({ color: v.toLowerCase(), multicolor: false });
                        e.accepted = true;
                    }
                }
            }
            ToggleRow {
                text: "Multicolor"
                checked: AulaKeyboard.light.multicolor ?? false
                onToggled: AulaKeyboard.setLight({ multicolor: !checked })
            }
            SegRow {
                label: "Brillo"
                options: ["1", "2", "3", "4", "5"]
                current: (AulaKeyboard.light.brightness ?? 3) - 1
                onPicked: i => AulaKeyboard.setLight({ brightness: i + 1 })
            }
            SegRow {
                visible: AulaKeyboard.mode.speed === true
                label: "Velocidad"
                options: ["1", "2", "3", "4", "5"]
                current: (AulaKeyboard.light.speed ?? 3) - 1
                onPicked: i => AulaKeyboard.setLight({ speed: i + 1 })
            }
            SegRow {
                visible: AulaKeyboard.mode.direction === true
                label: "Dirección"
                options: ["→", "↓", "←", "↑"]
                current: Math.max(0, ["right", "down", "left", "up"].indexOf(AulaKeyboard.light.direction ?? "right"))
                onPicked: i => AulaKeyboard.setLight({ direction: ["right", "down", "left", "up"][i] })
            }
        }
    }
}
