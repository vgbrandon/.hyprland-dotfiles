import QtQuick
import QtQuick.Layouts
import qs.modules.palettes
import qs.services

// Un color de una plantilla en la guía: la muestra, el papel de la paleta, su valor y
// para qué lo usa la app
Rectangle {
    id: sw
    property string role
    property string use
    readonly property color value: Theme.scheme[role.startsWith("term_") ? role : "p_" + role] ?? "#808080"

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 38
    radius: Design.corner(6)
    color: "#141417"
    border.color: "#24242a"

    RowLayout {
        id: row
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Rectangle {
            implicitWidth: 20
            implicitHeight: 20
            radius: Design.corner(4)
            color: sw.value
            border.color: "#1affffff"
        }
        ColumnLayout {
            spacing: 0
            GuideText { text: sw.role; size: 11; font.family: "JetBrainsMono Nerd Font" }
            GuideText { text: sw.use + "  ·  " + sw.value.toString(); size: 10; color: "#8a8a92" }
        }
    }
}
