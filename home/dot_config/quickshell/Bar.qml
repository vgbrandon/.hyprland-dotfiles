import QtQuick
import QtQuick.Layouts
import Quickshell

// Barra: arriba, abajo, a la izquierda o a la derecha (Config.barPosition,
// se elige en el panel de ajustes). En los lados los módulos van en columna.
PanelWindow {
    id: bar

    readonly property bool vertical: Config.barVertical

    anchors {
        top: Config.barPosition !== "bottom"
        bottom: Config.barPosition !== "top"
        left: Config.barPosition !== "right"
        right: Config.barPosition !== "left"
    }
    implicitHeight: Theme.barHeight
    implicitWidth: Theme.barHeight
    // El fondo va dentro del contenido para deslizarse con él
    color: "transparent"
    // Barra vertical en un monitor bajo: no cabe todo, se ocultan CPU y RAM
    readonly property bool compact: vertical && height < 900
    // Barra horizontal en un monitor estrecho: títulos más cortos para que quepa todo
    readonly property bool narrow: !vertical && width < 1600

    // Todo el contenido: se desliza fuera de su borde al cambiar de posición
    Item {
        id: content
        anchors.fill: parent
        transform: Translate {
            x: Config.barHide * (Config.barPosition === "left" ? -bar.width : Config.barPosition === "right" ? bar.width : 0)
            y: Config.barHide * (Config.barPosition === "top" ? -bar.height : Config.barPosition === "bottom" ? bar.height : 0)
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.barBg
        }

        // Inicio (izquierda / arriba): logo + ventana activa
        GridLayout {
            id: startGroup
            // Posición calculada (no anclajes: al cambiar de lado, Qt deja anclajes colgados)
            x: bar.vertical ? (parent.width - width) / 2 : 10
            y: bar.vertical ? 10 : (parent.height - height) / 2
            columns: bar.vertical ? 1 : -1
            rowSpacing: 10
            columnSpacing: 10

            Rectangle {
                implicitWidth: Theme.pillHeight
                implicitHeight: Theme.pillHeight
                radius: width / 2
                color: Theme.surface
                Icon {
                    anchors.centerIn: parent
                    text: Theme.iLogo
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Launcher.toggle()
                }
            }
            // El título de la ventana no cabe en la barra vertical
            ActiveWindow {
                visible: !bar.vertical
                maxWidth: bar.narrow ? 150 : 260
                screen: bar.screen
            }
        }

        // Centro: recursos, multimedia, workspaces, reloj
        GridLayout {
            id: centerGroup
            // Centrado, pero sin pisar los grupos de los extremos
            x: bar.vertical ? (parent.width - width) / 2
                : Math.max(startGroup.x + startGroup.width + 12, Math.min((parent.width - width) / 2, endGroup.x - width - 12))
            y: !bar.vertical ? (parent.height - height) / 2
                : Math.max(startGroup.y + startGroup.height + 12, Math.min((parent.height - height) / 2, endGroup.y - height - 12))
            columns: bar.vertical ? 1 : -1
            rowSpacing: bar.compact ? 4 : Theme.gap
            columnSpacing: Theme.gap

            Resources {
                Layout.alignment: Qt.AlignCenter
                compact: bar.compact
            }
            // Lo que esté sonando (cualquier app)
            MediaPill {
                Layout.alignment: Qt.AlignCenter
                compact: bar.compact
                titleWidth: bar.narrow ? 110 : 200
            }
            Workspaces {
                Layout.alignment: Qt.AlignCenter
                compact: bar.compact
                screen: bar.screen
            }
            ClockPill {
                Layout.alignment: Qt.AlignCenter
                compact: bar.compact
            }
        }

        // Final (derecha / abajo): actualizaciones, red, bluetooth, notificaciones y energía
        GridLayout {
            id: endGroup
            x: bar.vertical ? (parent.width - width) / 2 : parent.width - width - 16
            y: bar.vertical ? parent.height - height - (bar.compact ? 10 : 16) : (parent.height - height) / 2
            columns: bar.vertical ? 1 : -1
            rowSpacing: bar.compact ? 7 : bar.vertical ? 10 : 14
            columnSpacing: 14

            UpdatesPill {
                Layout.alignment: Qt.AlignCenter
                compact: bar.compact
            }
            StatusIcons {
                Layout.alignment: Qt.AlignCenter
                compact: bar.compact
            }
        }
    }
}
