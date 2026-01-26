import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  // Una barra por monitor
  Variants {
    model: Quickshell.screens  // <- en v0.2.1 es "model", no "variants" :contentReference[oaicite:1]{index=1}

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: 32
      color: "#111318"

      RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

        // IZQUIERDA: Workspaces
        RowLayout {
          spacing: 6
          Layout.alignment: Qt.AlignVCenter

          Repeater {
            model: Hyprland.workspaces  // :contentReference[oaicite:2]{index=2}

            delegate: Rectangle {
              required property var modelData // HyprlandWorkspace
              height: 22
              radius: 6
              width: wsText.implicitWidth + 14

              color: modelData.focused ? "#3b82f6"
                    : modelData.active ? "#334155"
                    : modelData.urgent ? "#ef4444"
                    : "#1f2937"

              border.width: 1
              border.color: modelData.focused ? "#60a5fa" : "#111827"

              Text {
                id: wsText
                anchors.centerIn: parent
                text: modelData.name
                color: "#e5e7eb"
                font.pixelSize: 12
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: modelData.activate()
              }
            }
          }
        }

        // “Separador” flexible para centrar la hora
        Item { Layout.fillWidth: true }

        // CENTRO: Hora
        Text {
          Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
          text: Qt.formatDateTime(clock.date, "HH:mm")
          color: "#e5e7eb"
          font.pixelSize: 13
          font.weight: 600
        }

        // “Separador” flexible para empujar la fecha a la derecha
        Item { Layout.fillWidth: true }

        // DERECHA: Fecha
        Text {
          Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
          text: Qt.formatDateTime(clock.date, "yyyy-MM-dd")
          color: "#cbd5e1"
          font.pixelSize: 12
        }
      }
    }
  }
}

