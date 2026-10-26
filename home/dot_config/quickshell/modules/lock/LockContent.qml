import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.services
import qs.components.base
import qs.components.buttons
import qs.components.design

// Contenido de la pantalla de bloqueo de un monitor (lo usa LockSurface), con el
// diseño Velure (docs/velure.md): reloj grande a la izquierda, tarjeta de vidrio
// con la contraseña a la derecha y una mini barra abajo (reproductor y energía). En
// los demás monitores, solo el reloj. La de inicio de sesión (quickshell-greeter) es igual.
Item {
    id: surface

    // El monitor de esta vista (lo pone LockSurface)
    required property ShellScreen screen

    // Por nombre: al arrancar, monitorFor() aún no conoce los monitores y no se reevalúa
    readonly property bool main: !Hyprland.focusedMonitor || Hypr.isFocused(screen)
    readonly property string user: Quickshell.env("USER") ?? ""
    readonly property var locale: Qt.locale("es_ES")
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    // Monitor bajo (768 px): todo un poco más pequeño
    readonly property real k: Math.min(1, height / 1080)
    // Franja central donde van el reloj (a la izquierda) y la tarjeta (a la
    // derecha): lo que miden los dos más un hueco entre ellos, centrada
    readonly property real stageWidth: Math.min(width * 0.82, clockBlock.width + 260 * k + card.width)
    readonly property real stageLeft: (width - stageWidth) / 2
    readonly property real stageRight: stageLeft + stageWidth

    // Entrada: aparece cuando el fondo está listo (o al rato, si no carga).
    // shown = reloj, tarjeta y mini barra; backdrop = el fondo, que no sale al desbloquear
    property real shown: 0
    property real backdrop: 0
    readonly property bool ready: wallpaper.status === Image.Ready || wallpaper.status === Image.Error || fallback.triggered
    onReadyChanged: if (ready) enter.start()
    Component.onCompleted: if (ready) enter.start()

    // Contraseña correcta: reloj, tarjeta y mini barra salen por donde entraron
    // (el fondo se queda) y luego se quita el bloqueo
    Connections {
        target: Lock
        function onUnlockingChanged() {
            if (Lock.unlocking) {
                enter.stop();
                leave.start();
            }
        }
    }
    NumberAnimation {
        id: leave
        target: surface
        property: "shown"
        to: 0
        duration: 450
        easing.type: Easing.InCubic
    }

    NumberAnimation {
        id: enter
        target: surface
        properties: "shown,backdrop"
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

    // --- Fondo: nítido, con un velo suave (el desenfoque va solo detrás del vidrio) ---
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
        opacity: surface.backdrop
    }
    // Velo con el tinte del diseño, más denso hacia la izquierda (bajo el reloj)
    Rectangle {
        anchors.fill: parent
        opacity: surface.backdrop
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Design.alpha(Design.background, 0.55) }
            GradientStop { position: 0.6; color: Design.alpha(Design.background, 0.15) }
            GradientStop { position: 1; color: Design.alpha(Design.background, 0.3) }
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
            font.features: { "tnum": 1 }
            // Dígitos más juntos (a este tamaño la fuente los separa mucho)
            font.letterSpacing: -6 * surface.k
        }
        Text {
            Layout.alignment: surface.main ? Qt.AlignLeft : Qt.AlignHCenter
            // Pegado a las horas (la fuente deja mucho aire arriba y abajo)
            Layout.topMargin: -82 * surface.k
            text: Qt.formatDateTime(clock.date, "mm")
            color: Design.accent
            font.family: Theme.font
            font.pixelSize: 200 * surface.k
            font.weight: Font.Light
            font.features: { "tnum": 1 }
            // Dígitos más juntos (a este tamaño la fuente los separa mucho)
            font.letterSpacing: -6 * surface.k
        }

        // Fecha en una cápsula de vidrio
        Rectangle {
            Layout.alignment: surface.main ? Qt.AlignLeft : Qt.AlignHCenter
            Layout.topMargin: 18 * surface.k
            implicitWidth: dateRow.implicitWidth + 32
            implicitHeight: 40
            radius: Design.radiusMd
            color: "transparent"
            Surface {
                anchors.fill: parent
                z: -1
                material: "glass"
                backdrop: wallpaper
                radius: parent.radius
                tintOpacity: 0.78
                bordered: false
                elevation: 0
                // Se recoloca al moverse (entrada, temblor)
                scrollY: clockBlock.x + clockBlock.y
            }
            border.color: Design.border
            border.width: 1

            GlassEdge {
                inset: Design.radiusMd
            }

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
                    color: Design.accent
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
        // Vidrio (el fondo desenfocado está justo detrás)
        radius: Design.radiusLg
        color: "transparent"
        Surface {
            anchors.fill: parent
            z: -1
            material: "glass"
            backdrop: wallpaper
            radius: parent.radius
            tintOpacity: 0.78
            bordered: false
            elevation: 0
            // Se recoloca al moverse (entrada, temblor)
            scrollY: card.x + card.y
        }
        border.color: Lock.error !== "" ? Design.alpha(Design.error, 0.6) : Design.border
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 200 } }

        GlassEdge {
            inset: Design.radiusLg
        }

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

                Avatar {
                    size: 56
                    source: Profile.avatarUrl
                    initial: Profile.initial
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Label {
                        text: Profile.name
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
                radius: Design.radiusMd
                color: Design.alpha(Design.surface0, 0.8)
                border.color: input.activeFocus ? Design.alpha(Design.accent, 0.6) : Design.outlineVariant
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
                        radius: Design.radiusSm
                        color: input.text !== "" || Lock.unlocking ? Design.accent : Design.surface3
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Icon {
                            id: submitIcon
                            anchors.centerIn: parent
                            // ✓ cuando la contraseña es correcta
                            text: Lock.unlocking ? Theme.iCheck : Theme.iChevronRight
                            color: input.text !== "" || Lock.unlocking ? Design.onAccent : Design.onSurfaceVariant
                            font.pixelSize: 20
                            RotationAnimation on rotation {
                                running: Lock.checking
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 900
                                // Al parar a medio giro, el icono queda derecho
                                onStopped: submitIcon.rotation = 0
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
        spacing: 8

        // Reproductor
        GlassBlock {
            visible: surface.player !== null

            LockButton {
                icon: Theme.iPrev
                enabled: surface.player?.canGoPrevious ?? false
                onClicked: surface.player.previous()
            }
            LockButton {
                icon: surface.player?.isPlaying ? Theme.iPause : Theme.iPlay
                iconColor: Design.accent
                onClicked: surface.player?.togglePlaying()
            }
            LockButton {
                icon: Theme.iNext
                enabled: surface.player?.canGoNext ?? false
                onClicked: surface.player.next()
            }
            Label {
                Layout.leftMargin: 6
                Layout.rightMargin: 8
                Layout.maximumWidth: 320
                text: {
                    const p = surface.player;
                    if (!p) return "";
                    return p.trackArtist ? `${p.trackTitle} · ${p.trackArtist}` : p.trackTitle;
                }
            }
        }

        // Energía
        GlassBlock {
            Repeater {
                model: [
                    { icon: Theme.iSleep, cmd: ["systemctl", "suspend"] },
                    { icon: Theme.iReboot, cmd: ["systemctl", "reboot"] },
                    { icon: Theme.iPower, cmd: ["systemctl", "poweroff"] }
                ]

                LockButton {
                    required property var modelData
                    icon: modelData.icon
                    onClicked: Quickshell.execDetached(modelData.cmd)
                }
            }
        }
    }

    // Bloque de vidrio de la mini barra
    component GlassBlock: Rectangle {
        default property alias content: blockRow.data
        implicitWidth: blockRow.implicitWidth + 12
        implicitHeight: 44
        radius: Design.radiusMd
        color: "transparent"
        Surface {
            anchors.fill: parent
            z: -1
            material: "glass"
            backdrop: wallpaper
            radius: parent.radius
            tintOpacity: 0.6
            bordered: false
            elevation: 0
            // Se recoloca al moverse (entrada, temblor)
            scrollY: x + (parent ? parent.x + parent.y : 0)
        }
        border.color: Design.border
        border.width: 1

        GlassEdge {
            inset: Design.radiusMd
        }
        RowLayout {
            id: blockRow
            anchors.centerIn: parent
            spacing: 2
        }
    }

    // Botón de la mini barra (con la capa de hover del diseño)
    component LockButton: IconBtn {
        size: 32
        iconSize: 18
        iconColor: Design.onSurface
    }
}
