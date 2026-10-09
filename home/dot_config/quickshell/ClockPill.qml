import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

// Hora • fecha + volumen
Pill {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    PwObjectTracker {
        objects: [root.sink]
    }

    // Clic en la hora/fecha = calendario
    Label {
        id: dateLabel
        // En la barra vertical: horas sobre minutos, sin fecha
        text: root.vertical
            ? Qt.formatDateTime(clock.date, "hh\nmm")
            : Qt.formatDateTime(clock.date, "hh:mm") + "  •  " + Qt.formatDateTime(clock.date, "dddd, dd/MM")
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 0.9

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: calendar.toggle()
        }

        CalendarPanel {
            id: calendar
            anchorItem: dateLabel
            today: clock.date
            visible: false
        }
    }

    // Fondos de pantalla
    Icon {
        Layout.leftMargin: root.vertical ? 0 : 6
        Layout.topMargin: root.vertical ? 3 : 0
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

    // Volumen (en escritorio no hay batería). Click = mute, rueda = subir/bajar
    Item {
        visible: root.sink?.audio !== undefined
        Layout.leftMargin: root.vertical ? 0 : 6
        Layout.topMargin: root.vertical ? 3 : 0
        implicitWidth: vol.implicitWidth
        implicitHeight: vol.implicitHeight

        GridLayout {
            id: vol
            columns: root.vertical ? 1 : 2
            rowSpacing: 0
            columnSpacing: 4
            Icon {
                Layout.alignment: Qt.AlignCenter
                text: root.sink?.audio?.muted || Math.round((root.sink?.audio?.volume ?? 0) * 100) === 0 ? Theme.iMuted : Theme.iVolume
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: Math.round((root.sink?.audio?.volume ?? 0) * 100)
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.sink.audio.muted = !root.sink.audio.muted
            onWheel: e => {
                const v = root.sink.audio.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05);
                root.sink.audio.volume = Math.max(0, Math.min(1, v));
            }
        }
    }
}
