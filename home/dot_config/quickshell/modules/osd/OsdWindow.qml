import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components.base
import qs.components.design
import qs.services

// Aviso flotante de volumen, micrófono y brillo (lógica en services/Osd.qml): una
// píldora como las de la barra, abajo en el centro del monitor principal, con el icono,
// una barra fina y el porcentaje. La etiqueta (salida de audio, monitor del brillo)
// solo aparece cuando aporta algo. Sube y se funde al aparecer; el ratón la atraviesa
// y no roba el foco.
PanelWindow {
    id: win

    visible: Osd.shown || fade.running
    screen: Hypr.mainScreen
    anchors.bottom: true
    // Por encima de la barra si está abajo (el margen extra es para la sombra)
    margins.bottom: Config.reserve("bottom") + 40
    implicitWidth: 260 + shadowRoom * 2
    implicitHeight: 44 + shadowRoom * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:osd"
    // Sin zona de clic: el ratón pasa a lo de debajo
    mask: Region {}

    readonly property int shadowRoom: 14
    readonly property bool isMic: Osd.kind === "mic"
    readonly property bool isBrightness: Osd.kind === "brightness"

    readonly property string icon: isMic ? (Osd.muted ? Theme.iMicOff : Theme.iMic)
        : isBrightness ? (Osd.level < 0.34 ? Theme.iBrightnessLow : Osd.level < 0.67 ? Theme.iBrightnessMedium : Theme.iBrightnessHigh)
        : Osd.muted ? Theme.iMuted : Osd.level < 0.34 ? Theme.iVolumeLow : Osd.level < 0.67 ? Theme.iVolumeMedium : Theme.iVolume

    Item {
        anchors.fill: parent
        anchors.margins: win.shadowRoom

        opacity: Osd.shown ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                id: fade
                duration: Osd.shown ? 150 : 300
                easing.type: Easing.OutCubic
            }
        }
        transform: Translate {
            y: Osd.shown ? 0 : 12
            Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }

        // Vidrio con sombra suave (diseño Velure)
        Rectangle {
            anchors.fill: parent
            radius: Design.radiusMd
            color: Design.alpha(Design.glassTint, Design.glassOpacity)
            border.color: Design.border
            border.width: 1
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.4)
                shadowBlur: 0.5
                shadowVerticalOffset: 2
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 18
            spacing: 12

            // Icono: atenuado si está silenciado; rojo con el micrófono silenciado
            Icon {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter
                text: win.icon
                color: win.isMic && Osd.muted ? Theme.error : Osd.muted ? Theme.subtext : Theme.text
                font.pixelSize: 18
            }

            // Micrófono: solo el estado
            Label {
                visible: win.isMic
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: Osd.muted ? "Micrófono silenciado" : "Micrófono activado"
            }

            // Volumen y brillo: etiqueta (salida nueva o monitor, si hay) y la barra
            ColumnLayout {
                visible: !win.isMic
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                Label {
                    visible: Osd.device !== ""
                    Layout.fillWidth: true
                    text: Osd.device
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 1
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: Design.surface3

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, Osd.level))
                        height: parent.height
                        radius: 2
                        color: Osd.muted ? Design.muted : Design.accent
                        Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // Porcentaje, centrado con el icono
            Label {
                visible: !win.isMic
                Layout.preferredWidth: 34
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: Osd.muted ? "—" : Math.round(Osd.level * 100) + "%"
                color: Osd.muted ? Theme.subtext : Theme.text
                font.features: { "tnum": 1 }
            }
        }
    }
}
