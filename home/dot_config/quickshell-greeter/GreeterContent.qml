import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell

// Contenido de la pantalla de inicio en un monitor (mismo diseño que la pantalla
// de bloqueo). El campo de contraseña solo aparece en el monitor enfocado.
Item {
    id: surface

    required property ShellScreen screen
    required property bool main
    // Textura del fondo desenfocado que usan los paneles de vidrio
    readonly property Item glass: glassSource
    readonly property var locale: Qt.locale("es_ES")

    opacity: 0
    readonly property bool ready: wallpaper.status === Image.Ready || wallpaper.status === Image.Error || Theme.wallpaper === "" || fallback.triggered
    onReadyChanged: if (ready) fadeIn.start()
    Component.onCompleted: if (ready) fadeIn.start()

    NumberAnimation {
        id: fadeIn
        target: surface
        property: "opacity"
        to: 1
        duration: 400
        easing.type: Easing.OutCubic
    }
    Timer {
        id: fallback
        property bool triggered: false
        interval: 1000
        running: true
        onTriggered: triggered = true
    }

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
        source: Theme.wallpaper !== "" ? "file://" + Theme.wallpaper : ""
        sourceSize: Qt.size(surface.screen?.width ?? 1920, surface.screen?.height ?? 1080)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
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
                visible: Auth.user !== ""
                text: Auth.user.charAt(0).toUpperCase()
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 38
                font.weight: Font.DemiBold
            }
            Icon {
                anchors.centerIn: parent
                visible: Auth.user === ""
                text: Theme.iAccount
                font.pixelSize: 38
            }
        }

        // Usuario: se puede cambiar haciendo clic en el nombre
        TextInput {
            id: userInput

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 340
            horizontalAlignment: TextInput.AlignHCenter
            text: Auth.user
            color: Theme.text
            selectionColor: Theme.dot
            font.family: Theme.font
            font.pixelSize: 18
            onTextEdited: Auth.user = text
            onAccepted: input.forceActiveFocus()
            KeyNavigation.tab: input

            Text {
                anchors.centerIn: parent
                visible: userInput.text === ""
                text: "Usuario"
                color: Theme.subtext
                font: userInput.font
            }
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
            tint: Auth.error !== "" ? Theme.withAlpha(Theme.error, 0.22) : Theme.withAlpha(Theme.surface, 0.22)
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
                target: Auth
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
                    // Si no hay usuario conocido, se empieza por el nombre
                    focus: Auth.user !== ""
                    enabled: !Auth.busy
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: Theme.text
                    selectionColor: Theme.dot
                    font.family: Theme.font
                    font.pixelSize: 18
                    clip: true
                    KeyNavigation.backtab: userInput

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

                    Text {
                        visible: input.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: Auth.busy ? "Iniciando sesión…" : "Contraseña"
                        color: Theme.subtext
                        font: input.font
                    }
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 20
            text: Auth.error
            color: Theme.error
        }

        Component.onCompleted: {
            if (surface.main) (Auth.user === "" ? userInput : input).forceActiveFocus();
        }
    }

    // Sesión (abajo a la izquierda): flechas o clic para cambiarla
    GlassPanel {
        visible: surface.main && Auth.sessions.length > 0
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 32
        implicitWidth: sessionRow.implicitWidth + 28
        implicitHeight: 48
        glassSource: surface.glass

        RowLayout {
            id: sessionRow
            anchors.centerIn: parent
            spacing: 10

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
                color: Theme.subtext
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
