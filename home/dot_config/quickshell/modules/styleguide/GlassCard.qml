import QtQuick
import QtQuick.Layouts
import qs.components.design
import qs.services

// Panel de vidrio con título y nota, para los ejemplos de la guía de estilo sobre el
// fondo (backdrop: la imagen de la franja; scrollY: el desplazamiento de la guía)
Item {
    id: card
    property string heading
    property string note
    property Item backdrop: null
    property real scrollY: 0
    default property alias body: cardBody.data
    implicitWidth: cardCol.implicitWidth + 32
    implicitHeight: cardCol.implicitHeight + 32

    Surface {
        anchors.fill: parent
        material: "glass"
        backdrop: card.backdrop
        scrollY: card.scrollY
        elevation: 2
    }
    ColumnLayout {
        id: cardCol
        x: 16
        y: 16
        width: parent.width - 32
        spacing: 12
        ColumnLayout {
            spacing: 2
            Txt { text: card.heading; textStyle: Design.headline }
            Txt { Layout.fillWidth: true; text: card.note; wrapMode: Text.Wrap; textStyle: Design.caption; color: Design.onSurfaceVariant }
        }
        ColumnLayout {
            id: cardBody
            Layout.fillWidth: true
            spacing: 12
        }
    }
}
