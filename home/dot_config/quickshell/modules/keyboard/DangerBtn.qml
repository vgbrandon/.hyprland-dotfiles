import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// Botón de algo que borra: el primer clic pide confirmación, el segundo lo hace
Btn {
    id: danger
    property string action
    signal confirmed()

    kind: "outline"
    small: true
    enabled: AulaKeyboard.task === ""
    text: AulaKeyboard.confirming === action ? "¿Seguro? Pulsa otra vez" : text
    onClicked: {
        if (AulaKeyboard.confirming === action) {
            AulaKeyboard.confirming = "";
            danger.confirmed();
        } else {
            AulaKeyboard.confirming = action;
            AulaKeyboard.confirmTimer.restart();
        }
    }
}
