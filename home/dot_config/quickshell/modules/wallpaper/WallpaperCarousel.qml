import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.design
import qs.services

// Selector de fondos en carrusel (Ajustes → Selector de fondos): el señalado, grande en
// el centro; los vecinos, más pequeños y atenuados. Flechas, rueda o teclas de Vim
// (h/k anterior, l/j siguiente, g primero, G último) = moverse; Enter o clic en el del
// centro = usarlo; clic en otro = traerlo al centro; Esc o q = cerrar.
// Lógica en services/Wallpaper.qml.
PickerLayer {
    id: win

    open: Wallpaper.open && Config.wallpaperPicker === "carousel"
    dim: 0.8

    // El del centro (al que se va) y la posición que se ve, que se desliza hacia él: una
    // sola animación continua, así que pulsar rápido solo la alarga, sin saltos
    property int current: 0
    property real pos: current
    Behavior on pos {
        id: slide
        NumberAnimation { duration: Design.slow; easing.type: Easing.OutCubic }
    }
    readonly property int count: Wallpaper.files.length
    readonly property real bigWidth: Math.min(720, Math.round(width * 0.42))
    readonly property int gap: 24

    // Ancho, opacidad y posición (del centro de cada uno respecto al centro de la
    // pantalla) según la distancia al centro. En los enteros salen de las tablas; entre
    // medias se interpolan, para que todo cambie de forma continua al deslizarse.
    readonly property var sizes: [1, 0.52, 0.33, 0.22]
    readonly property var opacities: [1, 0.8, 0.5, 0.25, 0]
    function lerpAt(table, d) {
        const i = Math.min(Math.floor(d), table.length - 1);
        const j = Math.min(i + 1, table.length - 1);
        return table[i] + (table[j] - table[i]) * (d - Math.floor(d));
    }
    function sizeAt(d) {
        return bigWidth * lerpAt(sizes, Math.min(d, 3));
    }
    // Desplazamiento del vecino número k (entero): la mitad del central, más los anchos
    // y huecos de los que hay entre medias, más su propia mitad
    function stepOffset(k) {
        if (k === 0) return 0;
        let x = sizeAt(0) / 2;
        for (let i = 1; i < k; i++) x += gap + sizeAt(i);
        return x + gap + sizeAt(k) / 2;
    }
    function offsetAt(rel) {
        const a = Math.abs(rel);
        const k = Math.floor(a);
        const x = stepOffset(k) + (stepOffset(k + 1) - stepOffset(k)) * (a - k);
        return rel < 0 ? -x : x;
    }

    function move(d) {
        if (count > 0) current = Math.max(0, Math.min(count - 1, current + d));
    }
    function use(i) {
        if (i >= 0 && i < count) Wallpaper.choose(Wallpaper.files[i]);
    }
    // Al abrir (y cuando llega la lista, que se relee al abrir): en el fondo actual
    function center() {
        // Al abrir, directamente ahí (sin recorrer el carrusel): sin animación mientras
        // cambia (pos sigue enlazada a current, no se asigna)
        slide.enabled = false;
        current = Math.max(0, Wallpaper.files.indexOf(Wallpaper.current));
        Qt.callLater(() => slide.enabled = true);
    }
    onOpenChanged: if (open) {
        center();
        keys.forceActiveFocus();
    }
    Connections {
        target: Wallpaper
        function onFilesChanged() {
            if (win.open) win.center();
        }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            const k = e.key;
            if (k === Qt.Key_Left || k === Qt.Key_H || k === Qt.Key_K) win.move(-1);
            else if (k === Qt.Key_Right || k === Qt.Key_L || k === Qt.Key_J) win.move(1);
            // g = el primero, G (con Mayús) = el último
            else if (k === Qt.Key_G) win.move(e.modifiers & Qt.ShiftModifier ? win.count : -win.count);
            else if (k === Qt.Key_Home) win.move(-win.count);
            else if (k === Qt.Key_End) win.move(win.count);
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) win.use(win.current);
            else if (k === Qt.Key_Q) win.close();
            else return;
            e.accepted = true;
        }

        WheelHandler {
            onWheel: e => win.move(e.angleDelta.y < 0 || e.angleDelta.x < 0 ? 1 : -1)
        }
    }

    // Las miniaturas (solo se ven las cercanas al centro)
    Item {
        id: strip
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -30
        height: Math.round(win.bigWidth * 9 / 16)

        Repeater {
            model: Wallpaper.files

            Item {
                id: card
                required property string modelData
                required property int index
                // Distancia (con decimales mientras se desliza) al que se ve en el centro
                readonly property real rel: index - win.pos
                readonly property real distance: Math.abs(rel)
                readonly property bool centered: index === win.current

                visible: distance < 4
                // En píxeles enteros: con decimales la imagen se ve borrosa
                width: Math.round(win.sizeAt(distance))
                height: Math.round(width * 9 / 16)
                x: Math.round(strip.width / 2 + win.offsetAt(rel) - width / 2)
                y: Math.round((strip.height - height) / 2)
                z: 10 - distance
                opacity: win.lerpAt(win.opacities, Math.min(distance, 4))

                WallpaperThumb {
                    anchors.fill: parent
                    file: card.modelData
                    highlighted: card.centered
                    // La del centro, a resolución completa (la miniatura de la caché se ve borrosa)
                    full: card.distance < 1.5
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (card.centered) win.use(card.index);
                        else win.current = card.index;
                    }
                }
            }
        }
    }

    // Nombre, posición y ayuda
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: strip.bottom
        anchors.topMargin: 24
        spacing: 6

        Txt {
            Layout.alignment: Qt.AlignHCenter
            text: (Wallpaper.files[win.current] ?? "").split("/").pop()
            textStyle: Design.headline
        }
        Txt {
            Layout.alignment: Qt.AlignHCenter
            text: win.count === 0 ? "No hay imágenes en " + Wallpaper.dir.replace(Quickshell.env("HOME"), "~")
                : `${win.current + 1} de ${win.count}   ·   ← → o h l para moverte   ·   Enter para usarlo   ·   Esc o q para cerrar`
            textStyle: Design.caption
            color: Design.onSurfaceVariant
        }
    }
}
