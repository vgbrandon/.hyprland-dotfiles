import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
  SystemClock { id: clock; precision: SystemClock.Minutes }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors { top: true; left: true; right: true }

      implicitHeight: 26
      exclusiveZone: implicitHeight
      color: "transparent"

      // Ajuste óptico: baja todo 2px para “matar” el espacio del font descent
      Item {
        anchors.fill: parent

        RowLayout {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.leftMargin: 14
          anchors.rightMargin: 14
          anchors.bottomMargin: 0

          spacing: 10

          // IZQUIERDA
          RowLayout {
            Layout.alignment: Qt.AlignBottom | Qt.AlignLeft
            spacing: 12

            Text {
              text: ""
              color: "#ffffff"
              opacity: 0.92
              font.pixelSize: 14
              font.weight: 600
              transform: Translate { y: 2 }   // <- baja 2px
            }

            Repeater {
              model: Hyprland.workspaces
              delegate: Text {
                required property var modelData
                text: modelData.name
                color: modelData.focused ? "#ffffff" : "#cbd5e1"
                opacity: modelData.focused ? 0.95 : 0.75
                font.pixelSize: 14
                font.weight: modelData.focused ? 700 : 500
                transform: Translate { y: 2 } // <- baja 2px

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: modelData.activate()
                }
              }
            }
          }

          Item { Layout.fillWidth: true }

          // CENTRO
          Text {
            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: "#ffffff"
            opacity: 0.92
            font.pixelSize: 14
            font.weight: 600
            transform: Translate { y: 2 }   // <- baja 2px
          }

          Item { Layout.fillWidth: true }

          // DERECHA
          RowLayout {
            Layout.alignment: Qt.AlignBottom | Qt.AlignRight
            spacing: 12

            Text { text: "󰖩"; color: "#ffffff"; opacity: 0.8; font.pixelSize: 14; transform: Translate { y: 2 } }
            Text { text: "";  color: "#ffffff"; opacity: 0.8; font.pixelSize: 14; transform: Translate { y: 2 } }
            Text { text: "󰁹"; color: "#ffffff"; opacity: 0.8; font.pixelSize: 14; transform: Translate { y: 2 } }

            Text {
              text: Qt.formatDateTime(clock.date, "ddd d MMM")
              color: "#ffffff"
              opacity: 0.85
              font.pixelSize: 14
              transform: Translate { y: 2 } // <- baja 2px
            }
          }
        }
      }
    }
  }
}

