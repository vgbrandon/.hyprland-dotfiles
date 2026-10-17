import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.design
import qs.services

// Reloj grande en el escritorio (va dentro de la capa del fondo, debajo de las
// ventanas), con el diseño Prisma y a juego con la pantalla de bloqueo: horas sobre
// minutos (en acento), juntos, y la fecha completa debajo, alineado a la derecha.
Item {
    id: root

    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: Config.reserve("top") + 50
    anchors.rightMargin: Config.reserve("right") + 60
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        id: col
        spacing: 0

        Txt {
            Layout.alignment: Qt.AlignRight
            text: Qt.formatDateTime(clock.date, "hh")
            font.pixelSize: 150
            font.weight: Font.Light
            font.features: { "tnum": 1 }
            // Dígitos más juntos (a este tamaño la fuente los separa mucho)
            font.letterSpacing: -6
        }
        Txt {
            Layout.alignment: Qt.AlignRight
            // Pegado a las horas (la fuente deja mucho aire arriba y abajo)
            Layout.topMargin: -62
            text: Qt.formatDateTime(clock.date, "mm")
            color: Design.accent
            font.pixelSize: 150
            font.weight: Font.Light
            font.features: { "tnum": 1 }
            font.letterSpacing: -6
        }
        Txt {
            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: 6
            // En español aunque el sistema esté en inglés
            text: {
                const s = clock.date.toLocaleDateString(Qt.locale("es_ES"), "dddd, d 'de' MMMM");
                return s.charAt(0).toUpperCase() + s.slice(1);
            }
            font.pixelSize: 20
            color: Design.onSurfaceVariant
        }
    }
}
