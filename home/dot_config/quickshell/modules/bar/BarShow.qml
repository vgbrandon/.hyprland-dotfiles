import QtQuick
import QtQuick.Layouts
import qs.services

// Muestra u oculta un elemento de la barra según Ajustes → Módulos de la barra, con
// animación: el elemento crece (o se encoge) empujando a los de al lado y se funde.
// Va dentro del elemento; este usa "on" en su visible.
//   BarIcon { visible: showPicker.on; BarShow { id: showPicker; key: "picker" } }
Item {
    id: root

    required property string key
    property Item target: parent
    // 0 = oculto, 1 = en la barra
    property real progress: Config.barShows(key) ? 1 : 0
    readonly property bool on: progress > 0
    readonly property bool vertical: Config.barVertical

    visible: false
    Behavior on progress {
        NumberAnimation {
            duration: Design.normal
            easing.type: Design.easing
        }
    }

    onProgressChanged: apply()
    onVerticalChanged: apply()
    Component.onCompleted: apply()

    // Mientras se anima, el elemento ocupa una parte de su tamaño (a lo largo de la
    // barra) y recorta lo que sobra; quieto, vuelve a su tamaño normal
    function apply() {
        if (!target) return;
        const moving = progress < 1;
        target.clip = moving;
        target.opacity = progress;
        target.Layout.preferredWidth = moving && !vertical ? target.implicitWidth * progress : -1;
        target.Layout.preferredHeight = moving && vertical ? target.implicitHeight * progress : -1;
    }
}
