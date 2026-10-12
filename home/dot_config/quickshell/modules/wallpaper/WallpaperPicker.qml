import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components.base
import qs.components.containers
import qs.services

// Selector de fondos de pantalla (la lógica está en services/Wallpaper.qml)
//   quickshell ipc call wallpaper toggle
OverlayWindow {
    id: win

    open: Wallpaper.open
    onCloseRequested: Wallpaper.open = false
    namespace: "quickshell:wallpaper"

    onVisibleChanged: if (visible) grid.forceActiveFocus()

    PanelHeader {
        icon: Theme.iImage
        title: "Fondos de pantalla"
        subtitle: Wallpaper.dir.replace(Quickshell.env("HOME"), "~")
    }

    GridView {
        id: grid

        readonly property int columns: 3

        Layout.preferredWidth: columns * cellWidth
        implicitHeight: Math.max(1, Math.min(3, Math.ceil(count / columns))) * cellHeight
        cellWidth: 216
        cellHeight: 140
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationWraps: true
        model: Wallpaper.files
        visible: count > 0
        // La lista llega un momento después de abrir: selecciona el fondo actual
        onCountChanged: currentIndex = Math.max(0, Wallpaper.files.indexOf(Theme.wallpaper))

        Keys.onPressed: e => {
            if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) Wallpaper.choose(Wallpaper.files[currentIndex]);
            else return;
            e.accepted = true;
        }

        delegate: Item {
            id: cell
            required property string modelData
            required property int index
            readonly property bool selected: GridView.isCurrentItem
            readonly property bool active: modelData === Theme.wallpaper

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: Theme.radius
                color: cell.selected ? Theme.surfaceHigh : "transparent"
                border.color: cell.active ? Theme.primary : "transparent"
                border.width: 2

                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: Theme.radiusSmall
                    color: Theme.surface

                    Image {
                        anchors.fill: parent
                        source: "file://" + (Wallpaper.thumbs[cell.modelData] ?? cell.modelData)
                        sourceSize.width: 400
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                // Marca del fondo actual
                Rectangle {
                    visible: cell.active
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 12
                    width: 24
                    height: 24
                    radius: 12
                    color: Theme.primary

                    Icon {
                        anchors.centerIn: parent
                        text: Theme.iCheck
                        color: Theme.primaryFg
                        font.pixelSize: 16
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: grid.currentIndex = cell.index
                onClicked: Wallpaper.choose(cell.modelData)
            }
        }
    }

    Label {
        visible: grid.count === 0
        Layout.alignment: Qt.AlignHCenter
        Layout.margins: 20
        text: "No hay imágenes en " + Wallpaper.dir.replace(Quickshell.env("HOME"), "~")
        color: Theme.subtext
    }
}
