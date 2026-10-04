import QtQuick

Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize + 2
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    // El cuadro de texto incluye espacio para letras con descendente (g, y, p);
    // sin esto los números y mayúsculas se ven ~1.5 px más arriba del centro.
    topPadding: 2
}
