import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.buttons
import qs.components.containers
import qs.services

// Calendario mensual (se abre al hacer clic en la fecha de la barra)
BarPopup {
    id: panel

    required property date today

    readonly property var locale: Qt.locale("es_ES")
    // Mes mostrado (cualquier día de ese mes)
    property date shown: today
    readonly property int year: shown.getFullYear()
    readonly property int month: shown.getMonth()

    // 42 celdas (6 semanas) empezando en lunes
    readonly property var cells: {
        const first = new Date(year, month, 1);
        const offset = (first.getDay() + 6) % 7; // lunes = 0
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(year, month, 1 - offset + i);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === month,
                isToday: d.toDateString() === today.toDateString(),
                weekend: d.getDay() === 0 || d.getDay() === 6
            });
        }
        return out;
    }

    function capitalize(s) {
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    function changeMonth(delta) {
        shown = new Date(year, month + delta, 1);
    }

    implicitWidth: 320
    padding: 16
    spacing: 12

    // Al cerrar vuelve al mes actual, así al abrir ya está listo
    onVisibleChanged: if (!visible) shown = today

    // Rueda = cambiar de mes
    WheelHandler {
        onWheel: e => panel.changeMonth(e.angleDelta.y > 0 ? -1 : 1)
    }

    // Fecha de hoy
    ColumnLayout {
        spacing: 0

        Label {
            text: panel.capitalize(panel.today.toLocaleDateString(panel.locale, "dddd"))
            color: Theme.subtext
        }
        Label {
            text: panel.today.toLocaleDateString(panel.locale, "d 'de' MMMM 'de' yyyy")
            font.pixelSize: 20
        }
    }

    // Mes y navegación
    RowLayout {
        spacing: 4

        Label {
            Layout.fillWidth: true
            text: panel.capitalize(panel.locale.standaloneMonthName(panel.month)) + " " + panel.year
            font.weight: Font.DemiBold
        }

        // Volver a hoy
        TextButton {
            visible: panel.month !== panel.today.getMonth() || panel.year !== panel.today.getFullYear()
            text: "Hoy"
            small: true
            onClicked: panel.shown = panel.today
        }
        CircleButton {
            icon: Theme.iChevronLeft
            size: 28
            iconSize: 18
            onClicked: panel.changeMonth(-1)
        }
        CircleButton {
            icon: Theme.iChevronRight
            size: 28
            iconSize: 18
            onClicked: panel.changeMonth(1)
        }
    }

    // Días de la semana + días del mes
    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 2
        columnSpacing: 2

        Repeater {
            model: ["L", "M", "X", "J", "V", "S", "D"]

            Label {
                required property string modelData
                required property int index
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: index >= 5 ? Theme.dot : Theme.subtext
                font.pixelSize: Theme.fontSize
            }
        }

        Repeater {
            model: panel.cells

            Rectangle {
                id: cell
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 36
                radius: height / 2
                color: modelData.isToday ? Theme.primary : "transparent"

                Label {
                    anchors.centerIn: parent
                    text: cell.modelData.day
                    color: cell.modelData.isToday ? Theme.primaryFg
                        : !cell.modelData.inMonth ? Theme.dot
                        : cell.modelData.weekend ? Theme.subtext : Theme.text
                    font.weight: cell.modelData.isToday ? Font.DemiBold : Font.Normal
                }
            }
        }
    }
}
