import QtQuick
import QtQuick.Layouts

// Contenedor redondeado para agrupar módulos. En la barra vertical
// (izquierda/derecha) los elementos se apilan en columna.
Rectangle {
    default property alias content: grid.data
    property int padding: 12
    property int spacing: 8
    // Sigue a la barra; otros sitios (p. ej. la pantalla de bloqueo) lo fijan
    property bool vertical: Config.barVertical
    // Barra vertical en un monitor bajo: aún más apretado
    property bool compact: false

    // En columna se aprieta un poco: el alto del monitor es más justo que el ancho
    implicitWidth: vertical ? Theme.pillHeight : grid.implicitWidth + padding * 2
    implicitHeight: vertical ? grid.implicitHeight + Math.min(padding, compact ? 6 : 8) * 2 : Theme.pillHeight
    radius: Math.min(width, height) / 2
    color: Theme.surface

    // Ocupa todo el grosor: cada elemento se centra respecto a la píldora
    GridLayout {
        id: grid
        anchors.centerIn: parent
        width: vertical ? parent.width : implicitWidth
        height: vertical ? implicitHeight : parent.height
        flow: vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: vertical ? -1 : 1
        columns: vertical ? 1 : -1
        rowSpacing: vertical ? Math.min(spacing, compact ? 3 : 5) : spacing
        columnSpacing: spacing

        // Centra cada elemento en su celda (en columna, si no, quedan a la izquierda)
        Component.onCompleted: {
            for (const child of children)
                child.Layout.alignment = Qt.AlignCenter;
        }
    }
}
