import QtQuick
import Quickshell
import Quickshell.Wayland

// Capa del fondo de un monitor: imagen con fundido al cambiar + reloj del escritorio.
// Va en la capa "Bottom", por encima del fondo de hyprpaper y debajo de las ventanas.
PanelWindow {
    id: win

    required property ShellScreen modelData
    readonly property string target: Wallpaper.current
    property Image front: null

    // Carga el fondo nuevo en la imagen de atrás; al estar lista, hace el fundido
    function load() {
        if (target === "") return;
        const back = front === imgA ? imgB : imgA;
        back.source = "file://" + target;
    }

    function reveal(img) {
        if (img === front || img.source.toString() !== "file://" + target) return;
        const prev = front;
        img.z = 1;
        if (prev) prev.z = 0;
        front = img;
        fade.target = img;
        fade.prev = prev;
        fade.restart();
    }

    onTargetChanged: load()
    Component.onCompleted: load()

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Theme.surface
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell:wallpaper"
    mask: Region {} // no captura clics

    NumberAnimation {
        id: fade
        property Image prev: null
        property: "opacity"
        from: 0
        to: 1
        duration: 700
        easing.type: Easing.InOutQuad
        // Libera la imagen anterior (las tuyas son muy grandes)
        onFinished: if (prev) prev.source = ""
    }

    Image {
        id: imgA
        anchors.fill: parent
        opacity: 0
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(win.modelData.width, win.modelData.height)
        asynchronous: true
        cache: false
        onStatusChanged: if (status === Image.Ready) win.reveal(imgA)
    }
    Image {
        id: imgB
        anchors.fill: parent
        opacity: 0
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(win.modelData.width, win.modelData.height)
        asynchronous: true
        cache: false
        onStatusChanged: if (status === Image.Ready) win.reveal(imgB)
    }

    DesktopClock {
        z: 2
    }
}
