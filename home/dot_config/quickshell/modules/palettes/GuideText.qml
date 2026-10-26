import QtQuick

// Texto de las guías (paletas y estilo): fuente del diseño sobre el fondo neutro
Text {
    property int size: 13
    property int weight: Font.Normal
    color: "#e6e6e6"
    font.family: "Adwaita Sans"
    font.pixelSize: size
    font.weight: weight
}
