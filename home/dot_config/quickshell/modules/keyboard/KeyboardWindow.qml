import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.base
import qs.components.buttons
import qs.components.containers
import qs.components.controls
import qs.services

// Ventana del teclado AULA F75 Max (la lógica está en services/AulaKeyboard.qml):
// luces, pantalla y ajustes. Los cambios se aplican al momento.
//   quickshell ipc call keyboard toggle
OverlayWindow {
    id: win

    open: AulaKeyboard.open
    onCloseRequested: AulaKeyboard.close()
    namespace: "quickshell:keyboard"
    focusMode: WlrKeyboardFocus.OnDemand
    cardWidth: 720
    spacing: 14

    onVisibleChanged: if (visible) pictures.running = true

    // Imágenes y GIF de ~/Pictures (las más recientes primero) para la pantalla
    property var images: []
    Process {
        id: pictures
        command: ["sh", "-c", `find "$HOME/Pictures" -maxdepth 2 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.webp' \\) -printf '%T@ %p\\n' 2>/dev/null | sort -rn | cut -d' ' -f2- | head -60`]
        stdout: StdioCollector {
            onStreamFinished: win.images = this.text.split("\n").filter(l => l !== "")
        }
    }

    // Colores para las luces: el principal del tema y colores vivos (en los LED, los
    // tonos pastel del tema salen casi blancos)
    readonly property var swatches: [
        String(Theme.primary), "#ffffff", "#ff0000", "#ff6000", "#ffd000",
        "#00ff00", "#00ffd0", "#0060ff", "#8000ff", "#ff00a0"
    ]

    // --- Cabecera ---
    PanelHeader {
        icon: Theme.iKeyboard
        iconColor: Theme.primary
        title: "Teclado"
        subtitle: "AULA F75 Max"

        // Conexión
        Rectangle {
            implicitWidth: statusRow.implicitWidth + 20
            implicitHeight: 28
            radius: Design.radiusSm
            color: Theme.surface

            RowLayout {
                id: statusRow
                anchors.centerIn: parent
                spacing: 6
                Rectangle {
                    implicitWidth: 8
                    implicitHeight: 8
                    radius: 4
                    color: AulaKeyboard.connected ? Theme.pick("green", "#40e060") : Theme.dot
                }
                Label {
                    text: AulaKeyboard.busy ? "Aplicando…" : AulaKeyboard.connected ? "Conectado por cable" : "Desconectado"
                    color: Theme.subtext
                }
            }
        }
        CircleButton {
            icon: Theme.iClose
            iconColor: Theme.subtext
            onClicked: AulaKeyboard.close()
        }
    }

    // --- Pestañas ---
    RowLayout {
        spacing: 6

        Repeater {
            model: ["Luces", "Pantalla", "Ajustes"]

            Rectangle {
                id: tabButton
                required property string modelData
                required property int index
                readonly property bool selected: AulaKeyboard.tab === index

                Layout.fillWidth: true
                implicitHeight: 32
                radius: Theme.radiusSmall
                color: selected ? Theme.surfaceHigh : tabMouse.containsMouse ? Theme.surface : "transparent"

                Label {
                    anchors.centerIn: parent
                    text: tabButton.modelData
                    color: tabButton.selected ? Theme.text : Theme.subtext
                }
                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AulaKeyboard.tab = tabButton.index
                }
            }
        }
    }

    // Sin teclado: aviso en lugar de los controles
    Card {
        visible: !AulaKeyboard.connected
        Layout.fillWidth: true
        padding: 32
        spacing: 6

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: AulaKeyboard.available ? "Conecta el teclado por cable (USB-C)" : "Falta aulactl (~/.local/bin/aulactl)"
            font.pixelSize: 15
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "Por 2.4G o Bluetooth el teclado no deja cambiar su configuración"
            color: Theme.subtext
        }
    }

    // --- Luces ---
    ColumnLayout {
        visible: AulaKeyboard.connected && AulaKeyboard.tab === 0
        Layout.fillWidth: true
        spacing: 14

        // Efectos
        Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: AulaKeyboard.modes

                Chip {
                    required property var modelData
                    text: modelData.name
                    selected: AulaKeyboard.light.mode === modelData.id
                    onClicked: AulaKeyboard.setLight({ mode: modelData.id })
                }
            }
        }

        // Color (solo en los efectos que lo usan)
        Section {
            visible: AulaKeyboard.mode.color ?? false
            title: "Color"

            RowLayout {
                spacing: 8

                Repeater {
                    model: win.swatches

                    Rectangle {
                        id: swatch
                        required property string modelData
                        readonly property bool on: !AulaKeyboard.light.multicolor
                            && String(AulaKeyboard.light.color).toLowerCase() === modelData.toLowerCase()

                        implicitWidth: 30
                        implicitHeight: 30
                        radius: 15
                        color: modelData
                        border.color: on ? Theme.text : Theme.surfaceHigh
                        border.width: on ? 3 : 1

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AulaKeyboard.setLight({ color: swatch.modelData, multicolor: false })
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: "Multicolor"
                }
                Switch {
                    checked: AulaKeyboard.light.multicolor ?? false
                    onToggled: AulaKeyboard.setLight({ multicolor: !AulaKeyboard.light.multicolor })
                }
            }
        }

        RowLayout {
            visible: AulaKeyboard.light.mode !== "off"
            spacing: 24

            Chips {
                label: "Brillo"
                options: [1, 2, 3, 4, 5]
                value: AulaKeyboard.light.brightness
                onPicked: v => AulaKeyboard.setLight({ brightness: v })
            }
            Chips {
                visible: AulaKeyboard.mode.speed ?? false
                label: "Velocidad"
                options: [1, 2, 3, 4, 5]
                value: AulaKeyboard.light.speed
                onPicked: v => AulaKeyboard.setLight({ speed: v })
            }
            Chips {
                visible: AulaKeyboard.mode.direction ?? false
                label: "Dirección"
                options: ["right", "down", "left", "up"]
                format: v => ({ right: "→", down: "↓", left: "←", up: "↑" })[v]
                value: AulaKeyboard.light.direction
                onPicked: v => AulaKeyboard.setLight({ direction: v })
            }
        }
    }

    // --- Pantalla ---
    // Mientras se investiga el protocolo, solo un aviso
    Card {
        visible: AulaKeyboard.connected && AulaKeyboard.tab === 1 && !AulaKeyboard.screenReady
        Layout.fillWidth: true
        padding: 32
        spacing: 6

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "Pantalla en investigación"
            font.pixelSize: 15
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "La subida de imágenes aún no es fiable: falta capturar cómo lo hace el programa oficial."
            color: Theme.subtext
        }
    }

    ColumnLayout {
        visible: AulaKeyboard.connected && AulaKeyboard.tab === 1 && AulaKeyboard.screenReady
        Layout.fillWidth: true
        spacing: 14

        RowLayout {
            spacing: 16

            // Lo que hay ahora en la pantalla (lo último subido)
            Rectangle {
                implicitWidth: 128
                implicitHeight: 128
                radius: Theme.radiusSmall
                color: "black"
                clip: true

                AnimatedImage {
                    anchors.fill: parent
                    source: AulaKeyboard.screen.file ? "file://" + AulaKeyboard.screen.file : ""
                    fillMode: ({ fit: Image.PreserveAspectFit, fill: Image.PreserveAspectCrop, stretch: Image.Stretch })[AulaKeyboard.screen.fit ?? "fill"]
                    asynchronous: true
                }
                Label {
                    anchors.centerIn: parent
                    visible: !AulaKeyboard.screen.file
                    text: "De fábrica"
                    color: Theme.subtext
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: "Pantalla de 128 × 128"
                    font.pixelSize: 15
                }
                Label {
                    Layout.fillWidth: true
                    text: "Elige una imagen o un GIF (hasta 255 fotogramas) de tu carpeta Imágenes."
                    color: Theme.subtext
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                }

                Chips {
                    label: "Encaje"
                    options: ["fill", "fit", "stretch"]
                    format: v => ({ fill: "Rellenar", fit: "Ajustar", stretch: "Estirar" })[v]
                    value: AulaKeyboard.screen.fit ?? "fill"
                    onPicked: v => {
                        if (AulaKeyboard.screen.file) AulaKeyboard.setScreen(AulaKeyboard.screen.file, v);
                    }
                }

                // Progreso de la subida
                Slider {
                    visible: AulaKeyboard.uploadProgress >= 0
                    Layout.fillWidth: true
                    interactive: false
                    value: AulaKeyboard.uploadProgress
                }
            }
        }

        // Imágenes para elegir
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 196
            radius: Theme.radiusSmall
            color: Theme.surface

            GridView {
                id: grid
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                cellWidth: Math.floor(width / 8)
                cellHeight: cellWidth
                boundsBehavior: Flickable.StopAtBounds
                model: win.images

                delegate: Item {
                    id: thumb
                    required property string modelData
                    readonly property bool current: modelData === AulaKeyboard.screen.file

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: Theme.radiusSmall
                        color: Theme.surfaceHigh
                        border.color: thumb.current ? Theme.primary : thumbMouse.containsMouse ? Theme.text : "transparent"
                        border.width: 2
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: "file://" + thumb.modelData
                            sourceSize: Qt.size(160, 160)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        // Los GIF llevan una etiqueta
                        Rectangle {
                            visible: /\.gif$/i.test(thumb.modelData)
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 4
                            width: gifLabel.implicitWidth + 8
                            height: gifLabel.implicitHeight
                            radius: 4
                            color: Theme.withAlpha("black", 0.6)
                            Label {
                                id: gifLabel
                                anchors.centerIn: parent
                                text: "GIF"
                                font.pixelSize: 9
                            }
                        }
                    }
                    MouseArea {
                        id: thumbMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: AulaKeyboard.uploadProgress < 0
                        onClicked: AulaKeyboard.setScreen(thumb.modelData)
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                visible: win.images.length === 0
                text: "No hay imágenes en ~/Pictures"
                color: Theme.subtext
            }
        }
    }

    // --- Ajustes ---
    ColumnLayout {
        visible: AulaKeyboard.connected && AulaKeyboard.tab === 2
        Layout.fillWidth: true
        spacing: 14

        RowLayout {
            spacing: 24

            Chips {
                label: "Tiempo de respuesta (1 = más rápido)"
                options: [1, 2, 3, 4, 5]
                value: AulaKeyboard.settings.response
                onPicked: v => AulaKeyboard.setSettings({ response: v })
            }
            Chips {
                label: "Suspender tras"
                options: ["never", "1", "5", "30"]
                format: v => v === "never" ? "Nunca" : `${v} min`
                value: AulaKeyboard.settings.sleep
                onPicked: v => AulaKeyboard.setSettings({ sleep: v })
            }
        }

        Repeater {
            model: [
                { key: "winLock", label: "Bloquear la tecla Windows" },
                { key: "altF4Lock", label: "Bloquear Alt+F4" },
                { key: "altTabLock", label: "Bloquear Alt+Tab" },
                { key: "fnSwitch", label: "Intercambiar Fn (F1–F12 sin pulsar Fn)" }
            ]

            SwitchRow {
                required property var modelData

                text: modelData.label
                checked: AulaKeyboard.settings[modelData.key] ?? false
                onToggled: {
                    const changes = {};
                    changes[modelData.key] = !AulaKeyboard.settings[modelData.key];
                    AulaKeyboard.setSettings(changes);
                }
            }
        }

        // Reloj de la pantalla
        RowLayout {
            Layout.leftMargin: 6
            Layout.rightMargin: 4
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label {
                    text: "Reloj de la pantalla"
                }
                Label {
                    text: AulaKeyboard.clock.lastSync
                        ? `Sincronizado a las ${Qt.formatDateTime(new Date(AulaKeyboard.clock.lastSync * 1000), "hh:mm")} (se sincroniza solo al conectar y cada hora)`
                        : "Se sincroniza solo al conectar el teclado y cada hora"
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                }
            }
            Label {
                text: "12 h"
            }
            Switch {
                checked: AulaKeyboard.clock.twelveHour ?? false
                onToggled: AulaKeyboard.syncClock(!AulaKeyboard.clock.twelveHour)
            }
            TextButton {
                text: "Sincronizar"
                onClicked: AulaKeyboard.syncClock()
            }
        }
    }

    // Error del último cambio
    Label {
        visible: AulaKeyboard.error !== ""
        Layout.leftMargin: 4
        text: AulaKeyboard.error
        color: Theme.error
    }
    // Error del último cambio
    Label {
        visible: AulaKeyboard.error !== ""
        Layout.leftMargin: 6
        text: AulaKeyboard.error
        color: Theme.error
    }
}
