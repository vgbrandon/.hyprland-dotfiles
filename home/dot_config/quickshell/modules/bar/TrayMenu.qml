import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components.base
import qs.components.containers
import qs.components.design
import qs.services

// Menú de una app de la bandeja (clic derecho), con el diseño Prisma en lugar del menú
// nativo de Qt. Los submenús se abren en el mismo panel, con una fila para volver.
//   TrayMenu { id: menu; anchorItem: icono; menu: item.menu }   →   menu.toggle()
BarPopup {
    id: popup

    // Menú raíz de la app (SystemTrayItem.menu)
    property QsMenuHandle menu
    // Submenús abiertos, del primero al actual
    property var stack: []
    readonly property QsMenuHandle current: stack.length > 0 ? stack[stack.length - 1] : menu

    implicitWidth: 260
    padding: 6
    spacing: 0
    maxHeight: 640

    onVisibleChanged: if (!visible) stack = []

    QsMenuOpener {
        id: opener
        menu: popup.current
    }

    // Volver del submenú
    MenuRow {
        visible: popup.stack.length > 0
        icon: Theme.iChevronLeft
        text: popup.stack.length > 0 ? popup.stack[popup.stack.length - 1].text : ""
        bold: true
        onClicked: popup.stack = popup.stack.slice(0, -1)
    }
    Rectangle {
        visible: popup.stack.length > 0
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        implicitHeight: 1
        color: Design.outlineVariant
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitHeight: entries.implicitHeight
        contentHeight: entries.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: entries
            width: parent.width
            spacing: 0

            Repeater {
                model: opener.children

                Loader {
                    id: entryLoader
                    required property QsMenuEntry modelData
                    Layout.fillWidth: true
                    sourceComponent: modelData.isSeparator ? separator : row

                    Component {
                        id: separator
                        Item {
                            implicitHeight: 9
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                height: 1
                                color: Design.outlineVariant
                            }
                        }
                    }
                    Component {
                        id: row
                        MenuRow {
                            readonly property QsMenuEntry entry: entryLoader.modelData
                            text: entry.text
                            image: entry.icon
                            enabled: entry.enabled
                            check: entry.buttonType
                            checked: entry.checkState === Qt.Checked
                            submenu: entry.hasChildren
                            onClicked: {
                                if (entry.hasChildren) {
                                    popup.stack = popup.stack.concat([entry]);
                                } else {
                                    entry.triggered();
                                    popup.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Una fila: casilla o radio (si la tiene), icono, texto y flecha de submenú
    component MenuRow: Rectangle {
        id: r

        property string text
        property string icon
        property string image
        property int check: QsMenuButtonType.None
        property bool checked: false
        property bool submenu: false
        property bool bold: false
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 32
        radius: Design.radiusSm
        color: !enabled ? "transparent" : mouse.pressed ? Design.pressLayer : mouse.containsMouse ? Design.hoverLayer : "transparent"
        opacity: enabled ? 1 : 0.45

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 10

            // Casilla / radio
            Rectangle {
                visible: r.check !== QsMenuButtonType.None
                implicitWidth: 16
                implicitHeight: 16
                radius: r.check === QsMenuButtonType.RadioButton ? 8 : Design.radiusXs
                color: r.checked ? Design.accent : "transparent"
                border.color: r.checked ? Design.accent : Design.outline
                border.width: 1.5
                Icon {
                    anchors.centerIn: parent
                    visible: r.checked && r.check === QsMenuButtonType.CheckBox
                    text: Theme.iCheck
                    font.pixelSize: 12
                    color: Design.onAccent
                }
                Rectangle {
                    anchors.centerIn: parent
                    visible: r.checked && r.check === QsMenuButtonType.RadioButton
                    width: 6
                    height: 6
                    radius: 3
                    color: Design.onAccent
                }
            }
            Icon {
                visible: r.icon !== ""
                text: r.icon
                font.pixelSize: 16
                color: Design.onSurfaceVariant
            }
            IconImage {
                visible: r.image !== ""
                implicitSize: 16
                source: r.image
            }
            Txt {
                Layout.fillWidth: true
                text: r.text.replace(/_(?!_)/g, "").replace(/__/g, "_")
                textStyle: r.bold ? Design.label : Design.body
            }
            Icon {
                visible: r.submenu
                text: Theme.iChevronRight
                font.pixelSize: 16
                color: Design.onSurfaceVariant
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: r.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: r.clicked()
        }
    }
}
