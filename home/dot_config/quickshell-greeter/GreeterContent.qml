import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// Contenido de la pantalla de inicio de sesión en un monitor. Mismo diseño que la
// pantalla de bloqueo (LockContent.qml de la sesión normal, diseño Velure
// de docs/velure.md): reloj grande a la izquierda, tarjeta de vidrio con usuario y
// contraseña a la derecha y una mini barra abajo (sesión y energía). En los demás
// monitores, solo el reloj.
Item {
    id: surface

    // El monitor de esta vista y si es el enfocado (los pone shell.qml)
    required property ShellScreen screen
    required property bool main
    readonly property var locale: Qt.locale("es_ES")
    // Monitor bajo (768 px): todo un poco más pequeño
    readonly property real k: Math.min(1, height / 1080)
    // Franja central donde van el reloj (a la izquierda) y la tarjeta (a la
    // derecha): lo que miden los dos más un hueco entre ellos, centrada
    readonly property real stageWidth: Math.min(width * 0.82, clockBlock.width + 260 * k + card.width)
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

    // --- Fondo: nítido, con un velo suave (el desenfoque va solo detrás del vidrio) ---
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
        opacity: surface.shown
    }
    // Velo con el tinte del diseño, más denso hacia la izquierda (bajo el reloj)
    Rectangle {
        anchors.fill: parent
        opacity: surface.shown
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
        border.color: Auth.error !== "" ? Design.alpha(Design.error, 0.6) : Design.border
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

                // Foto del perfil (si el usuario es el de la sesión que la compartió);
                // si no, la inicial, o un icono sin usuario
                Item {
                    readonly property bool owner: Auth.user !== "" && Auth.user === Theme.user
                    implicitWidth: 56
                    implicitHeight: 56

                    Avatar {
                        visible: Auth.user !== ""
                        anchors.fill: parent
                        size: 56
                        source: parent.owner ? Theme.avatar : ""
                        initial: (parent.owner && Theme.name !== "" ? Theme.name : Auth.user).charAt(0).toUpperCase()
                    }
                    Rectangle {
                        visible: Auth.user === ""
                        anchors.fill: parent
                        radius: height / 2
                        color: Design.accentContainer

                        Icon {
                            anchors.centerIn: parent
                            text: Theme.iAccount
                            color: Design.onAccentContainer
                            font.pixelSize: 28
                        }
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
                        selectionColor: Design.alpha(Design.accent, 0.4)
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
                radius: Design.radiusMd
                color: Design.alpha(Design.surface0, 0.8)
                border.color: input.activeFocus ? Design.alpha(Design.accent, 0.6) : Design.outlineVariant
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
                        radius: Design.radiusSm
                        color: input.text !== "" || Auth.launching ? Design.accent : Design.surface3
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Icon {
                            id: submitIcon
                            anchors.centerIn: parent
                            // ✓ cuando la contraseña es correcta
                            text: Auth.launching ? Theme.iCheck : Theme.iChevronRight
                            color: input.text !== "" || Auth.launching ? Design.onAccent : Design.onSurfaceVariant
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
        spacing: 8

        // Sesión (Hyprland, Hyprland con uwsm…): flechas para cambiarla
        GlassBlock {
            visible: Auth.sessions.length > 0

            GreeterButton {
                visible: Auth.sessions.length > 1
                icon: Theme.iChevronLeft
                iconColor: Design.onSurfaceVariant
                onClicked: Auth.nextSession(-1)
            }
            Icon {
                Layout.leftMargin: Auth.sessions.length > 1 ? 2 : 10
                text: Theme.iMonitor
                color: Design.accent
                font.pixelSize: 18
            }
            Label {
                Layout.leftMargin: 6
                Layout.rightMargin: Auth.sessions.length > 1 ? 2 : 10
                text: Auth.session?.name ?? ""
            }
            GreeterButton {
                visible: Auth.sessions.length > 1
                icon: Theme.iChevronRight
                iconColor: Design.onSurfaceVariant
                onClicked: Auth.nextSession(1)
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

                GreeterButton {
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
    component GreeterButton: IconBtn {
        size: 32
        iconSize: 18
        iconColor: Design.onSurface
    }
}
