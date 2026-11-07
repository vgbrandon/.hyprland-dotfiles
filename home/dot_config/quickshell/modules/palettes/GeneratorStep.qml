import QtQuick
import QtQuick.Layouts
import qs.services

// Paso «De la imagen»: la imagen y lo que saca velure de ella (sus colores con las
// marcas de los que salen los acentos) y los grupos de tokens que deriva
GuideStep {
    id: step
    // Un PaletteData
    property var data
    readonly property var d: data ? data.d : null
    readonly property var r: data ? data.r : null
    readonly property var org: data ? data.org : null

    function hexes(names) {
        return r ? names.map(n => r[n]) : [];
    }
    function numbered(prefix, count) {
        return hexes(Array.from({ length: count }, (_, i) => prefix + i));
    }

    visible: !!d
    title: "De la imagen"
    subtitle: "Lo que saca velure de la imagen. Armonía detectada: " + (step.d ? step.d.harmony : "") + ". Marcados, los colores de los que salen los acentos."

    RowLayout {
        Layout.fillWidth: true
        spacing: 22

        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 340
            implicitHeight: 192
            radius: Design.corner(10)
            color: "#000000"
            clip: true
            Image {
                anchors.fill: parent
                source: step.d ? "file://" + step.d.image : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 680
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            GuideLabel { text: "Colores de la imagen (por presencia)" }
            Row {
                spacing: 6
                Repeater {
                    model: step.d ? step.d.image_colors : []
                    Column {
                        required property string modelData
                        readonly property string mark: !step.org ? ""
                            : modelData === step.org.primary ? "primario"
                            : modelData === step.org.secondary ? "secundario"
                            : modelData === step.org.tertiary ? "terciario" : ""
                        spacing: 3
                        Rectangle {
                            width: 46
                            height: 46
                            radius: Design.corner(8)
                            color: parent.modelData
                            border.width: parent.mark !== "" ? 2 : 1
                            border.color: parent.mark !== "" ? "#ffffff" : "#2a2a30"
                        }
                        GuideText { text: parent.modelData.toLowerCase(); size: 9; color: "#77777f"; font.family: "JetBrainsMono Nerd Font" }
                        GuideText { text: parent.mark; size: 9; weight: Font.DemiBold }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 22
                rowSpacing: 10
                ColorStrip { label: "Acentos"; colors: step.hexes(["primary", "secondary", "tertiary"]); big: true }
                ColorStrip { label: "Estados"; colors: step.hexes(["error", "warning", "success", "info"]); big: true }
                ColorStrip { label: "Fondos y borde"; colors: step.hexes(["crust", "bg", "surface_low", "surface", "surface_high", "overlay", "border"]) }
                ColorStrip { label: "Texto"; colors: step.hexes(["muted", "subtext", "text"]) }
                ColorStrip { label: "Código"; colors: step.hexes(["syntax_keyword", "syntax_function", "syntax_type", "syntax_string", "syntax_number", "syntax_property"]) }
                ColorStrip { label: "Degradado del visualizador"; colors: step.numbered("gradient_", 8) }
                ColorStrip { label: "Terminal"; colors: step.numbered("ansi_", 16) }
            }
        }
    }
}
