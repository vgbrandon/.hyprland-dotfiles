import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.components
import qs.components.base
import qs.components.buttons
import qs.components.containers
import qs.components.controls
import qs.services

// Panel de ajustes rápidos: entra desde la derecha del monitor principal
// (como el centro de notificaciones).
//   quickshell ipc call config toggle
SidePanel {
    id: panel

    open: Config.open
    onCloseRequested: Config.close()
    namespace: "quickshell:config-panel"

    HyprOption { id: animations; option: "animations:enabled" }
    HyprOption { id: blur; option: "decoration:blur:enabled" }
    HyprOption { id: shadows; option: "decoration:shadow:enabled" }
    HyprOption { id: gapsIn; option: "general:gaps_in"; max: 20; fallback: 5 }
    HyprOption { id: gapsOut; option: "general:gaps_out"; max: 30; fallback: 10 }

    readonly property BluetoothAdapter bt: Bluetooth.defaultAdapter

    // Perfil: foto, nombre, usuario@equipo y tiempo encendido. Clic = ventana del perfil
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 64
        radius: Theme.radiusSmall
        color: profileMouse.containsMouse ? Theme.surfaceHigh : Theme.surface

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 12

            Avatar {
                size: 44
                source: Profile.avatarUrl
                initial: Profile.initial
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label {
                    Layout.fillWidth: true
                    text: Profile.name
                    font.pixelSize: 16
                }
                Label {
                    Layout.fillWidth: true
                    text: `${Profile.user}@${Profile.host}  ·  encendido hace ${Profile.uptimeText}`
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                }
            }
            Icon {
                text: Theme.iChevronRight
                color: Theme.subtext
            }
        }
        MouseArea {
            id: profileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Config.close();
                Profile.open = true;
            }
        }
    }

    Section {
        title: "Dispositivos"
        contentSpacing: 8

        SwitchRow {
            icon: Networking.wifiEnabled ? Theme.iWifi : Theme.iWifiOff
            text: "Red inalámbrica"
            checked: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
        SwitchRow {
            icon: panel.bt?.enabled ? Theme.iBtOn : Theme.iBt
            text: "Bluetooth"
            checked: panel.bt?.enabled ?? false
            onToggled: if (panel.bt) panel.bt.enabled = !panel.bt.enabled
        }
        SwitchRow {
            icon: Notifs.dnd ? Theme.iBellOff : Theme.iBell
            text: "No molestar"
            checked: Notifs.dnd
            onToggled: Notifs.dnd = !Notifs.dnd
        }
        SwitchRow {
            icon: NightLight.enabled ? Theme.iNight : Theme.iSun
            text: "Luz nocturna"
            checked: NightLight.available && NightLight.enabled
            onToggled: NightLight.toggle()
        }

        // Intensidad de la luz nocturna: más a la derecha = más cálida
        // (izquierda = 6500 K, derecha = 2500 K)
        SliderRow {
            visible: NightLight.available
            Layout.leftMargin: 34
            text: "Intensidad"
            value: NightLight.strength
            valueText: `${NightLight.temperature}K`
            valueWidth: 44
            color: Theme.warm
            dimmed: !NightLight.enabled
            resettable: NightLight.temperature !== NightLight.defaultTemp
            onMoved: f => NightLight.setTemperature(NightLight.maxTemp - f * (NightLight.maxTemp - NightLight.minTemp))
            onReset: NightLight.reset()

            WheelHandler {
                onWheel: e => NightLight.scroll(e.angleDelta.y)
            }
        }
    }

    // Brillo de cada monitor (DDC/CI con ddcutil; solo si se detectan)
    Section {
        visible: Brightness.available
        title: "Brillo"
        contentSpacing: 2

        Repeater {
            model: Brightness.displays

            RowLayout {
                id: bright
                required property var modelData
                Layout.leftMargin: 6
                Layout.rightMargin: 4
                spacing: 10

                Icon {
                    text: bright.modelData.value < 0.34 ? Theme.iBrightnessLow
                        : bright.modelData.value < 0.67 ? Theme.iBrightnessMedium : Theme.iBrightnessHigh
                    color: Theme.subtext
                }
                Label {
                    Layout.preferredWidth: 90
                    text: bright.modelData.model || bright.modelData.output
                    elide: Text.ElideRight
                }
                Slider {
                    Layout.fillWidth: true
                    value: bright.modelData.value
                    // Sin el aviso flotante: el nivel ya se ve aquí
                    onMoved: f => Brightness.set(bright.modelData.output, f, false)
                }
                Label {
                    Layout.preferredWidth: 34
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(bright.modelData.value * 100) + "%"
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }

    Section {
        title: "Apariencia"
        contentSpacing: 8

        NavRow {
            icon: Theme.iMonitor
            text: "Pantallas"
            onClicked: {
                Config.close();
                Displays.toggle();
            }
        }
        NavRow {
            icon: Theme.iKeyboard
            text: "Teclado"
            onClicked: {
                Config.close();
                AulaKeyboard.toggle();
            }
        }

        // Posición de la barra: un botón por borde
        RowLayout {
            Layout.leftMargin: 6
            Layout.rightMargin: 4
            spacing: 10

            Icon {
                text: ({ top: Theme.iDockTop, bottom: Theme.iDockBottom, left: Theme.iDockLeft, right: Theme.iDockRight })[Config.barTarget]
                color: Theme.subtext
            }
            Label {
                Layout.fillWidth: true
                text: "Barra"
            }
            Repeater {
                model: [
                    { position: "top", icon: Theme.iDockTop },
                    { position: "bottom", icon: Theme.iDockBottom },
                    { position: "left", icon: Theme.iDockLeft },
                    { position: "right", icon: Theme.iDockRight }
                ]

                Chip {
                    required property var modelData
                    icon: modelData.icon
                    selected: Config.barTarget === modelData.position
                    onClicked: Config.setBarPosition(modelData.position)
                }
            }
        }

        // Selector de fondos: carrusel o cuadrícula a pantalla completa
        RowLayout {
            Layout.leftMargin: 6
            Layout.rightMargin: 4
            spacing: 10

            Icon {
                text: Theme.iImage
                color: Theme.subtext
            }
            Label {
                Layout.fillWidth: true
                text: "Selector de fondos"
            }
            Repeater {
                model: [
                    { style: "carousel", label: "Carrusel" },
                    { style: "grid", label: "Cuadrícula" }
                ]

                Chip {
                    required property var modelData
                    text: modelData.label
                    selected: Config.wallpaperPicker === modelData.style
                    onClicked: Config.setWallpaperPicker(modelData.style)
                }
            }
        }

        SwitchRow {
            icon: Theme.iAnimation
            text: "Animaciones"
            checked: animations.boolValue
            onToggled: animations.set(!animations.boolValue)
        }
        SwitchRow {
            icon: Theme.iBlur
            text: "Desenfoque"
            checked: blur.boolValue
            onToggled: blur.set(!blur.boolValue)
        }
        // Fondo de la barra y los paneles semitransparente; el desenfoque de detrás
        // depende del de Hyprland (la opción de arriba)
        SwitchRow {
            icon: Theme.iOpacity
            text: "Barra y paneles translúcidos"
            checked: Config.translucent
            onToggled: Config.setTranslucent(!Config.translucent)
        }
        SwitchRow {
            icon: Theme.iShadow
            text: "Sombras"
            checked: shadows.boolValue
            onToggled: shadows.set(!shadows.boolValue)
        }

        // Bordes: clic o arrastre para fijar el tamaño, y reset al valor por defecto
        SliderRow {
            icon: Theme.iGaps
            text: "Interiores"
            value: gapsIn.intValue / gapsIn.max
            valueText: gapsIn.intValue
            resettable: gapsIn.intValue !== gapsIn.fallback
            onMoved: f => gapsIn.set(f * gapsIn.max)
            onReset: gapsIn.set(gapsIn.fallback)
        }
        SliderRow {
            icon: Theme.iGaps
            text: "Exteriores"
            value: gapsOut.intValue / gapsOut.max
            valueText: gapsOut.intValue
            resettable: gapsOut.intValue !== gapsOut.fallback
            onMoved: f => gapsOut.set(f * gapsOut.max)
            onReset: gapsOut.set(gapsOut.fallback)
        }
    }

    // Qué se ve en la barra: cada módulo es una opción; marcada = en la barra.
    // Los ajustes (el engranaje) no se pueden quitar.
    Section {
        title: "Módulos de la barra"
        contentSpacing: 8

        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 2
            spacing: 6

            Repeater {
                model: Config.barModules

                Chip {
                    required property var modelData
                    icon: modelData.icon
                    text: modelData.label
                    selected: Config.barShows(modelData.key)
                    onClicked: Config.toggleBarModule(modelData.key)
                }
            }
        }
    }

    // Qué pasa tras unos minutos sin usar el equipo (ver services/Idle.qml)
    Section {
        title: "Inactividad"
        contentSpacing: 8

        IdleRow {
            what: "lock"
            icon: Theme.iLock
            text: "Bloquear"
        }
        IdleRow {
            what: "screenOff"
            icon: Theme.iMonitor
            text: "Apagar pantallas"
        }
        IdleRow {
            what: "suspend"
            icon: Theme.iSleep
            text: "Suspender"
        }
    }

    // Espacio para que las acciones queden al pie del panel
    Item { Layout.fillHeight: true }

    // --- Acciones ---
    RowLayout {
        spacing: 8

        TextButton {
            Layout.fillWidth: true
            icon: Theme.iLock
            text: "Bloquear"
            onClicked: {
                Config.close();
                Lock.lock();
            }
        }
        TextButton {
            Layout.fillWidth: true
            icon: Theme.iSleep
            text: "Suspender"
            onClicked: {
                Config.close();
                Quickshell.execDetached(["systemctl", "suspend"]);
            }
        }
    }

    // --- Componentes del panel ---

    // Fila que abre otra ventana: icono, texto y una flecha
    // Mismo alto que las filas con interruptor; el resaltado sobresale un poco
    component NavRow: Item {
        id: nav
        property string icon
        property string text
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 24

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: -4
            anchors.bottomMargin: -4
            radius: Theme.radiusSmall
            color: navMouse.containsMouse ? Theme.surface : "transparent"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 4
            spacing: 10

            Icon {
                text: nav.icon
                color: Theme.subtext
            }
            Label {
                Layout.fillWidth: true
                text: nav.text
            }
            Icon {
                text: Theme.iChevronRight
                color: Theme.subtext
            }
        }
        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.clicked()
        }
    }

    // Acción por inactividad: icono, texto, minutos (‹ 5 min ›) e interruptor.
    // Los minutos se atenúan si está desactivada.
    component IdleRow: RowLayout {
        id: idle
        required property string what
        property string icon
        property string text
        readonly property bool on: Idle[what + "Enabled"]

        Layout.leftMargin: 6
        Layout.rightMargin: 4
        spacing: 10

        Icon {
            text: idle.icon
            color: Theme.subtext
        }
        Label {
            Layout.fillWidth: true
            text: idle.text
        }
        RowLayout {
            spacing: 2
            opacity: idle.on ? 1 : 0.4

            CircleButton {
                icon: Theme.iChevronLeft
                size: 24
                iconSize: 14
                iconColor: Theme.subtext
                onClicked: Idle.step(idle.what, -1)
            }
            Label {
                Layout.preferredWidth: 52
                horizontalAlignment: Text.AlignHCenter
                text: Idle.label(Idle[idle.what + "Minutes"])
                color: Theme.subtext
                font.features: { "tnum": 1 }
            }
            CircleButton {
                icon: Theme.iChevronRight
                size: 24
                iconSize: 14
                iconColor: Theme.subtext
                onClicked: Idle.step(idle.what, 1)
            }
        }
        Switch {
            checked: idle.on
            onToggled: Idle.setEnabled(idle.what, !idle.on)
        }
    }

    // Ajuste con deslizador: icono, texto, barra, valor y botón de restablecer
    // (siempre en su sitio; apagado si ya está en el valor por defecto)
    component SliderRow: RowLayout {
        id: row
        property string icon
        property string text
        property real value
        property string valueText
        property int valueWidth: 26
        property color color: Theme.primary
        property bool dimmed: false
        property bool resettable: false
        signal moved(real fraction)
        signal reset()

        Layout.leftMargin: 6
        Layout.rightMargin: 4
        spacing: 10

        Icon {
            visible: row.icon !== ""
            text: row.icon
            color: Theme.subtext
        }
        Label {
            text: row.text
            color: row.icon !== "" ? Theme.text : Theme.subtext
        }
        Slider {
            Layout.fillWidth: true
            value: row.value
            color: row.color
            opacity: row.dimmed ? 0.5 : 1
            onMoved: f => row.moved(f)
        }
        Label {
            Layout.preferredWidth: row.valueWidth
            text: row.valueText
            color: Theme.subtext
        }
        CircleButton {
            enabled: row.resettable
            icon: Theme.iRestore
            size: 24
            onClicked: row.reset()
        }
    }
}
