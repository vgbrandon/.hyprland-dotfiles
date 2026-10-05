import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

// Tarjeta de una notificación (se usa en los popups y en el centro)
Rectangle {
    id: card

    required property Notification notif
    property bool popup: false
    readonly property bool hovered: hover.hovered
    readonly property var defaultAction: notif.actions.find(a => a.identifier === "default") ?? null
    readonly property var buttons: notif.actions.filter(a => a.identifier !== "default")
    readonly property string iconSource: {
        if (notif.image !== "") return notif.image;
        const i = notif.appIcon;
        if (i === "") return "";
        if (i.startsWith("/") ) return "file://" + i;
        if (i.includes("://")) return i;
        return Quickshell.iconPath(i, true);
    }

    function activate(action) {
        Notifs.closeCenter();
        action?.invoke();
        if (!notif.resident) notif.dismiss();
    }

    implicitHeight: content.implicitHeight + 24
    radius: 20
    // Dentro del panel de vidrio, semitransparente; como popup, sólida
    color: popup ? Theme.surface : Theme.withAlpha(Theme.surfaceHigh, 0.5)
    border.color: notif.urgency === NotificationUrgency.Critical ? Theme.error : Theme.surfaceHigh
    border.width: 1

    HoverHandler {
        id: hover
    }

    // Clic en la tarjeta = acción por defecto
    MouseArea {
        anchors.fill: parent
        cursorShape: card.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (card.defaultAction) card.activate(card.defaultAction)
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 40
            implicitHeight: 40
            radius: 12
            color: Theme.surfaceHigh

            Icon {
                anchors.centerIn: parent
                visible: img.status !== Image.Ready
                text: Theme.iBell
                color: Theme.subtext
                font.pixelSize: 20
            }
            Image {
                id: img
                anchors.fill: parent
                source: card.iconSource
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 80
                sourceSize.height: 80
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                spacing: 6

                Label {
                    Layout.fillWidth: true
                    text: [card.notif.appName, Notifs.ago(card.notif)].filter(s => s !== "").join(" • ")
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 1
                }
                Icon {
                    text: Theme.iClose
                    color: closeMouse.containsMouse ? Theme.text : Theme.subtext
                    font.pixelSize: 14

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.notif.dismiss()
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: card.notif.summary
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.notif.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: card.popup ? 4 : 8
                elide: Text.ElideRight
                color: Theme.subtext
                linkColor: Theme.primary
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            // Botones de acción
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: card.buttons.length > 0
                spacing: 6

                Repeater {
                    model: card.buttons

                    Rectangle {
                        id: btn
                        required property NotificationAction modelData

                        width: btnLabel.implicitWidth + 24
                        height: 30
                        radius: height / 2
                        color: btnMouse.containsMouse ? Theme.primary : Theme.surfaceHigh

                        Label {
                            id: btnLabel
                            anchors.centerIn: parent
                            text: btn.modelData.text
                            color: btnMouse.containsMouse ? Theme.primaryFg : Theme.text
                            font.pixelSize: Theme.fontSize + 1
                        }
                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.activate(btn.modelData)
                        }
                    }
                }
            }
        }
    }
}
