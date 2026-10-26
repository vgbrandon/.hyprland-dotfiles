import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.containers
import qs.components.design
import qs.services

// Ventana de autorización de polkit (diseño Velure): qué pide permiso, quién autoriza
// (si hay varios, se elige), la contraseña y Cancelar / Autenticar. Si la contraseña
// no es correcta, lo dice y se puede reintentar. La lógica está en services/Polkit.qml.
OverlayWindow {
    id: win

    readonly property var flow: Polkit.flow
    open: flow !== null && !flow.isCompleted
    onCloseRequested: flow?.cancelAuthenticationRequest()
    namespace: "quickshell:polkit"
    cardWidth: 440
    padding: 20
    spacing: 14

    readonly property bool waiting: flow !== null && !flow.isResponseRequired
    readonly property var identities: flow?.identities ?? []

    onVisibleChanged: {
        password.text = "";
        if (visible) Qt.callLater(() => password.focusInput());
    }
    // Al volver a pedir la contraseña (tras un intento fallido), foco y campo vacío
    Connections {
        target: win.flow
        function onIsResponseRequiredChanged() {
            if (win.flow.isResponseRequired) {
                password.text = "";
                password.focusInput();
            }
        }
    }

    function submit() {
        if (!flow || waiting || password.text === "") return;
        flow.submit(password.text);
        password.text = "";
    }

    // Nombre de una identidad: el completo, o el de usuario/grupo
    function nameOf(id) {
        if (!id) return "";
        const name = id.displayName || id.string || String(id.id);
        return id.isGroup ? `Grupo ${name}` : name;
    }
    // Mensajes de polkit (en inglés) que se conocen, en español
    function message(text) {
        return text
            .replace(/^Authentication is needed to run [`'"](.+)[`'"] as the super user$/i, "Para ejecutar «$1» como administrador")
            .replace(/^Authentication is needed to run [`'"](.+)[`'"] as user (.+)$/i, "Para ejecutar «$1» como el usuario $2")
            .replace(/^Authentication is required to (.+?)\.?$/i, "Hace falta tu contraseña para: $1");
    }
    // Texto de polkit (en inglés) que se conoce, en español
    function es(text) {
        return (text ?? "").replace(/^Password:\s*$/i, "Contraseña").replace(/:\s*$/, "");
    }

    // --- Cabecera ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        Rectangle {
            implicitWidth: 48
            implicitHeight: 48
            radius: 24
            color: Design.tonal
            Icon {
                anchors.centerIn: parent
                text: Theme.iLock
                color: Design.onTonal
                font.pixelSize: 22
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Txt {
                text: "Se necesita autorización"
                textStyle: Design.title
            }
            Txt {
                Layout.fillWidth: true
                text: win.message(win.flow?.message ?? "")
                wrapMode: Text.Wrap
                color: Design.onSurfaceVariant
            }
        }
    }

    // --- Quién autoriza ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Avatar {
            size: 32
            readonly property bool me: (win.flow?.selectedIdentity?.string ?? "") === Profile.user
            source: me ? Profile.avatarUrl : ""
            initial: win.nameOf(win.flow?.selectedIdentity).charAt(0).toUpperCase()
        }
        Txt {
            Layout.fillWidth: true
            text: win.nameOf(win.flow?.selectedIdentity)
            textStyle: Design.headline
        }
        // Varias identidades: elegir con quién
        Repeater {
            model: win.identities.length > 1 ? win.identities : []
            Chip {
                required property var modelData
                text: win.nameOf(modelData)
                selected: modelData === win.flow?.selectedIdentity
                onClicked: win.flow.selectedIdentity = modelData
            }
        }
    }

    // --- Contraseña ---
    Field {
        id: password
        Layout.fillWidth: true
        big: true
        icon: Theme.iKey
        placeholder: win.es(win.flow?.inputPrompt) || "Contraseña"
        echoMode: win.flow?.responseVisible ? TextInput.Normal : TextInput.Password
        enabled: !win.waiting
        onKeyPressed: e => {
            if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) win.submit();
            else if (e.key === Qt.Key_Escape) win.closeRequested();
            else return;
            e.accepted = true;
        }
    }

    // Avisos: contraseña incorrecta o mensajes de polkit
    Txt {
        Layout.fillWidth: true
        visible: text !== ""
        text: win.flow?.failed ? "Contraseña incorrecta, inténtalo de nuevo"
            : win.waiting ? "Comprobando…"
            : win.flow?.supplementaryMessage ?? ""
        color: win.flow?.failed || win.flow?.supplementaryIsError ? Design.error : Design.onSurfaceVariant
        wrapMode: Text.Wrap
    }

    // --- Botones y la acción que se autoriza ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Txt {
            Layout.fillWidth: true
            text: win.flow?.actionId ?? ""
            textStyle: Design.caption
            color: Design.muted
        }
        Btn {
            kind: "outline"
            text: "Cancelar"
            onClicked: win.closeRequested()
        }
        Btn {
            kind: "filled"
            text: "Autenticar"
            onClicked: win.submit()
        }
    }
}
