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

    // Ocupa todo el alto: cada elemento se centra respecto a la píldora
    RowLayout {
        id: row
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.height
        spacing: 8
    }
}
