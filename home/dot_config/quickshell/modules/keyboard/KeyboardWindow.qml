import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.base
import qs.components.containers
import qs.components.design
import qs.services

// Ventana del teclado AULA F75 Max (la lógica está en services/AulaKeyboard.qml): barra
// lateral con las secciones (Inicio, Luces, Pantalla, Teclas, Ajustes) y el teclado
// dibujado (KeyboardDrawing) con la vista previa de las luces. Los cambios se aplican al
// momento; lo que borra pide confirmación.
//   quickshell ipc call keyboard toggle | openTab 0-4
OverlayWindow {
    id: win

    open: AulaKeyboard.open
    onCloseRequested: AulaKeyboard.close()
    namespace: "quickshell:keyboard"
    focusMode: WlrKeyboardFocus.OnDemand
    cardWidth: Math.min(1120, (screen?.width ?? 1400) - 80)
    padding: 0
    spacing: 0

    onVisibleChanged: {
        if (visible) {
            AulaKeyboard.loadImages();
            AulaKeyboard.notice = "";
            AulaKeyboard.confirming = "";
        }
    }

    readonly property var sections: [
        { title: "Inicio", subtitle: "Tu teclado de un vistazo", icon: Theme.iApps },
        { title: "Luces", subtitle: "Efecto, color, brillo y velocidad", icon: Theme.iSun },
        { title: "Pantalla", subtitle: "Imagen o GIF en la pantalla de 128 × 128 y el reloj", icon: Theme.iImage },
        { title: "Teclas", subtitle: "Reasignación y bloqueos (guardados en el teclado)", icon: Theme.iKeyboard },
        { title: "Ajustes", subtitle: "Respuesta, suspensión, dispositivo y restablecer", icon: Theme.iSettings }
    ]

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 700
        spacing: 0

        // ================= Barra lateral =================
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 230
            color: Design.alpha("#000000", 0.18)
            topLeftRadius: Design.radiusMd
            bottomLeftRadius: Design.radiusMd

            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: Design.border
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 6

                // Marca
                RowLayout {
                    Layout.bottomMargin: 18
                    spacing: 12
                    Rectangle {
                        implicitWidth: 42
                        implicitHeight: 42
                        radius: Design.radiusMd
                        color: Design.accent
                        AccentFill { glow: true }
                        Icon {
                            anchors.centerIn: parent
                            text: Theme.iKeyboard
                            color: Design.onAccent
                            font.pixelSize: 21
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Txt { text: "AULA"; textStyle: Design.headline }
                        Txt { text: "F75 Max"; textStyle: Design.caption; color: Design.onSurfaceVariant }
                    }
                }

                Repeater {
                    model: win.sections
                    NavItem {
                        required property var modelData
                        required property int index
                        icon: modelData.icon
                        text: modelData.title
                        selected: AulaKeyboard.tab === index
                        onClicked: AulaKeyboard.tab = index
                    }
                }

                Item { Layout.fillHeight: true }

                // Estado de la conexión
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: conn.implicitHeight + 24
                    radius: Design.radiusMd
                    color: Design.raised
                    border.color: Design.border

                    ColumnLayout {
                        id: conn
                        x: 12
                        y: 12
                        width: parent.width - 24
                        spacing: 4
                        RowLayout {
                            spacing: 8
                            Rectangle {
                                implicitWidth: 8
                                implicitHeight: 8
                                radius: 4
                                color: AulaKeyboard.connected ? Design.success : Design.muted
                            }
                            Txt {
                                text: AulaKeyboard.connected ? "Conectado por cable" : "Desconectado"
                                textStyle: Design.label
                            }
                        }
                        Txt {
                            visible: AulaKeyboard.connected
                            text: "Firmware " + (AulaKeyboard.device.firmware ?? "—")
                            textStyle: Design.caption
                            color: Design.onSurfaceVariant
                            font.family: Design.monoFont
                        }
                    }
                }
            }
        }

        // ================= Contenido =================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 18

                // Cabecera de la sección
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Txt { Layout.fillWidth: true; text: win.sections[AulaKeyboard.tab].title; textStyle: Design.title }
                        Txt {
                            Layout.fillWidth: true
                            text: win.sections[AulaKeyboard.tab].subtitle
                            color: Design.onSurfaceVariant
                        }
                    }
                    // Lo que está haciendo, el último aviso o el error
                    Rectangle {
                        readonly property string message: AulaKeyboard.task !== "" ? AulaKeyboard.task
                            : AulaKeyboard.error !== "" ? AulaKeyboard.error : AulaKeyboard.notice
                        visible: message !== ""
                        Layout.maximumWidth: 360
                        implicitWidth: noticeRow.implicitWidth + 24
                        implicitHeight: 32
                        radius: Design.radiusSm
                        color: AulaKeyboard.error !== "" && AulaKeyboard.task === "" ? Design.alpha(Design.error, 0.15) : Design.raised
                        border.color: Design.border
                        RowLayout {
                            id: noticeRow
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, parent.width - 24)
                            spacing: 8
                            Icon {
                                text: AulaKeyboard.task !== "" ? Theme.iRefresh : AulaKeyboard.error !== "" ? Theme.iAlert : Theme.iCheck
                                color: AulaKeyboard.error !== "" && AulaKeyboard.task === "" ? Design.error : Design.accent
                                font.pixelSize: 14
                            }
                            Txt {
                                Layout.fillWidth: true
                                text: parent.parent.message
                                textStyle: Design.label
                            }
                        }
                    }
                    IconBtn {
                        icon: Theme.iRefresh
                        onClicked: AulaKeyboard.refresh()
                    }
                    IconBtn {
                        icon: Theme.iClose
                        onClicked: AulaKeyboard.close()
                    }
                }

                // Sin teclado: aviso en lugar de las secciones
                Box {
                    visible: !AulaKeyboard.connected
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout {
                        Layout.alignment: Qt.AlignCenter
                        spacing: 8
                        Icon {
                            Layout.alignment: Qt.AlignHCenter
                            text: Theme.iKeyboard
                            color: Design.muted
                            font.pixelSize: 40
                        }
                        Txt {
                            Layout.alignment: Qt.AlignHCenter
                            text: AulaKeyboard.available ? "Conecta el teclado por cable (USB-C)" : "Falta aulactl (~/.local/bin/aulactl)"
                            textStyle: Design.headline
                        }
                        Txt {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Por 2.4G o Bluetooth el teclado no deja cambiar su configuración"
                            color: Design.onSurfaceVariant
                        }
                    }
                }

                StackLayout {
                    visible: AulaKeyboard.connected
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: AulaKeyboard.tab

                    HomePage {}
                    LightPage {}
                    ScreenPage {}
                    KeysPage {}
                    SettingsPage {}
                }
            }
        }
    }
}
