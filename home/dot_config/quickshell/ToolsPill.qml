import QtQuick
import QtQuick.Layouts
import Quickshell

// Herramientas: fondos, selector de color, grabación, captura y luz nocturna.
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

    NightLightButton {}

    // Barra vertical: el volumen va aquí dentro (icono y número), donde ocupa menos alto
    VolumePill {
        embedded: true
        active: root.vertical
        Layout.topMargin: 3
    }
}
