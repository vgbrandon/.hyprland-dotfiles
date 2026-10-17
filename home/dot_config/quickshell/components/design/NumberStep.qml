import QtQuick
import QtQuick.Layouts
import qs.services

// Ajuste numérico: nombre a la izquierda y − valor + a la derecha (botones tonales)
//   NumberStep { label: "Enfoque"; value: 25; unit: "min"; step: 5; onChanged: v => … }
RowLayout {
    id: root

    property string label
    property int value
    property string unit: ""
    property int step: 1
    signal changed(int v)

    Layout.fillWidth: true
    spacing: 6

    Txt {
        Layout.fillWidth: true
        text: root.label
    }
    IconBtn {
        icon: Theme.iMinus
        kind: "tonal"
        size: 26
        iconSize: 14
        onClicked: root.changed(root.value - root.step)
    }
    Txt {
        Layout.preferredWidth: 54
        horizontalAlignment: Text.AlignHCenter
        text: root.unit ? `${root.value} ${root.unit}` : String(root.value)
        textStyle: Design.label
        font.features: { "tnum": 1 }
    }
    IconBtn {
        icon: Theme.iPlus
        kind: "tonal"
        size: 26
        iconSize: 14
        onClicked: root.changed(root.value + root.step)
    }
}
