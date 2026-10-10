import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell

// Contenido de la pantalla de inicio de sesión en un monitor. Mismo diseño que la
// pantalla de bloqueo (LockContent.qml de la sesión normal): reloj grande a la
// izquierda, tarjeta con usuario y contraseña a la derecha y una mini barra abajo
// (sesión y energía). En los demás monitores, solo el reloj.
Item {
    id: surface

    // El monitor de esta vista y si es el enfocado (los pone shell.qml)
    required property ShellScreen screen
    required property bool main
    readonly property var locale: Qt.locale("es_ES")
    // Monitor bajo (768 px): todo un poco más pequeño
    readonly property real k: Math.min(1, height / 1080)
    // Franja central donde van el reloj (a la izquierda) y la tarjeta (a la
    // derecha): en pantallas muy anchas no se separan más de 1500 px
    readonly property real stageWidth: Math.min(width * 0.82, 1500)
    readonly property real stageLeft: (width - stageWidth) / 2
    readonly property real stageRight: stageLeft + stageWidth

    // Entrada: aparece cuando el fondo está listo (o al rato, si no carga)
    property real shown: 0
    readonly property bool ready: wallpaper.status === Image.Ready || wallpaper.status === Image.Error || Theme.wallpaper === "" || fallback.triggered
    onReadyChanged: if (ready) enter.start()
    Component.onCompleted: if (ready) enter.start()

    // El campo toma el foco al abrir y cada vez que este monitor pasa a ser el
    // enfocado (sin tener que mover el ratón): el nombre si no hay usuario conocido,
    // si no la contraseña. Con un pequeño retraso, para que la ventana ya tenga el teclado
    onMainChanged: focusTimer.restart()
    Timer {
        id: focusTimer
        interval: 150
        onTriggered: if (surface.main) (Auth.user === "" ? userInput : input).forceActiveFocus()
    }

    // Contraseña aceptada: todo sale por donde entró (el fundido a negro va en shell.qml)
    Connections {
        target: Auth
        function onLaunchingChanged() {
            if (Auth.launching) {
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
        source: Theme.wallpaper !== "" ? "file://" + Theme.wallpaper : ""
        sourceSize: Qt.size(surface.screen?.width ?? 1920, surface.screen?.height ?? 1080)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
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
        border.color: Auth.error !== "" ? Theme.withAlpha(Theme.error, 0.6) : Theme.surfaceHigh
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
            target: Auth
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
                        visible: Auth.user !== ""
                        text: Auth.user.charAt(0).toUpperCase()
                        color: Theme.primaryFg
                        font.family: Theme.font
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                    }
                    Icon {
                        anchors.centerIn: parent
                        visible: Auth.user === ""
                        text: Theme.iAccount
                        color: Theme.primaryFg
                        font.pixelSize: 28
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    // Usuario: se puede cambiar escribiendo otro nombre
                    TextInput {
                        id: userInput

                        Layout.fillWidth: true
                        text: Auth.user
                        color: Theme.text
                        selectionColor: Theme.dot
                        font.family: Theme.font
                        font.pixelSize: 18
                        clip: true
                        onTextEdited: Auth.user = text
                        onAccepted: input.forceActiveFocus()
                        KeyNavigation.tab: input

                        Text {
                            visible: userInput.text === ""
                            text: "Usuario"
                            color: Theme.subtext
                            font: userInput.font
                        }
                    }
                    RowLayout {
                        spacing: 6
                        Icon {
                            text: Theme.iLock
                            color: Theme.subtext
                            font.pixelSize: 13
                        }
                        Label {
                            text: "Iniciar sesión"
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
                    // Si no hay usuario conocido, se empieza por el nombre
                    focus: Auth.user !== ""
                    enabled: !Auth.busy
                    KeyNavigation.backtab: userInput
                    echoMode: TextInput.Password
                    cursorVisible: false

                    onTextChanged: if (Auth.password !== text) Auth.password = text
                    onAccepted: Auth.submit()
                    Keys.onEscapePressed: text = ""

                    // Se vacía cuando Auth limpia la contraseña (tras un intento)
                    Connections {
                        target: Auth
                        function onPasswordChanged() {
                            if (input.text !== Auth.password) input.text = Auth.password;
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
                            text: Auth.busy ? "Iniciando sesión…" : "Contraseña"
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
                                    color: Auth.busy ? Theme.subtext : Theme.text
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
                        color: input.text !== "" || Auth.launching ? Theme.primary : Theme.surfaceHigh
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Icon {
                            id: submitIcon
                            anchors.centerIn: parent
                            // ✓ cuando la contraseña es correcta
                            text: Auth.launching ? Theme.iCheck : Theme.iChevronRight
                            color: input.text !== "" || Auth.launching ? Theme.primaryFg : Theme.subtext
                            font.pixelSize: 20
                            RotationAnimation on rotation {
                                running: Auth.busy && !Auth.launching
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 900
                                // Al parar a medio giro, el ✓ queda derecho
                                onStopped: submitIcon.rotation = 0
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Auth.submit()
                        }
                    }
                }
            }

            Component.onCompleted: focusTimer.restart()

            // Error o ayuda
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: Auth.error !== "" ? Auth.error : "Escribe tu contraseña y pulsa Enter"
                color: Auth.error !== "" ? Theme.error : Theme.subtext
                font.pixelSize: Theme.fontSize
            }
        }
    }

    // --- Mini barra inferior: sesión y energía (monitor enfocado) ---
    RowLayout {
        visible: surface.main
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24 - (1 - surface.shown) * 60
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: surface.shown
        spacing: Theme.gap

        // Sesión (Hyprland, Hyprland con uwsm…): flechas para cambiarla
        Pill {
            visible: Auth.sessions.length > 0
            vertical: false
            implicitHeight: 40
            padding: 16
            spacing: 12

            Icon {
                visible: Auth.sessions.length > 1
                text: Theme.iChevronLeft
                color: Theme.subtext
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Auth.nextSession(-1)
                }
            }
            Icon {
                text: Theme.iMonitor
                color: Theme.primary
                font.pixelSize: 18
            }
            Label {
                text: Auth.session?.name ?? ""
            }
            Icon {
                visible: Auth.sessions.length > 1
                text: Theme.iChevronRight
                color: Theme.subtext
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Auth.nextSession(1)
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
