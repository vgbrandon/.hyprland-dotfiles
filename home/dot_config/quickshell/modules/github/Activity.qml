import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.buttons
import qs.services

// Actividad de GitHub de un mes: calendario con un color por día (más color = más
// contribuciones), flechas para ir atrás o adelante de mes en mes, el total y la
// racha. Al pasar el ratón, el día y su número; clic = lo que se hizo ese día
// (commits con su mensaje, PRs, issues y revisiones).
ColumnLayout {
    id: root

    spacing: 8

    readonly property var locale: Qt.locale("es_ES")
    property var hovered: null

    function dayText(d) {
        const date = new Date(d.date + "T12:00:00");
        const n = d.count === 1 ? "1 contribución" : `${d.count} contribuciones`;
        return `${date.toLocaleDateString(locale, "ddd d 'de' MMMM")}: ${n}`;
    }
    function levelColor(level) {
        return level === 0 ? Theme.surfaceHigh : Theme.withAlpha(Theme.primary, [0, 0.3, 0.5, 0.75, 1][level]);
    }

    // --- Cabecera: mes, flechas, total y racha ---
    RowLayout {
        spacing: 4

        CircleButton {
            icon: Theme.iChevronLeft
            size: 26
            iconSize: 15
            enabled: GitHub.canGoBack
            onClicked: GitHub.previousMonth()
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: root.locale.standaloneMonthName(GitHub.shownMonth.month).replace(/^./, c => c.toUpperCase())
                    + " " + GitHub.shownMonth.year
                font.weight: Font.DemiBold
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: GitHub.windowLoading ? "Cargando…"
                    : (GitHub.monthTotal === 1 ? "1 contribución" : `${GitHub.monthTotal} contribuciones`)
                    + (GitHub.monthOffset === 0 && GitHub.streak > 0 ? `  ·  racha de ${GitHub.streak} ${GitHub.streak === 1 ? "día" : "días"}` : "")
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 1
            }
        }
        CircleButton {
            icon: Theme.iChevronRight
            size: 26
            iconSize: 15
            enabled: GitHub.monthOffset > 0
            onClicked: GitHub.nextMonth()
        }
    }

    // --- El mes (semanas de lunes a domingo) ---
    GridLayout {
        id: monthGrid
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 3
        columnSpacing: 3

        // Semanas desde el lunes de la primera (5 o 6)
        readonly property var cells: {
            const m = GitHub.shownMonth;
            const first = new Date(m.year, m.month, 1);
            const offset = (first.getDay() + 6) % 7;
            const today = Qt.formatDate(new Date(), "yyyy-MM-dd");
            const out = [];
            for (let i = 0; i < 42; i++) {
                const d = new Date(m.year, m.month, 1 - offset + i);
                const date = Qt.formatDate(d, "yyyy-MM-dd");
                out.push({ date, day: d.getDate(), inMonth: d.getMonth() === m.month,
                    future: date > today, today: date === today });
            }
            return out.slice(35).every(c => !c.inMonth) ? out.slice(0, 35) : out;
        }

        Repeater {
            model: ["L", "M", "X", "J", "V", "S", "D"]
            Text {
                required property string modelData
                // Mismo ancho base en todas las columnas: se reparten por igual
                Layout.fillWidth: true
                Layout.preferredWidth: 10
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }
        }

        Repeater {
            model: monthGrid.cells

            Rectangle {
                id: dayCell
                required property var modelData
                readonly property var info: GitHub.days[modelData.date] ?? { count: 0, level: 0 }
                readonly property bool selected: GitHub.selectedDate === modelData.date
                readonly property bool usable: modelData.inMonth && !modelData.future

                Layout.fillWidth: true
                Layout.preferredWidth: 10
                implicitHeight: 30
                radius: Theme.radiusSmall
                opacity: modelData.inMonth ? 1 : 0
                color: !usable ? "transparent" : root.levelColor(info.level)
                border.width: selected || modelData.today || (dayMouse.containsMouse && usable) ? 1 : 0
                border.color: selected ? Theme.text : modelData.today ? Theme.primary : Theme.subtext

                Text {
                    anchors.centerIn: parent
                    text: dayCell.modelData.day
                    color: !dayCell.usable ? Theme.dot
                        : dayCell.info.level >= 3 ? Theme.primaryFg : Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
                MouseArea {
                    id: dayMouse
                    anchors.fill: parent
                    enabled: dayCell.usable
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.hovered = { date: dayCell.modelData.date, count: dayCell.info.count }
                    onExited: if (root.hovered?.date === dayCell.modelData.date) root.hovered = null
                    onClicked: GitHub.loadDay(dayCell.modelData.date)
                }
            }
        }
    }

    // Día bajo el ratón (o leyenda)
    RowLayout {
        Layout.leftMargin: 4
        spacing: 4

        Label {
            Layout.fillWidth: true
            text: root.hovered ? root.dayText(root.hovered) : "Pulsa un día para ver qué hiciste"
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 1
        }
        Label {
            text: "Menos"
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 1
        }
        Repeater {
            model: 5
            Rectangle {
                required property int index
                width: 9
                height: 9
                radius: 2
                color: root.levelColor(index)
            }
        }
        Label {
            text: "Más"
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 1
        }
    }

    // --- Detalle del día elegido ---
    Rectangle {
        visible: GitHub.selectedDate !== ""
        Layout.fillWidth: true
        implicitHeight: Math.min(detail.implicitHeight, 280) + 20
        radius: Theme.radiusSmall
        color: Theme.surface

        Flickable {
            anchors.fill: parent
            anchors.margins: 10
            contentHeight: detail.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: detail
                width: parent.width
                spacing: 6

                Label {
                    Layout.fillWidth: true
                    text: GitHub.selectedDate === "" ? ""
                        : root.locale.toString(new Date(GitHub.selectedDate + "T12:00:00"), "dddd d 'de' MMMM").replace(/^./, c => c.toUpperCase())
                    font.weight: Font.DemiBold
                }

                Label {
                    visible: GitHub.dayLoading
                    text: "Cargando…"
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                }
                Label {
                    visible: !GitHub.dayLoading && GitHub.day !== null
                        && (GitHub.day.error !== undefined || ["commits", "pullRequests", "issues", "reviews"].every(k => (GitHub.day[k] ?? []).length === 0))
                    Layout.fillWidth: true
                    text: GitHub.day?.error ? "No se pudo cargar ese día." : "Ese día no hubo actividad."
                    wrapMode: Text.Wrap
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                }

                // Commits, agrupados por repositorio
                Repeater {
                    model: {
                        const groups = [];
                        for (const c of GitHub.day?.commits ?? []) {
                            let g = groups.find(x => x.repo === c.repo);
                            if (!g) groups.push(g = { repo: c.repo, commits: [] });
                            g.commits.push(c);
                        }
                        return groups;
                    }

                    ColumnLayout {
                        id: group
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            spacing: 6
                            Icon {
                                text: Theme.iGithub
                                color: Theme.subtext
                                font.pixelSize: 13
                            }
                            Label {
                                Layout.fillWidth: true
                                text: `${group.modelData.repo.split("/").pop()}  ·  ${group.modelData.commits.length === 1 ? "1 commit" : group.modelData.commits.length + " commits"}`
                                color: Theme.subtext
                                font.pixelSize: Theme.fontSize
                            }
                        }
                        Repeater {
                            model: group.modelData.commits
                            LinkRow {
                                required property var modelData
                                prefix: modelData.sha
                                text: modelData.message
                                url: modelData.url
                            }
                        }
                    }
                }

                // PRs, issues y revisiones
                Repeater {
                    model: [
                        { label: "Pull requests", items: GitHub.day?.pullRequests ?? [] },
                        { label: "Issues", items: GitHub.day?.issues ?? [] },
                        { label: "Revisiones", items: GitHub.day?.reviews ?? [] }
                    ].filter(s => s.items.length > 0)

                    ColumnLayout {
                        id: section
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: section.modelData.label
                            color: Theme.subtext
                            font.pixelSize: Theme.fontSize
                        }
                        Repeater {
                            model: section.modelData.items
                            LinkRow {
                                required property var modelData
                                prefix: modelData.repo.split("/").pop()
                                text: modelData.title
                                url: modelData.url
                            }
                        }
                    }
                }
            }
        }
    }

    // Línea pulsable que abre la dirección en el navegador
    component LinkRow: Rectangle {
        id: link
        property string prefix
        property string text
        property string url

        Layout.fillWidth: true
        implicitHeight: 24
        radius: 6
        color: linkMouse.containsMouse ? Theme.surfaceHigh : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 8
            Text {
                text: link.prefix
                color: Theme.primary
                font.family: Theme.monoFont
                font.pixelSize: Theme.fontSize - 1
            }
            Label {
                Layout.fillWidth: true
                text: link.text
                font.pixelSize: Theme.fontSize
            }
        }
        MouseArea {
            id: linkMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally(link.url)
        }
    }
}
