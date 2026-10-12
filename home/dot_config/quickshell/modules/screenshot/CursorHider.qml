import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Capa transparente que oculta el cursor durante una captura (ver Screenshot.capture)
PanelWindow {
    required property ShellScreen modelData

    screen: modelData
    visible: Screenshot.hidingCursor
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:screenshot-cursor"

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.BlankCursor
    }
}
