import QtQuick
import QtQuick.Layouts
import qs.components.base
import qs.components.buttons
import qs.services

// Ajuste numérico: nombre, − valor +
//   Stepper { label: "Enfoque"; value: 25; unit: "min"; step: 5; onChanged: v => … }
RowLayout {
    id: stepper

    property string label
    property int value
    property string unit: ""
    property int step: 1
    signal changed(int v)

    spacing: 6

    Label {
        Layout.fillWidth: true
        text: stepper.label
    }
    CircleButton {
        icon: Theme.iMinus
        size: 28
        iconSize: 14
        filled: true
        onClicked: stepper.changed(stepper.value - stepper.step)
    }
    Label {
        Layout.preferredWidth: 52
        horizontalAlignment: Text.AlignHCenter
        text: stepper.unit ? `${stepper.value} ${stepper.unit}` : String(stepper.value)
        font.features: { "tnum": 1 }
    }
    CircleButton {
        icon: Theme.iPlus
        size: 28
        iconSize: 14
        filled: true
        onClicked: stepper.changed(stepper.value + stepper.step)
    }
}
