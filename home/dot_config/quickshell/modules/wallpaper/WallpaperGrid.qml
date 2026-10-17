import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.design
import qs.services

// Selector de fondos a pantalla completa (Ajustes → Selector de fondos): todos los
// fondos en una cuadrícula grande, con buscador por nombre. Escribir = buscar; flechas
// o Ctrl + h/j/k/l (las letras solas van al buscador) = moverse; Enter o clic = usarlo;
// Esc = cerrar. Lógica en services/Wallpaper.qml.
PickerLayer {
    id: win

    open: Wallpaper.open && Config.wallpaperPicker === "grid"
    dim: 0.85

    // Fondos que coinciden con la búsqueda
    readonly property var shown: {
        const q = search.text.trim().toLowerCase();
        return q === "" ? Wallpaper.files : Wallpaper.files.filter(f => f.split("/").pop().toLowerCase().includes(q));
    }

    onOpenChanged: {
        search.text = "";
        if (open) {
            center();
            search.focusInput();
        }
    }
    // Señala el fondo actual (al abrir y cuando llega la lista, que se relee al abrir)
    function center() {
        grid.currentIndex = Math.max(0, shown.indexOf(Wallpaper.current));
        grid.positionViewAtIndex(grid.currentIndex, GridView.Center);
    }
    Connections {
        target: Wallpaper
        function onFilesChanged() {
            if (win.open) Qt.callLater(win.center);
        }
    }

    function use(i) {
        if (i >= 0 && i < shown.length) Wallpaper.choose(shown[i]);
    }

    ColumnLayout {
        id: page
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 60
        anchors.bottomMargin: 40
        width: grid.columns * grid.cellWidth
        spacing: 20

        // Cabecera: título, cuántos y buscador
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 0
                Txt {
                    text: "Fondos de pantalla"
                    textStyle: Design.title
                }
                Txt {
                    text: win.shown.length === 1 ? "1 fondo" : `${win.shown.length} fondos`
                    textStyle: Design.caption
                    color: Design.onSurfaceVariant
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Field {
                id: search
                implicitWidth: 400
                icon: Theme.iSearch
                placeholder: "Buscar por nombre…  (Ctrl + h j k l para moverte)"
                onKeyPressed: e => {
                    const ctrl = e.modifiers & Qt.ControlModifier;
                    if (e.key === Qt.Key_Left || ctrl && e.key === Qt.Key_H) grid.moveCurrentIndexLeft();
                    else if (e.key === Qt.Key_Right || ctrl && e.key === Qt.Key_L) grid.moveCurrentIndexRight();
                    else if (e.key === Qt.Key_Up || ctrl && e.key === Qt.Key_K) grid.moveCurrentIndexUp();
                    else if (e.key === Qt.Key_Down || ctrl && e.key === Qt.Key_J) grid.moveCurrentIndexDown();
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) win.use(grid.currentIndex);
                    else if (e.key === Qt.Key_Escape) win.close();
                    else return;
                    e.accepted = true;
                }
                onTextChanged: grid.currentIndex = 0
            }
        }

        GridView {
            id: grid
            readonly property int columns: Math.max(2, Math.floor((win.width - 160) / cellWidth))

            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: 272
            cellHeight: 168
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: win.shown
            highlightMoveDuration: Design.normal

            delegate: Item {
                id: cell
                required property string modelData
                required property int index
                readonly property bool current: GridView.isCurrentItem

                width: grid.cellWidth
                height: grid.cellHeight

                WallpaperThumb {
                    anchors.fill: parent
                    anchors.margins: 12
                    file: cell.modelData
                    highlighted: cell.current
                    scale: cell.current ? 1.03 : 1
                    Behavior on scale { NumberAnimation { duration: Design.normal; easing.type: Design.easing } }
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: 12
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: grid.currentIndex = cell.index
                    onClicked: win.use(cell.index)
                }
            }
        }

        Txt {
            visible: win.shown.length === 0
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 40
            text: Wallpaper.files.length === 0 ? "No hay imágenes en " + Wallpaper.dir.replace(Quickshell.env("HOME"), "~") : "Ningún fondo con ese nombre"
            color: Design.onSurfaceVariant
        }
    }
}
