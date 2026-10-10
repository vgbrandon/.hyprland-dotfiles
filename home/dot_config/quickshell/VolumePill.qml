import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

// Píldora del volumen (en escritorio no hay batería). Rueda = subir/bajar.
// Horizontal: cápsula con el número y una barra que se llena (clic o arrastre en la
// barra = fijar el nivel; clic en el número = silenciar). Vertical: icono y número,
// dentro de la píldora del reloj (embedded), donde ocupa menos alto.
Rectangle {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real level: sink?.audio?.volume ?? 0
    readonly property bool muted: (sink?.audio?.muted ?? false) || Math.round(level * 100) === 0
    readonly property bool vertical: Config.barVertical
    // Dentro de otra píldora (barra vertical): sin fondo ni relleno propios
    property bool embedded: false
    // Quien la usa decide en qué orientación se muestra
    property bool active: true
    // Mismo margen a los dos lados: número a la izquierda, final de la barra a la derecha
    readonly property int side: 12

    function setLevel(v) {
        if (sink?.audio) sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    function toggleMute() {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted;
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    visible: active && sink?.audio !== undefined
    implicitWidth: vertical ? (embedded ? vol.implicitWidth : Theme.pillHeight) : 120
    implicitHeight: vertical ? vol.implicitHeight + (embedded ? 0 : 16) : Theme.pillHeight
    radius: Math.min(width, height) / 2
    color: embedded ? "transparent" : Theme.surface

    // Rueda en cualquier parte
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: e => root.setLevel(root.level + (e.angleDelta.y > 0 ? 0.05 : -0.05))
    }

    // --- Barra vertical: icono y número (clic = silenciar) ---
    ColumnLayout {
        id: vol
        visible: root.vertical
        anchors.centerIn: parent
        spacing: 0
        Icon {
            Layout.alignment: Qt.AlignCenter
            text: root.muted ? Theme.iMuted : Theme.iVolume
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            text: Math.round(root.level * 100)
        }
    }
    MouseArea {
        visible: root.vertical
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleMute()
    }

    // --- Barra horizontal: número + barra ---
    Item {
        id: number
        visible: !root.vertical
        x: root.side
        width: Math.max(numberLabel.implicitWidth, muteIcon.implicitWidth)
        height: parent.height

        Label {
            id: numberLabel
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.muted
            text: Math.round(root.level * 100)
        }
        Icon {
            id: muteIcon
            anchors.verticalCenter: parent.verticalCenter
            visible: root.muted
            text: Theme.iMuted
            color: Theme.subtext
            font.pixelSize: 14
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleMute()
        }
    }

    // Barra: se llena con el nivel; clic o arrastre = fijarlo
    Item {
        visible: !root.vertical
        anchors.left: number.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: root.side
        anchors.verticalCenter: parent.verticalCenter
        height: 10

        // Pista: todo el recorrido (hasta 100 %), tenue
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.withAlpha(Theme.text, 0.12)
        }

        // Relleno: el nivel actual
        Rectangle {
            height: parent.height
            width: root.level > 0 ? Math.max(height, parent.width * Math.min(1, root.level)) : 0
            radius: height / 2
            color: root.muted ? Theme.dot : Theme.text
            Behavior on width { NumberAnimation { duration: 120 } }
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -9
            anchors.bottomMargin: -9
            cursorShape: Qt.PointingHandCursor
            onPressed: e => root.setLevel(e.x / width)
            onPositionChanged: e => { if (pressed) root.setLevel(e.x / width); }
        }
    }
}
