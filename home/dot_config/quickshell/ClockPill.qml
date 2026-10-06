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
        text: Qt.formatDateTime(clock.date, "hh:mm") + "  •  " + Qt.formatDateTime(clock.date, "dddd, dd/MM")

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
        Layout.leftMargin: 6
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
        Layout.leftMargin: 6
        implicitWidth: vol.implicitWidth
        implicitHeight: vol.implicitHeight

        RowLayout {
            id: vol
            spacing: 4
            Icon { text: root.sink?.audio?.muted || Math.round((root.sink?.audio?.volume ?? 0) * 100) === 0 ? Theme.iMuted : Theme.iVolume }
            Label { text: Math.round((root.sink?.audio?.volume ?? 0) * 100) }
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
