import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.buttons
import qs.services

// Herramientas: fondos, selector de color, portapapeles, grabación, captura, pomodoro y luz nocturna.
// En la barra vertical también el volumen (icono y número), donde ocupa menos alto.
Pill {
    id: root

    IconButton {
        text: Theme.iImage
        onClicked: Wallpaper.toggle()
    }
    IconButton {
        text: Theme.iPicker
        onClicked: ColorPicker.pick()
    }
    IconButton {
        text: Theme.iClipboard
        onClicked: Clipboard.toggle()
    }

    // Grabación de pantalla (grabando: punto rojo con el tiempo)
    RecordButton {}

    // Captura: clic = selector, clic derecho = monitor completo al instante
    IconButton {
        text: Theme.iCamera
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: button => {
            if (button === Qt.RightButton) Screenshot.screenNow();
            else Screenshot.open();
        }
    }

    // Pomodoro: con una sesión en marcha muestra el tiempo restante
    PomodoroButton {}

    // Luz nocturna: clic = activar/desactivar (la intensidad, en el panel de ajustes)
    IconButton {
        enabled: NightLight.available
        text: NightLight.enabled ? Theme.iNight : Theme.iSun
        color: !NightLight.available ? Theme.dot : NightLight.enabled ? Theme.warm : Theme.text
        onClicked: NightLight.toggle()
    }

    // Barra vertical: el volumen va aquí dentro (icono y número), donde ocupa menos alto
    VolumePill {
        embedded: true
        active: root.vertical
        Layout.topMargin: 3
    }
}
