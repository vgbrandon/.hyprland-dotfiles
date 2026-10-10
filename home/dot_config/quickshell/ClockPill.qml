import QtQuick
import QtQuick.Layouts
import Quickshell

// Hora • fecha (clic = calendario). Las herramientas van en ToolsPill y el volumen en VolumePill.
Pill {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
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
}
