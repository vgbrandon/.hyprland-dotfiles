import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

// Fila de una red WiFi. Clic = conectar / desconectar; si pide contraseña y no
// está guardada, se despliega un campo para escribirla.
Rectangle {
    id: row

    required property WifiNetwork modelData
    readonly property WifiNetwork net: modelData
    readonly property bool secured: net.security !== WifiSecurityType.Open && net.security !== WifiSecurityType.Owe
    readonly property bool busy: net.stateChanging
    property bool askingKey: false
    property string error: ""

    function signalIcon(s) {
        const v = s > 1 ? s / 100 : s;
        return v > 0.75 ? Theme.iWifi4 : v > 0.5 ? Theme.iWifi3 : v > 0.25 ? Theme.iWifi2 : Theme.iWifi1;
    }

    function activate() {
        if (busy) return;
        error = "";
        if (net.connected) net.disconnect();
        else if (net.known || !secured) net.connect();
        else {
            askingKey = !askingKey;
            if (askingKey) Qt.callLater(() => secretField.forceActiveFocus());
        }
    }

    function submit() {
        if (secretField.text === "") return;
        error = "";
        net.connectWithPsk(secretField.text);
        secretField.text = "";
        askingKey = false;
    }

    Connections {
        target: row.net
        function onConnectionFailed(reason) {
            row.error = reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout
                ? "Contraseña incorrecta" : "No se pudo conectar";
            if (!row.net.known && row.secured) row.askingKey = true;
        }
    }

    implicitHeight: content.implicitHeight + 16
    radius: Theme.radiusSmall
    color: mouse.containsMouse || askingKey ? Theme.surfaceHigh : "transparent"

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.activate()
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        RowLayout {
            spacing: 12

            Rectangle {
                implicitWidth: 34
                implicitHeight: 34
                radius: Theme.radiusSmall
                color: row.net.connected ? Theme.primary : Theme.surfaceHigh

                Icon {
                    anchors.centerIn: parent
                    text: row.signalIcon(row.net.signalStrength)
                    color: row.net.connected ? Theme.primaryFg : Theme.text
                    font.pixelSize: 18
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    Layout.fillWidth: true
                    text: row.net.name
                }
                Label {
                    Layout.fillWidth: true
                    text: {
                        if (row.error !== "") return row.error;
                        const st = row.net.state;
                        if (st === ConnectionState.Connecting) return "Conectando…";
                        if (st === ConnectionState.Disconnecting) return "Desconectando…";
                        if (row.net.connected) return "Conectado";
                        if (row.net.known) return "Guardada";
                        return row.secured ? "Protegida" : "Abierta";
                    }
                    color: row.error !== "" ? Theme.error : row.net.connected ? Theme.text : Theme.subtext
                    font.pixelSize: Theme.fontSize
                }
            }

            // Candado, en una caja del mismo tamaño que el icono de señal (simétrico)
            Item {
                visible: row.secured
                implicitWidth: 34
                implicitHeight: 34

                Icon {
                    anchors.centerIn: parent
                    text: Theme.iLock
                    color: Theme.subtext
                    font.pixelSize: 14
                }
            }

            // Olvidar (solo redes guardadas, al pasar el ratón)
            Rectangle {
                visible: row.net.known && (mouse.containsMouse || forgetMouse.containsMouse)
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                color: forgetMouse.containsMouse ? Theme.surface : "transparent"

                Icon {
                    anchors.centerIn: parent
                    text: Theme.iClose
                    color: Theme.subtext
                    font.pixelSize: 14
                }
                MouseArea {
                    id: forgetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.net.forget()
                }
            }
        }

        // Contraseña (redes protegidas que no están guardadas)
        Rectangle {
            visible: row.askingKey
            Layout.fillWidth: true
            implicitHeight: 40
            radius: height / 2
            color: Theme.surface
            border.color: secretField.activeFocus ? Theme.primary : Theme.surfaceHigh
            border.width: 1

            TextInput {
                id: secretField
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 2
                clip: true
                onAccepted: row.submit()
                Keys.onEscapePressed: row.askingKey = false

                Text {
                    visible: secretField.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Contraseña (Enter para conectar)"
                    color: Theme.subtext
                    font: secretField.font
                }
            }
        }
    }
}
