import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.buttons
import qs.services

// Texto con formato markdown. Los bloques de código (```) van aparte, en monoespaciada y
// con botón de copiar; un bloque sin cerrar (la respuesta aún llegando) también se ve
// como código. El texto se puede seleccionar.
//   MarkdownText { text: part.text }
ColumnLayout {
    id: root

    property string text
    property color color: Theme.text

    spacing: 8

    // Trozos: { code: false, text } o { code: true, lang, text }
    readonly property var segments: {
        const out = [];
        const re = /```([^\n`]*)\n?([\s\S]*?)(```|$)/g;
        let last = 0, m;
        while ((m = re.exec(text)) !== null) {
            if (m.index === re.lastIndex) {
                re.lastIndex++;
                continue;
            }
            const before = text.slice(last, m.index).trim();
            if (before !== "") out.push({ code: false, text: before });
            out.push({ code: true, lang: m[1].trim(), text: m[2].replace(/\n$/, "") });
            last = re.lastIndex;
        }
        const rest = text.slice(last).trim();
        if (rest !== "") out.push({ code: false, text: rest });
        return out;
    }

    Repeater {
        model: root.segments

        Loader {
            id: seg
            required property var modelData
            Layout.fillWidth: true
            sourceComponent: modelData.code ? codeBlock : prose

            Component {
                id: prose

                TextEdit {
                    text: seg.modelData.text
                    textFormat: TextEdit.MarkdownText
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    color: root.color
                    selectionColor: Theme.withAlpha(Theme.primary, 0.4)
                    selectedTextColor: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                    onLinkActivated: link => Qt.openUrlExternally(link)

                    HoverHandler {
                        enabled: parent.hoveredLink !== ""
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }

            Component {
                id: codeBlock

                Rectangle {
                    implicitHeight: codeColumn.implicitHeight + 16
                    radius: Theme.radiusSmall
                    color: Theme.surface
                    border.color: Theme.surfaceHigh
                    border.width: 1

                    ColumnLayout {
                        id: codeColumn
                        anchors.fill: parent
                        anchors.margins: 8
                        anchors.topMargin: 4
                        spacing: 2

                        RowLayout {
                            Label {
                                Layout.fillWidth: true
                                text: seg.modelData.lang || "código"
                                color: Theme.subtext
                                font.pixelSize: Theme.fontSize - 1
                            }
                            CircleButton {
                                id: copyButton
                                property bool copied: false
                                icon: copied ? Theme.iCheck : Theme.iCopy
                                size: 24
                                iconSize: 13
                                iconColor: Theme.subtext
                                onClicked: {
                                    Quickshell.execDetached(["wl-copy", "--", seg.modelData.text]);
                                    copied = true;
                                    copiedTimer.restart();
                                }
                                Timer {
                                    id: copiedTimer
                                    interval: 1500
                                    onTriggered: copyButton.copied = false
                                }
                            }
                        }
                        // Las líneas largas se desplazan en horizontal (sin partirlas)
                        Flickable {
                            Layout.fillWidth: true
                            implicitHeight: code.implicitHeight
                            contentWidth: code.implicitWidth
                            flickableDirection: Flickable.HorizontalFlick
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true

                            TextEdit {
                                id: code
                                text: seg.modelData.text
                                textFormat: TextEdit.PlainText
                                readOnly: true
                                selectByMouse: true
                                color: Theme.text
                                selectionColor: Theme.withAlpha(Theme.primary, 0.4)
                                font.family: Theme.monoFont
                                font.pixelSize: Theme.fontSize
                            }
                        }
                    }
                }
            }
        }
    }
}
