import QtQuick
import qs.services

// Icono (una letra de la Nerd Font o de Velure Icons). Donde se use queda centrado,
// aunque no siempre al píxel: cada icono tiene su forma y el redondeo lo puede dejar
// medio píxel o uno desplazado. Si en un sitio concreto no se ve centrado, se corrige
// con el editor de iconos (Ajustes → Ajustar iconos), que guarda el ajuste de cada icono
// a cada tamaño (services/IconOffsets.qml) y se aplica aquí solo, en todos los sitios.
// Para un caso concreto también se puede pasar offsetX / offsetY (en píxeles; positivo
// = a la derecha / abajo), que se suman a lo guardado.
//   Icon { text: Theme.iBell; offsetY: 1 }
//   IconBtn { icon: Theme.iImage; iconOffsetX: 1; iconOffsetY: 1 }
Text {
    id: icon

    property real offsetX: 0
    property real offsetY: 0
    readonly property var savedOffset: IconOffsets.of(text, font.pixelSize)
    transform: Translate {
        x: icon.offsetX + icon.savedOffset.x
        y: icon.offsetY + icon.savedOffset.y
    }

    // Ancho tipográfico del icono (su avance en la fuente): para centrarlo en una caja.
    // El ancho del texto puede salir 1 px mayor si el dibujo acaba justo al borde de un
    // píxel, y entonces el icono quedaría desplazado.
    readonly property real advance: metrics.advanceWidth
    TextMetrics {
        id: metrics
        font: icon.font
        text: icon.text
    }

    color: Theme.text
    // La Nerd Font; los iconos propios (U+100000…, p. ej. Theme.iBitwarden), Velure Icons
    font.family: (text.codePointAt(0) ?? 0) >= 0x100000 ? Theme.velureIconFont : Theme.iconFont
    font.pixelSize: 16
    verticalAlignment: Text.AlignVCenter
    // Dibujo nativo: ajustado a la rejilla de píxeles (la Nerd Font y Velure Icons traen
    // instrucciones para ello) y sin los ribetes de color del suavizado subpíxel (con el
    // de Qt se ven borrosos y como desplazados)
    renderType: Text.NativeRendering
}
