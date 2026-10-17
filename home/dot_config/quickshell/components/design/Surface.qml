import QtQuick
import QtQuick.Effects
import qs.services

// Superficie con un material: "mica" (barra), "glass" (paneles flotantes) o "solid"
// (contenido). En la guía, el desenfoque se simula con el fondo de pantalla que hay
// detrás (backdrop); en el escritorio lo hará Hyprland.
//   Surface { material: "glass"; backdrop: wall; elevation: 2; … }
Item {
    id: root

    property string material: "solid"
    property Item backdrop: null
    property color tint: material === "mica" ? Design.micaTint : material === "glass" ? Design.glassTint : Design.surface1
    property real tintOpacity: material === "mica" ? Design.micaOpacity : material === "glass" ? Design.glassOpacity : 1
    property real radius: Design.radiusMd
    property int elevation: material === "glass" ? 2 : 0
    property bool bordered: material !== "solid"
    // Cambia cuando se desplaza la guía (para recolocar el fondo desenfocado)
    property real scrollY: 0
    default property alias content: inner.data

    // Sombra
    Rectangle {
        visible: root.elevation > 0
        anchors.fill: parent
        radius: root.radius
        color: Design.background
        layer.enabled: visible
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: Design.elevation[root.elevation].opacity
            shadowBlur: Design.elevation[root.elevation].blur
            shadowVerticalOffset: Design.elevation[root.elevation].offset
            shadowHorizontalOffset: 0
        }
    }

    // Fondo desenfocado (solo con material transparente)
    Item {
        anchors.fill: parent
        visible: root.backdrop !== null && root.tintOpacity < 1
        layer.enabled: visible
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
        }

        ShaderEffectSource {
            id: blurSource
            anchors.fill: parent
            visible: false
            sourceItem: root.backdrop
            live: true
            sourceRect: {
                root.scrollY;
                root.x; root.y; root.width; root.height;
                if (!root.backdrop) return Qt.rect(0, 0, 0, 0);
                const p = root.mapToItem(root.backdrop, 0, 0);
                return Qt.rect(p.x, p.y, root.width, root.height);
            }
        }
        MultiEffect {
            anchors.fill: parent
            source: blurSource
            blurEnabled: true
            blur: Design.blur
            blurMax: 64
            saturation: 0.2
        }
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }

    // Tinte
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Design.alpha(root.tint, root.tintOpacity)
        border.color: root.bordered ? Design.border : "transparent"
        border.width: root.bordered ? 1 : 0
    }

    // Brillo del canto superior (más claro en el centro)
    Rectangle {
        visible: root.bordered
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - root.radius * 2
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Design.borderHighlight }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
