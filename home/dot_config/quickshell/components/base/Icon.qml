import QtQuick
import qs.services

Text {
    color: Theme.text
    // La Nerd Font; los iconos propios (U+100000…, p. ej. Theme.iBitwarden), Velure Icons
    font.family: (text.codePointAt(0) ?? 0) >= 0x100000 ? Theme.velureIconFont : Theme.iconFont
    font.pixelSize: 16
    verticalAlignment: Text.AlignVCenter
}
