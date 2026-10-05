import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris

// Contenido de la pantalla de bloqueo de un monitor (lo usa LockSurface).
// El campo de contraseña solo aparece en el monitor enfocado.
Item {
    id: surface

    // El monitor de esta vista (lo pone LockSurface o la vista previa)
    required property ShellScreen screen
    // Textura del fondo desenfocado que usan los paneles de vidrio
    readonly property Item glass: glassSource

    opacity: 0
    readonly property bool ready: wallpaper.status === Image.Ready || wallpaper.status === Image.Error || fallback.triggered
    onReadyChanged: if (ready) fadeIn.start()
    Component.onCompleted: if (ready) fadeIn.start()

    NumberAnimation {
        id: fadeIn
        target: surface
        property: "opacity"
        to: 1
        duration: 250
        easing.type: Easing.OutCubic
    }
    Timer {
        id: fallback
        property bool triggered: false
        interval: 600
        running: true
        onTriggered: triggered = true
    }

    readonly property bool main: Hyprland.focusedMonitor === null || Hyprland.monitorFor(screen) === Hyprland.focusedMonitor
    readonly property string user: Quickshell.env("USER") ?? ""
    readonly property var locale: Qt.locale("es_ES")
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
        // Mismo tamaño que el fondo del escritorio: así sale de la caché al instante
        sourceSize: Qt.size(surface.screen.width, surface.screen.height)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
    }

    // Fondo casi nítido, apenas oscurecido
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blur: 0.12
        blurMax: 32
        brightness: -0.12
    }

    // Lo que se ve "a través" del vidrio: el fondo más desenfocado
    MultiEffect {
        id: frosted
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blur: 0.55
        blurMax: 48
        saturation: 0.15
    }
    ShaderEffectSource {
        id: glassSource
        anchors.fill: parent
        sourceItem: frosted
        hideSource: true
        visible: false
    }

    // Hora y fecha
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.18
        spacing: -8

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "hh:mm")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 128
            font.weight: Font.Light
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.25)
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: {
                const s = clock.date.toLocaleDateString(surface.locale, "dddd, d 'de' MMMM");
                return s.charAt(0).toUpperCase() + s.slice(1);
            }
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 24
        }
    }

    // Usuario y contraseña
    ColumnLayout {
        visible: surface.main
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.55
        spacing: 14

        GlassPanel {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 88
            implicitHeight: 88
            glassSource: surface.glass
            tint: Theme.withAlpha(Theme.primary, 0.25)

            Text {
                anchors.centerIn: parent
                text: surface.user.charAt(0).toUpperCase()
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 38
                font.weight: Font.DemiBold
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: surface.user
            font.pixelSize: 18
        }

        GlassPanel {
            id: field

            property real shake: 0

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            implicitWidth: 340
            implicitHeight: 56
            glassSource: surface.glass
            shiftX: shake
            tint: Lock.error !== "" ? Theme.withAlpha(Theme.error, 0.22) : Theme.withAlpha(Theme.surface, 0.22)
            transform: Translate { x: field.shake }

            // Temblor al fallar
            SequentialAnimation {
                id: shakeAnim
                loops: 2
                NumberAnimation { target: field; property: "shake"; to: 12; duration: 50 }
                NumberAnimation { target: field; property: "shake"; to: -12; duration: 100 }
                NumberAnimation { target: field; property: "shake"; to: 0; duration: 50 }
            }
            Connections {
                target: Lock
                function onFailCountChanged() { shakeAnim.restart(); }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 12

                Icon {
                    text: Theme.iLock
                    color: Theme.subtext
                    font.pixelSize: 18
                }

                TextInput {
                    id: input

                    Layout.fillWidth: true
                    focus: true
                    enabled: !Lock.checking
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: Theme.text
                    selectionColor: Theme.dot
                    font.family: Theme.font
                    font.pixelSize: 18
                    clip: true

                    onTextChanged: if (Lock.buffer !== text) Lock.buffer = text
                    onAccepted: Lock.submit()
                    Keys.onEscapePressed: text = ""

                    // Se vacía cuando el singleton limpia la contraseña (tras un intento)
                    Connections {
                        target: Lock
                        function onBufferChanged() {
                            if (input.text !== Lock.buffer) input.text = Lock.buffer;
                        }
                    }

                    Text {
                        visible: input.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: Lock.checking ? "Comprobando…" : "Contraseña"
                        color: Theme.subtext
                        font: input.font
                    }
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 20
            text: Lock.error
            color: Theme.error
        }
    }

    // Reproductor (abajo a la izquierda)
    RowLayout {
        visible: surface.main && surface.player !== null
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 32
        spacing: 12

        GlassPanel {
            implicitWidth: 44
            implicitHeight: 44
            glassSource: surface.glass

            Icon {
                anchors.centerIn: parent
                text: surface.player?.isPlaying ? Theme.iPause : Theme.iPlay
                font.pixelSize: 20
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: surface.player?.togglePlaying()
            }
        }
        ColumnLayout {
            spacing: 0
            Label {
                Layout.maximumWidth: 360
                text: surface.player?.trackTitle ?? ""
            }
            Label {
                Layout.maximumWidth: 360
                text: surface.player?.trackArtist ?? ""
                color: Theme.subtext
                font.pixelSize: Theme.fontSize
            }
        }
    }

    // Energía (abajo a la derecha)
    RowLayout {
        visible: surface.main
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32
        spacing: 10

        Repeater {
            model: [
                { icon: Theme.iSleep, cmd: ["systemctl", "suspend"] },
                { icon: Theme.iReboot, cmd: ["systemctl", "reboot"] },
                { icon: Theme.iPower, cmd: ["systemctl", "poweroff"] }
            ]

            GlassPanel {
                id: powerBtn
                required property var modelData

                implicitWidth: 48
                implicitHeight: 48
                glassSource: surface.glass
                tint: powerMouse.containsMouse ? Theme.withAlpha(Theme.text, 0.18) : Theme.withAlpha(Theme.surface, 0.22)

                Icon {
                    anchors.centerIn: parent
                    text: powerBtn.modelData.icon
                    font.pixelSize: 20
                }
                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(powerBtn.modelData.cmd)
                }
            }
        }
    }
}
