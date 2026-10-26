import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// --- Pantalla ---
RowLayout {
    spacing: 16

    Box {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "Imagen de la pantalla"
        subtitle: "Imagen o GIF de tu carpeta Imágenes (hasta 64 fotogramas)"

        RowLayout {
            Layout.fillWidth: true
            spacing: 18

            // Vista previa: la elegida, o la que tiene ahora
            ColumnLayout {
                spacing: 8
                Rectangle {
                    implicitWidth: 192
                    implicitHeight: 192
                    radius: Design.radiusMd
                    color: "#000000"
                    border.color: Design.border
                    clip: true
                    readonly property string file: AulaKeyboard.pickedImage !== "" ? AulaKeyboard.pickedImage : (AulaKeyboard.screen.file ?? "")
                    AnimatedImage {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: parent.file !== "" ? "file://" + parent.file : ""
                        fillMode: ({ fit: Image.PreserveAspectFit, fill: Image.PreserveAspectCrop, stretch: Image.Stretch })[AulaKeyboard.pickedFit] ?? Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Txt {
                        anchors.centerIn: parent
                        visible: parent.file === ""
                        text: "De fábrica"
                        color: Design.muted
                    }
                }
                Txt {
                    Layout.alignment: Qt.AlignHCenter
                    text: AulaKeyboard.pickedImage !== "" ? "Sin enviar" : "En el teclado"
                    textStyle: Design.caption
                    color: AulaKeyboard.pickedImage !== "" ? Design.warning : Design.onSurfaceVariant
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 12
                SegRow {
                    label: "Encaje"
                    options: ["Rellenar", "Ajustar", "Estirar"]
                    current: Math.max(0, ["fill", "fit", "stretch"].indexOf(AulaKeyboard.pickedFit))
                    onPicked: i => AulaKeyboard.pickedFit = ["fill", "fit", "stretch"][i]
                }
                Btn {
                    kind: "filled"
                    icon: Theme.iSend
                    text: "Enviar a la pantalla"
                    enabled: AulaKeyboard.task === "" && (AulaKeyboard.pickedImage !== "" || (AulaKeyboard.screen.file ?? "") !== "")
                    onClicked: {
                        AulaKeyboard.setScreen(AulaKeyboard.pickedImage !== "" ? AulaKeyboard.pickedImage : AulaKeyboard.screen.file, AulaKeyboard.pickedFit);
                        AulaKeyboard.pickedImage = "";
                    }
                }
                // Progreso de la subida
                ColumnLayout {
                    visible: AulaKeyboard.uploadProgress >= 0
                    Layout.fillWidth: true
                    spacing: 6
                    Txt {
                        text: ({ clear: "Borrando la memoria…", upload: "Enviando… " + Math.round(AulaKeyboard.uploadProgress * 100) + " %",
                            commit: "Guardando en el teclado…" })[AulaKeyboard.uploadStep] ?? "Preparando…"
                        textStyle: Design.label
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        radius: 3
                        color: Design.sunken
                        Rectangle {
                            width: parent.width * Math.max(0, AulaKeyboard.uploadProgress)
                            height: parent.height
                            radius: 3
                            color: Design.accent
                            Behavior on width { NumberAnimation { duration: 150 } }
                            AccentFill { glow: true }
                        }
                    }
                }
                Txt {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: "Antes de cada envío se borra la memoria de imágenes, como hace el programa oficial; un GIF largo tarda (unos 140 ms por cada 4 KB)."
                    textStyle: Design.caption
                    color: Design.onSurfaceVariant
                }
            }
        }

        // Imágenes para elegir
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Design.radiusMd
            color: Design.sunken
            border.color: Design.border

            GridView {
                id: grid
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                cellWidth: Math.floor(width / 7)
                cellHeight: cellWidth
                boundsBehavior: Flickable.StopAtBounds
                model: AulaKeyboard.images

                delegate: Item {
                    required property string modelData
                    width: grid.cellWidth
                    height: grid.cellHeight
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: Design.radiusSm
                        color: Design.surface1
                        clip: true
                        border.width: AulaKeyboard.pickedImage === parent.modelData ? 2 : 0
                        border.color: Design.accent
                        Image {
                            anchors.fill: parent
                            anchors.margins: AulaKeyboard.pickedImage === parent.parent.modelData ? 2 : 0
                            source: "file://" + parent.parent.modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 160
                            sourceSize.height: 160
                        }
                        Rectangle {
                            visible: parent.parent.modelData.toLowerCase().endsWith(".gif")
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 4
                            implicitWidth: 28
                            implicitHeight: 16
                            radius: 4
                            color: Design.alpha("#000000", 0.6)
                            Txt { anchors.centerIn: parent; text: "GIF"; textStyle: Design.caption; color: "#ffffff" }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AulaKeyboard.pickedImage = parent.parent.modelData
                        }
                    }
                }
            }
            Txt {
                anchors.centerIn: parent
                visible: AulaKeyboard.images.length === 0
                text: "No hay imágenes en ~/Pictures"
                color: Design.muted
            }
        }
    }

    ColumnLayout {
        Layout.preferredWidth: 320
        Layout.fillHeight: true
        spacing: 16

        Box {
            Layout.fillWidth: true
            title: "Reloj del teclado"
            subtitle: AulaKeyboard.clock.lastSync
                ? "Sincronizado a las " + Qt.formatTime(new Date(AulaKeyboard.clock.lastSync * 1000), "hh:mm") : "Sin sincronizar"
            Txt {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "El teclado guarda su propia hora. Se sincroniza solo al conectarlo y cada hora."
                textStyle: Design.caption
                color: Design.onSurfaceVariant
            }
            ToggleRow {
                text: "Formato de 12 horas"
                checked: AulaKeyboard.clock.twelveHour ?? false
                onToggled: AulaKeyboard.syncClock(!checked)
            }
            Btn {
                kind: "tonal"
                icon: Theme.iTimer
                text: "Sincronizar ahora"
                small: true
                onClicked: AulaKeyboard.syncClock()
            }
        }
        Box {
            Layout.fillWidth: true
            title: "Memoria de imágenes"
            Txt {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "Si la pantalla muestra parpadeos o colores raros, bórrala y vuelve a enviar la imagen. También quita la animación de fábrica."
                textStyle: Design.caption
                color: Design.onSurfaceVariant
            }
            DangerBtn {
                action: "clear"
                text: "Borrar la memoria"
                onConfirmed: AulaKeyboard.clearScreen()
            }
        }
        Box {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Formato"
            Txt {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "Cada fotograma se guarda en RGB565 de 128 × 128. Los GIF conservan la duración de cada fotograma (hasta 64)."
                textStyle: Design.caption
                color: Design.onSurfaceVariant
            }
        }
    }
}
