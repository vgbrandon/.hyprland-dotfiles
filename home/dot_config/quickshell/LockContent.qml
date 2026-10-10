import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Widgets

// Contenido de la pantalla de bloqueo de un monitor (lo usa LockSurface).
// Mismo estilo que la barra y sus paneles (sólidos, colores de matugen):
// reloj grande a la izquierda, tarjeta con la contraseña a la derecha y una
// mini barra abajo (reproductor y energía). En los demás monitores, solo el reloj.
Item {
    id: surface

    // El monitor de esta vista (lo pone LockSurface)
    required property ShellScreen screen

    // Por nombre: al arrancar, monitorFor() aún no conoce los monitores y no se reevalúa
    readonly property bool main: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === screen?.name
    readonly property string user: Quickshell.env("USER") ?? ""
    readonly property var locale: Qt.locale("es_ES")
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    // Monitor bajo (768 px): todo un poco más pequeño
    readonly property real k: Math.min(1, height / 1080)
    // Franja central donde van el reloj (a la izquierda) y la tarjeta (a la
    // derecha): en pantallas muy anchas no se separan más de 1500 px
    readonly property real stageWidth: Math.min(width * 0.82, 1500)
    readonly property real stageLeft: (width - stageWidth) / 2
    readonly property real stageRight: stageLeft + stageWidth

    // Entrada: aparece cuando el fondo está listo (o al rato, si no carga)
    property real shown: 0
    readonly property bool ready: wallpaper.status === Image.Ready || wallpaper.status === Image.Error || fallback.triggered
    onReadyChanged: if (ready) enter.start()
    Component.onCompleted: if (ready) enter.start()

    NumberAnimation {
        id: enter
        target: surface
        property: "shown"
        to: 1
        duration: 450
        easing.type: Easing.OutCubic
    }
    Timer {
        id: fallback
        property bool triggered: false
        interval: 600
        running: true
        onTriggered: triggered = true
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // --- Fondo: desenfocado y oscurecido con el color del tema ---
    Rectangle {
        anchors.fill: parent
        color: "black"
    }
    Image {
        id: wallpaper
        anchors.fill: parent
        source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
        // Mismo tamaño que el fondo del escritorio: así sale de la caché al instante
        sourceSize: Qt.size(surface.screen?.width ?? 1920, surface.screen?.height ?? 1080)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        opacity: surface.shown
        blurEnabled: true
        blur: 0.7
        blurMax: 64
        saturation: 0.1
    }
    // Velo del color de los paneles, más denso hacia la izquierda
    Rectangle {
        anchors.fill: parent
        opacity: surface.shown
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.withAlpha(Theme.panelBg, 0.75) }
            GradientStop { position: 0.6; color: Theme.withAlpha(Theme.panelBg, 0.35) }
            GradientStop { position: 1; color: Theme.withAlpha(Theme.panelBg, 0.55) }
        }
    }

    // --- Reloj: horas sobre minutos (como en la barra vertical) ---
    ColumnLayout {
        id: clockBlock

        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -30 * surface.k
        x: surface.main ? surface.stageLeft - (1 - surface.shown) * 40 : (parent.width - width) / 2
        opacity: surface.shown
        spacing: 0

        Text {
            Layout.alignment: surface.main ? Qt.AlignLeft : Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "hh")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 200 * surface.k
            font.weight: Font.Light
        }
        Text {
            Layout.alignment: surface.main ? Qt.AlignLeft : Qt.AlignHCenter
            // Pegado a las horas (la fuente deja mucho aire arriba y abajo)
            Layout.topMargin: -70 * surface.k
            text: Qt.formatDateTime(clock.date, "mm")
            color: Theme.primary
            font.family: Theme.font
            font.pixelSize: 200 * surface.k
            font.weight: Font.Light
        }

        // Fecha en una píldora, como el reloj de la barra
        Rectangle {
            Layout.alignment: surface.main ? Qt.AlignLeft : Qt.AlignHCenter
            Layout.topMargin: 18 * surface.k
            implicitWidth: dateRow.implicitWidth + 32
            implicitHeight: 40
            radius: height / 2
            color: Theme.surface

            RowLayout {
                id: dateRow
                anchors.centerIn: parent
                spacing: 10

                Label {
                    text: {
                        const s = clock.date.toLocaleDateString(surface.locale, "dddd, d 'de' MMMM");
                        return s.charAt(0).toUpperCase() + s.slice(1);
                    }
                    font.pixelSize: 16
                }
                // Segundero: un punto que late
                Rectangle {
                    implicitWidth: 6
                    implicitHeight: 6
                    radius: 3
                    color: Theme.primary
                    opacity: clock.date.getSeconds() % 2 === 0 ? 1 : 0.25
                    Behavior on opacity { NumberAnimation { duration: 400 } }
                }
            }
        }
    }

    // --- Tarjeta de desbloqueo (solo en el monitor enfocado) ---
    Rectangle {
        id: card

        property real shake: 0

        visible: surface.main
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: (1 - surface.shown) * 60
        x: surface.stageRight - width + shake
        opacity: surface.shown
        width: 380
        height: cardLayout.implicitHeight + 48
        radius: Theme.radius
        color: Theme.panelBg
        border.color: Lock.error !== "" ? Theme.withAlpha(Theme.error, 0.6) : Theme.surfaceHigh
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 200 } }

        // Temblor al fallar
        SequentialAnimation {
            id: shakeAnim
            loops: 2
            NumberAnimation { target: card; property: "shake"; to: 12; duration: 50 }
            NumberAnimation { target: card; property: "shake"; to: -12; duration: 100 }
            NumberAnimation { target: card; property: "shake"; to: 0; duration: 50 }
        }
        Connections {
            target: Lock
            function onFailCountChanged() { shakeAnim.restart(); }
        }

        ColumnLayout {
            id: cardLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 18

            // Avatar + nombre
            RowLayout {
                spacing: 14

                Rectangle {
                    implicitWidth: 56
                    implicitHeight: 56
                    radius: height / 2
                    color: Theme.primary

                    Text {
                        anchors.centerIn: parent
                        text: surface.user.charAt(0).toUpperCase()
                        color: Theme.primaryFg
                        font.family: Theme.font
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Label {
                        text: surface.user
                        font.pixelSize: 18
                    }
                    RowLayout {
                        spacing: 6
                        Icon {
                            text: Theme.iLock
                            color: Theme.subtext
                            font.pixelSize: 13
                        }
                        Label {
                            text: "Pantalla bloqueada"
                            color: Theme.subtext
                        }
                    }
                }
            }

            // Contraseña: píldora con puntos que aparecen al escribir
            Rectangle {
                id: field

                Layout.fillWidth: true
                implicitHeight: 52
                radius: height / 2
                color: Theme.surface
                border.color: input.activeFocus ? Theme.withAlpha(Theme.primary, 0.5) : "transparent"
                border.width: 1

                // El texto real va oculto; lo que se ve son los puntos
                TextInput {
                    id: input
                    anchors.fill: parent
                    opacity: 0
                    focus: true
                    enabled: !Lock.checking
                    echoMode: TextInput.Password
                    cursorVisible: false

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
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 8
                    spacing: 10

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 20
                        clip: true

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === ""
                            text: Lock.checking ? "Comprobando…" : "Contraseña"
                            color: Theme.subtext
                            font.pixelSize: 15
                        }

                        // Un punto por carácter. Los puntos son fijos y solo se muestran u
                        // ocultan: si el modelo fuera la cantidad, el Repeater los recrearía
                        // todos en cada tecla y parpadearían. Solo el nuevo entra creciendo.
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Repeater {
                                model: 18

                                Rectangle {
                                    id: dot
                                    required property int index
                                    readonly property bool on: index < input.text.length

                                    visible: on || scale > 0
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: Lock.checking ? Theme.subtext : Theme.text
                                    scale: on ? 1 : 0
                                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                                }
                            }
                        }
                    }

                    // Botón de desbloquear (o comprobando)
                    Rectangle {
                        implicitWidth: 38
                        implicitHeight: 38
                        radius: height / 2
                        color: input.text !== "" ? Theme.primary : Theme.surfaceHigh
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Icon {
                            anchors.centerIn: parent
                            text: Theme.iChevronRight
                            color: input.text !== "" ? Theme.primaryFg : Theme.subtext
                            font.pixelSize: 20
                            rotation: Lock.checking ? 360 : 0
                            RotationAnimation on rotation {
                                running: Lock.checking
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 900
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Lock.submit()
                        }
                    }
                }
            }

            // Error o ayuda
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: Lock.error !== "" ? Lock.error : "Escribe tu contraseña y pulsa Enter"
                color: Lock.error !== "" ? Theme.error : Theme.subtext
                font.pixelSize: Theme.fontSize
            }
        }
    }

    // --- Mini barra inferior: reproductor y energía (monitor enfocado) ---
    RowLayout {
        visible: surface.main
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24 - (1 - surface.shown) * 60
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: surface.shown
        spacing: Theme.gap

        // Reproductor
        Pill {
            visible: surface.player !== null
            vertical: false
            implicitHeight: 40
            padding: 16
            spacing: 14

            Icon {
                text: Theme.iPrev
                color: surface.player?.canGoPrevious ? Theme.text : Theme.dot
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (surface.player?.canGoPrevious) surface.player.previous()
                }
            }
            Icon {
                text: surface.player?.isPlaying ? Theme.iPause : Theme.iPlay
                color: Theme.primary
                font.pixelSize: 18
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: surface.player?.togglePlaying()
                }
            }
            Icon {
                text: Theme.iNext
                color: surface.player?.canGoNext ? Theme.text : Theme.dot
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (surface.player?.canGoNext) surface.player.next()
                }
            }
            Label {
                Layout.maximumWidth: 320
                text: {
                    const p = surface.player;
                    if (!p) return "";
                    return p.trackArtist ? `${p.trackTitle} • ${p.trackArtist}` : p.trackTitle;
                }
            }
        }

        // Energía
        Pill {
            vertical: false
            implicitHeight: 40
            padding: 16
            spacing: 18

            Repeater {
                model: [
                    { icon: Theme.iSleep, cmd: ["systemctl", "suspend"] },
                    { icon: Theme.iReboot, cmd: ["systemctl", "reboot"] },
                    { icon: Theme.iPower, cmd: ["systemctl", "poweroff"] }
                ]

                Icon {
                    id: powerIcon
                    required property var modelData

                    text: modelData.icon
                    color: powerMouse.containsMouse ? Theme.primary : Theme.text
                    font.pixelSize: 18

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(powerIcon.modelData.cmd)
                    }
                }
            }
        }
    }
}
