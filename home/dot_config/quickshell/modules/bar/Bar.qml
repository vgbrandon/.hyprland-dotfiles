import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import qs.components.base
import qs.components.design
import qs.modules.calendar
import qs.modules.github
import qs.modules.kblayout
import qs.modules.media
import qs.modules.network
import qs.modules.servers
import qs.modules.system
import qs.modules.updates
import qs.services

// Barra (diseño Prisma, ver docs/prisma.md): de Mica, pegada a un borde de lado a
// lado, con los elementos sueltos sobre ella. Arriba, abajo o en un lateral (Ajustes →
// Barra); en los laterales va en columna y sin lo que no cabe (títulos, CPU y RAM).
//   Inicio: lanzador, escritorios y ventana activa
//   Centro: lo que suena y la hora (clic = calendario)
//   Final: CPU y RAM, herramientas, bandeja, estado del sistema, volumen y energía
PanelWindow {
    id: bar

    readonly property string edge: Config.barPosition
    readonly property bool vertical: Config.barVertical
    // Barra lateral en un monitor bajo: botones más pequeños y menos escritorios
    readonly property bool compact: vertical && height < 900
    // Barra horizontal en un monitor estrecho: sin el título de la ventana
    readonly property bool narrow: !vertical && width < 1600
    readonly property int btn: compact ? 24 : 28

    anchors {
        top: edge !== "bottom"
        bottom: edge !== "top"
        left: edge !== "right"
        right: edge !== "left"
    }
    implicitHeight: Theme.barHeight
    implicitWidth: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "quickshell:bar"

    // Todo el contenido: se desliza fuera de su borde al cambiar de posición
    Item {
        id: content
        anchors.fill: parent
        transform: Translate {
            x: Config.barHide * (bar.edge === "left" ? -bar.width : bar.edge === "right" ? bar.width : 0)
            y: Config.barHide * (bar.edge === "top" ? -bar.height : bar.edge === "bottom" ? bar.height : 0)
        }

        // Mica: poco transparente, con el tinte del fondo (Hyprland desenfoca detrás)
        Rectangle {
            anchors.fill: parent
            color: Design.alpha(Design.micaTint, Design.micaOpacity)
        }
        // Canto hacia el escritorio
        Rectangle {
            x: bar.edge === "left" ? parent.width - 1 : 0
            y: bar.edge === "top" ? parent.height - 1 : 0
            width: bar.vertical ? 1 : parent.width
            height: bar.vertical ? parent.height : 1
            color: Design.border
        }

        // --- Inicio (izquierda / arriba) ---
        GridLayout {
            id: left
            // Posición calculada (no anclajes: al cambiar de lado, Qt deja anclajes colgados)
            x: bar.vertical ? Math.round((parent.width - width) / 2) : 8
            y: bar.vertical ? 8 : Math.round((parent.height - height) / 2)
            columns: bar.vertical ? 1 : -1
            rowSpacing: 8
            columnSpacing: 8

            BarIcon {
                Layout.alignment: Qt.AlignCenter
                icon: Theme.iLogo
                onClicked: Launcher.toggle()
            }
            Workspaces {
                Layout.alignment: Qt.AlignCenter
                screen: bar.screen
                vertical: bar.vertical
                shown: bar.compact ? 6 : 8
                cell: bar.compact ? 24 : 28
                thickness: bar.compact ? 24 : 26
            }
            // Título de la ventana activa (no cabe en monitores estrechos ni en los laterales)
            Txt {
                visible: !bar.narrow && !bar.vertical
                Layout.leftMargin: 6
                Layout.maximumWidth: 300
                text: activeWin.title
                textStyle: Design.label
                color: Design.onSurfaceVariant
            }
        }

        // --- Centro (centrado, sin pisar los extremos) ---
        GridLayout {
            id: center
            x: bar.vertical ? Math.round((parent.width - width) / 2)
                : Math.round(Math.max(left.x + left.width + 16, Math.min((parent.width - width) / 2, right.x - width - 16)))
            y: !bar.vertical ? Math.round((parent.height - height) / 2)
                : Math.round(Math.max(left.y + left.height + 16, Math.min((parent.height - height) / 2, right.y - height - 16)))
            columns: bar.vertical ? 1 : -1
            rowSpacing: 8
            columnSpacing: 14

            // Lo que suena: play/pausa y título (clic = panel). En un lateral, solo el botón
            GridLayout {
                id: media
                Layout.alignment: Qt.AlignCenter
                visible: Media.player !== null && !bar.compact
                columns: bar.vertical ? 1 : -1
                columnSpacing: 6

                IconBtn {
                    Layout.alignment: Qt.AlignCenter
                    icon: Media.isPlaying ? Theme.iPause : Theme.iPlay
                    size: bar.btn - 2
                    iconSize: 15
                    checked: Media.isPlaying
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    // En un lateral, clic derecho = panel
                    onClicked: button => {
                        if (button === Qt.RightButton) mediaPanel.toggle();
                        else Media.togglePlaying();
                    }
                }
                HoverBox {
                    id: mediaTitle
                    visible: !bar.vertical
                    implicitWidth: mediaText.implicitWidth + 16
                    Layout.maximumWidth: (bar.narrow ? 120 : 220) + 16

                    Txt {
                        id: mediaText
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        text: Media.artist ? `${Media.title} · ${Media.artist}` : Media.title
                        textStyle: Design.label
                        color: Design.onSurfaceVariant
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mediaPanel.toggle()
                    }
                    MediaPanel {
                        id: mediaPanel
                        player: Media.player
                        anchorItem: media
                    }
                    Connections {
                        target: Media
                        function onPanelRequested() {
                            if (Media.player) mediaPanel.toggleOnMainScreen();
                        }
                    }
                }
            }

            // Hora · fecha (clic = calendario). En un lateral, horas sobre minutos
            Rectangle {
                id: clockBox
                Layout.alignment: Qt.AlignCenter
                implicitWidth: bar.vertical ? bar.btn : clockText.implicitWidth + 20
                implicitHeight: bar.vertical ? clockText.implicitHeight + 10 : 26
                radius: Design.radiusSm - 2
                color: clockMouse.containsMouse ? Design.hoverLayer : "transparent"

                SystemClock {
                    id: clock
                    precision: SystemClock.Minutes
                }
                Txt {
                    id: clockText
                    anchors.centerIn: parent
                    // Fecha en español aunque el sistema esté en inglés
                    text: bar.vertical ? Qt.formatDateTime(clock.date, "hh\nmm")
                        : Qt.formatDateTime(clock.date, "hh:mm") + "  ·  " + Qt.locale("es_ES").toString(clock.date, "dddd d MMM")
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 0.9
                    textStyle: Design.label
                    font.features: { "tnum": 1 }
                }
                MouseArea {
                    id: clockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calendar.toggle()
                }
                CalendarPanel {
                    id: calendar
                    anchorItem: clockBox
                    today: clock.date
                }
            }
        }

        // --- Final (derecha / abajo) ---
        GridLayout {
            id: right
            x: bar.vertical ? Math.round((parent.width - width) / 2) : parent.width - width - 8
            y: bar.vertical ? parent.height - height - 8 : Math.round((parent.height - height) / 2)
            columns: bar.vertical ? 1 : -1
            rowSpacing: bar.compact ? 0 : 2
            columnSpacing: 2

            // Centra cada elemento en su celda (en columna, si no, quedan a un lado)
            Component.onCompleted: {
                for (const child of children)
                    child.Layout.alignment = Qt.AlignCenter;
            }

            // CPU y RAM (clic = panel del sistema; no caben en un lateral)
            Rectangle {
                id: res
                visible: !bar.vertical
                implicitWidth: resRow.implicitWidth + 16
                implicitHeight: 26
                radius: Design.radiusSm - 2
                color: resMouse.containsMouse ? Design.hoverLayer : "transparent"

                RowLayout {
                    id: resRow
                    anchors.centerIn: parent
                    spacing: 5
                    Icon { text: Theme.iCpu; color: Design.onSurfaceVariant; font.pixelSize: 14 }
                    Txt { text: SystemStats.cpu; textStyle: Design.label; font.features: { "tnum": 1 } }
                    Icon { Layout.leftMargin: 6; text: Theme.iRam; color: Design.onSurfaceVariant; font.pixelSize: 14 }
                    Txt { text: SystemStats.ram; textStyle: Design.label; font.features: { "tnum": 1 } }
                }
                MouseArea {
                    id: resMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sysPanel.toggle()
                }
                SystemPanel {
                    id: sysPanel
                    anchorItem: res
                }
                Connections {
                    target: SystemStats
                    function onPanelRequested() {
                        sysPanel.toggleOnMainScreen();
                    }
                }
            }

            Gap {}

            // Herramientas
            BarIcon { icon: Theme.iImage; onClicked: Wallpaper.toggle() }
            BarIcon { icon: Theme.iPicker; onClicked: ColorPicker.pick() }
            BarIcon { icon: Theme.iClipboard; onClicked: Clipboard.toggle() }
            // Grabación y pomodoro (con su menú y su panel)
            HoverBox {
                implicitWidth: bar.vertical ? bar.btn : Math.max(bar.btn, record.implicitWidth + 12)
                implicitHeight: bar.vertical ? Math.max(bar.btn, record.implicitHeight + 10) : bar.btn
                RecordButton {
                    id: record
                    anchors.fill: parent
                }
            }
            BarIcon {
                icon: Theme.iCamera
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: button => button === Qt.RightButton ? Screenshot.screenNow() : Screenshot.open()
            }
            HoverBox {
                implicitWidth: bar.vertical ? bar.btn : Math.max(bar.btn, pomodoro.implicitWidth + 12)
                implicitHeight: bar.vertical ? Math.max(bar.btn, pomodoro.implicitHeight + 10) : bar.btn
                PomodoroButton {
                    id: pomodoro
                    anchors.fill: parent
                }
            }
            BarIcon {
                enabled: NightLight.available
                icon: NightLight.enabled ? Theme.iNight : Theme.iSun
                checked: NightLight.enabled
                onClicked: NightLight.toggle()
            }

            Gap {}

            // Bandeja del sistema
            Repeater {
                model: SystemTray.items.values

                Item {
                    id: trayItem
                    required property SystemTrayItem modelData
                    Layout.alignment: Qt.AlignCenter
                    implicitWidth: bar.btn
                    implicitHeight: bar.btn

                    Rectangle {
                        anchors.fill: parent
                        radius: Design.radiusSm
                        color: trayMouse.containsMouse ? Design.hoverLayer : "transparent"
                    }
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 16
                        source: trayItem.modelData.icon
                        opacity: trayItem.modelData.status === Status.Passive ? 0.6 : 1
                    }
                    Rectangle {
                        visible: trayItem.modelData.status === Status.NeedsAttention
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 4
                        width: 6
                        height: 6
                        radius: 3
                        color: Design.accent
                    }
                    MouseArea {
                        id: trayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: e => {
                            const item = trayItem.modelData;
                            if (e.button === Qt.MiddleButton) item.secondaryActivate();
                            else if (e.button === Qt.RightButton || item.onlyMenu) bar.showTrayMenu(trayItem);
                            else item.activate();
                        }
                        onWheel: e => trayItem.modelData.scroll(e.angleDelta.y, false)
                    }
                }
            }

            // Actualizaciones (de blanco a amarillo según cuántas haya)
            BarIcon {
                id: updatesIcon
                icon: Theme.iPacman
                iconColor: Updates.totalColor()
                onClicked: updatesPanel.toggle()
                UpdatesPanel {
                    id: updatesPanel
                    anchorItem: updatesIcon
                }
            }

            // Teclado: clic = distribuciones, clic derecho = la siguiente
            BarIcon {
                id: kbIcon
                icon: Theme.iKeyboard
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: button => button === Qt.RightButton ? KeyboardLayout.next() : kbPanel.toggle()
                LayoutPanel {
                    id: kbPanel
                    anchorItem: kbIcon
                }
                Connections {
                    target: KeyboardLayout
                    function onPanelRequested() {
                        kbPanel.toggleOnMainScreen();
                    }
                }
            }

            // Red: clic = Wi-Fi, clic derecho = encender/apagar
            BarIcon {
                id: netIcon
                readonly property bool wiredUp: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)
                readonly property var wifiNet: Networking.devices.values.find(d => d.type === DeviceType.Wifi)?.networks.values.find(n => n.connected) ?? null
                icon: {
                    if (wiredUp) return Theme.iEthernet;
                    if (wifiNet) {
                        const v = wifiNet.signalStrength > 1 ? wifiNet.signalStrength / 100 : wifiNet.signalStrength;
                        return v > 0.75 ? Theme.iWifi4 : v > 0.5 ? Theme.iWifi3 : v > 0.25 ? Theme.iWifi2 : Theme.iWifi1;
                    }
                    return Networking.wifiEnabled ? Theme.iNoNet : Theme.iWifiOff;
                }
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: button => {
                    if (button === Qt.RightButton) Networking.wifiEnabled = !Networking.wifiEnabled;
                    else wifiPanel.toggle();
                }
                WifiPanel {
                    id: wifiPanel
                    anchorItem: netIcon
                }
            }

            // Bluetooth: clic = panel, clic derecho = encender/apagar
            BarIcon {
                id: btIcon
                readonly property BluetoothAdapter bt: Bluetooth.defaultAdapter
                readonly property bool connected: bt?.devices.values.some(d => d.connected) ?? false
                visible: bt !== null
                icon: !bt?.enabled ? Theme.iBtOff : connected ? Theme.iBtOn : Theme.iBt
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: button => button === Qt.RightButton ? btPanel.setPower(!btPanel.on) : btPanel.toggle()
                BluetoothPanel {
                    id: btPanel
                    anchorItem: btIcon
                }
            }

            // Servidores locales (solo si hay alguno)
            BarIcon {
                id: serversIcon
                visible: LocalServers.servers.length > 0
                icon: Theme.iServer
                iconColor: Design.accent
                onClicked: serversPanel.toggle()
                ServersPanel {
                    id: serversPanel
                    anchorItem: serversIcon
                }
                Connections {
                    target: LocalServers
                    function onPanelRequested() {
                        serversPanel.toggleOnMainScreen();
                    }
                }
            }

            // GitHub
            BarIcon {
                id: ghIcon
                icon: Theme.iGithub
                checked: GitHub.loggingIn
                onClicked: ghPanel.toggle()
                GitHubPanel {
                    id: ghPanel
                    anchorItem: ghIcon
                }
                Connections {
                    target: GitHub
                    function onPanelRequested() {
                        ghPanel.toggleOnMainScreen();
                    }
                }
            }

            // Asistente de IA (logo de OpenCode): de color mientras trabaja
            Rectangle {
                implicitWidth: bar.btn
                implicitHeight: bar.btn
                radius: Design.radiusSm
                color: AI.busy ? Design.tonal : aiMouse.containsMouse ? Design.hoverLayer : "transparent"
                OpenCodeLogo {
                    anchors.centerIn: parent
                    size: 14
                    color: AI.permissions.length > 0 ? Design.warning : AI.busy ? Design.onTonal : Design.onSurfaceVariant
                }
                MouseArea {
                    id: aiMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AI.toggle()
                }
            }

            Gap {}

            // Volumen: icono y número. Clic = silenciar, rueda = ±1 %
            Rectangle {
                id: volume
                readonly property PwNode sink: Pipewire.defaultAudioSink
                readonly property real level: sink?.audio?.volume ?? 0
                readonly property bool muted: (sink?.audio?.muted ?? false) || Math.round(level * 100) === 0
                visible: sink?.audio !== undefined
                implicitWidth: bar.vertical ? bar.btn : volRow.implicitWidth + 16
                implicitHeight: bar.vertical ? volRow.implicitHeight + 10 : bar.btn
                radius: Design.radiusSm
                color: volMouse.containsMouse ? Design.hoverLayer : "transparent"

                PwObjectTracker {
                    objects: [volume.sink]
                }
                GridLayout {
                    id: volRow
                    anchors.centerIn: parent
                    columns: bar.vertical ? 1 : -1
                    rowSpacing: 0
                    columnSpacing: 5
                    Icon {
                        Layout.alignment: Qt.AlignCenter
                        text: volume.muted ? Theme.iMuted : volume.level < 0.34 ? Theme.iVolumeLow : volume.level < 0.67 ? Theme.iVolumeMedium : Theme.iVolume
                        color: volume.muted ? Design.muted : Design.onSurfaceVariant
                        font.pixelSize: 16
                    }
                    Txt {
                        Layout.alignment: Qt.AlignCenter
                        text: Math.round(volume.level * 100)
                        textStyle: Design.label
                        color: volume.muted ? Design.muted : Design.onSurface
                        font.features: { "tnum": 1 }
                    }
                }
                MouseArea {
                    id: volMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Osd.quiet();
                        if (volume.sink?.audio) volume.sink.audio.muted = !volume.sink.audio.muted;
                    }
                    onWheel: e => {
                        Osd.quiet();
                        const v = volume.level + (e.angleDelta.y > 0 ? 0.01 : -0.01);
                        if (volume.sink?.audio) volume.sink.audio.volume = Math.max(0, Math.min(1, Math.round(v * 100) / 100));
                    }
                }
            }

            // Notificaciones, ajustes y energía
            BarIcon {
                icon: Notifs.dnd ? Theme.iBellOff : Notifs.count > 0 ? Theme.iBellBadge : Theme.iBell
                onClicked: Notifs.toggleCenter()
            }
            BarIcon { icon: Theme.iSettings; onClicked: Config.toggle() }
            BarIcon { icon: Theme.iPower; onClicked: PowerMenu.toggle() }
        }
    }

    // Ventana activa de este monitor (o la primera del escritorio visible)
    QtObject {
        id: activeWin
        readonly property HyprlandWorkspace ws: Hyprland.monitorFor(bar.screen)?.activeWorkspace ?? null
        readonly property Toplevel active: ToplevelManager.activeToplevel
        readonly property Toplevel win: {
            if (!ws || ws.toplevels.values.length === 0) return null;
            if (active && active.screens.includes(bar.screen)) return active;
            return ws.toplevels.values[0].wayland ?? null;
        }
        readonly property string title: win ? win.title : "Escritorio"
    }

    // Menú de una app de la bandeja, junto a la barra
    function showTrayMenu(icon) {
        const item = icon.modelData;
        if (!item.hasMenu) return;
        const p = icon.mapToItem(null, 0, 0);
        const x = bar.edge === "left" ? bar.width : bar.edge === "right" ? 0 : Math.round(p.x);
        const y = bar.edge === "top" ? bar.height : bar.edge === "bottom" ? 0 : Math.round(p.y);
        item.display(bar, x, y);
    }

    // Botón de icono de la barra
    component BarIcon: IconBtn {
        Layout.alignment: Qt.AlignCenter
        size: bar.btn
        iconSize: bar.compact ? 15 : 16
    }

    // Separación entre grupos
    component Gap: Item {
        implicitWidth: bar.vertical ? 1 : 10
        implicitHeight: bar.vertical ? (bar.compact ? 4 : 8) : 1
    }
}
