import QtQuick
import QtQuick.Layouts

// Contenedor redondeado para agrupar módulos
Rectangle {
    default property alias content: row.data
    property int padding: 12
    property alias spacing: row.spacing

    implicitHeight: Theme.pillHeight
    implicitWidth: row.implicitWidth + padding * 2
    radius: height / 2
    color: Theme.surface

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }
}
