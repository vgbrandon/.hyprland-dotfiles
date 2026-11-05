import QtQuick
import QtQuick.Layouts
import qs.modules.palettes
import qs.services

// Una app en la guía de estilo: su nombre y plantilla, una vista previa pintada con los
// colores de la paleta y los papeles que usa, cada uno con su uso.
// roles: [[papel, uso], …]
Rectangle {
    id: card
    property string name
    property string file
    property var roles: []
    default property alias content: preview.data

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignTop
    implicitHeight: col.implicitHeight + 32
    radius: Design.corner(10)
    color: "#1a1a1e"
    border.color: "#26262c"

    ColumnLayout {
        id: col
        x: 16
        y: 16
        width: parent.width - 32
        spacing: 12

        RowLayout {
            spacing: 10
            GuideText { text: card.name; size: 15; weight: Font.Medium }
            GuideText { text: card.file; size: 11; color: "#7a7a82"; font.family: "JetBrainsMono Nerd Font" }
        }
        // La vista previa: lo de dentro ocupa todo el ancho
        Item {
            id: preview
            Layout.fillWidth: true
            implicitHeight: children.length > 0 ? children[0].implicitHeight : 0
            onChildrenChanged: {
                for (const c of children) c.width = Qt.binding(() => preview.width);
            }
        }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: card.roles
                RoleSwatch { role: modelData[0]; use: modelData[1] }
            }
        }
    }
}
