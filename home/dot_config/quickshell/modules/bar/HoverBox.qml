import QtQuick
import qs.services

// Caja con la capa de hover del diseño, para lo que en la barra no es un IconBtn (el pomodoro, la grabación, el título de lo que suena). El contenido pone
// su propio MouseArea: HoverHandler no le quita los clics.
Rectangle {
    implicitHeight: 28
    radius: Design.radiusSm
    color: hover.hovered ? Design.hoverLayer : "transparent"
    Behavior on color { ColorAnimation { duration: Design.fast } }

    HoverHandler {
        id: hover
    }
}
