import QtQuick
import Quickshell.Widgets
import qs.services

// Foto de perfil en círculo; sin foto (o mientras carga), la inicial sobre el color
// principal. La usan el panel de ajustes, la ventana de perfil, el bloqueo y el greeter.
//   Avatar { size: 56; source: Profile.avatarUrl; initial: Profile.initial }
ClippingRectangle {
    id: root

    property int size: 40
    property string source
    property string initial

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: Theme.primary

    Text {
        anchors.centerIn: parent
        visible: photo.status !== Image.Ready
        text: root.initial
        color: Theme.primaryFg
        font.family: Theme.font
        font.pixelSize: Math.round(root.size * 0.45)
        font.weight: Font.DemiBold
    }

    Image {
        id: photo
        anchors.fill: parent
        source: root.source
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }
}
