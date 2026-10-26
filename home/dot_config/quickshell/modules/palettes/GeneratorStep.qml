import QtQuick
import QtQuick.Layouts

// Paso «Del generador»: la imagen y lo que saca paleta de ella (10 colores con las
// marcas de los que usa el tema, acentos, apagados, degradados y escalas)
GuideStep {
    id: step
    // Un PaletteData
    property var data
    readonly property var d: data ? data.d : null
    readonly property var sec: data ? data.sec : null
    readonly property var org: data ? data.org : null

    visible: !!d
    title: "Del generador"
    subtitle: "Lo que saca paleta de la imagen. Marcados, los colores que usa el tema."

    RowLayout {
        Layout.fillWidth: true
        spacing: 22

        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 340
            implicitHeight: 192
            radius: 10
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

            GuideLabel { text: "10 colores (ordenados por viveza)" }
            Row {
                spacing: 6
                Repeater {
                    model: step.d ? step.d.palette : []
                    Column {
                        required property string modelData
                        readonly property string mark: !step.org ? ""
                            : modelData === step.org.base ? "base"
                            : modelData === step.org.second ? "vecino 2"
                            : modelData === step.org.third ? "vecino 3" : ""
                        spacing: 3
                        Rectangle {
                            width: 46
                            height: 46
                            radius: 8
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
                ColorStrip { label: "Acentos (los 3 que elige)"; colors: step.sec ? step.sec.accent.colors : []; big: true }
                ColorStrip { label: "Apagados"; colors: step.sec ? step.sec.muted : []; big: true }
                ColorStrip { label: "Degradado acento 1 → 2"; colors: step.sec ? step.sec.accent.gradient1to2 : [] }
                ColorStrip { label: "Degradado acento 3 → 2"; colors: step.sec ? step.sec.accent.gradient3to2 : [] }
                ColorStrip { label: "Escala clara (blanco → acento)"; colors: step.sec ? step.sec.light : [] }
                ColorStrip { label: "Escala oscura (negro → acento)"; colors: step.sec ? step.sec.dark : [] }
            }
        }
    }
}
