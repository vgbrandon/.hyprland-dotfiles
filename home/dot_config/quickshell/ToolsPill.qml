import QtQuick
import QtQuick.Layouts
import Quickshell

// Herramientas: fondos, selector de color, portapapeles, grabación, captura, pomodoro y luz nocturna.
// En la barra vertical también el volumen (icono y número), donde ocupa menos alto.
Pill {
    id: root

    // Fondos de pantalla
    Icon {
        text: Theme.iImage

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Wallpaper.toggle()
        }
    }

    // Selector de color
    Icon {
        text: Theme.iPicker

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ColorPicker.pick()
        }
    }

    // Historial del portapapeles
    Icon {
        text: Theme.iClipboard

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Clipboard.toggle()
        }
    }

    // Grabación de pantalla (grabando: punto rojo con el tiempo)
    RecordButton {}

    // Captura: clic = selector, clic derecho = monitor completo al instante
    Icon {
        text: Theme.iCamera

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: e => {
                if (e.button === Qt.RightButton) Screenshot.screenNow();
                else Screenshot.open();
            }
        }
    }

    // Pomodoro: con una sesión en marcha muestra el tiempo restante
    PomodoroButton {}

    NightLightButton {}

    // Barra vertical: el volumen va aquí dentro (icono y número), donde ocupa menos alto
    VolumePill {
        embedded: true
        active: root.vertical
        Layout.topMargin: 3
    }
}
