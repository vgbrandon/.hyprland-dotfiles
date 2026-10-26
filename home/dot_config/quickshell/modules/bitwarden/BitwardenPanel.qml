import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.containers
import qs.components.design
import qs.services

// Panel de Bitwarden (Super + B o el logo de la barra), diseño Velure. Según el estado:
// falta rbw, primera vez (correo), bóveda cerrada, pregunta de rbw (contraseña maestra,
// 2FA…), la bóveda con buscador o el generador. La lógica está en services/Bitwarden.qml;
// el panel sigue a Bitwarden.open (lo abre el IPC o una pregunta de rbw).
//   Bóveda: ↑ ↓ o Ctrl + j/k = moverse · Enter = copiar la contraseña · Ctrl + U = el
//   usuario (o correo) · Ctrl + T = el código 2FA
//   Ctrl + G = generador · Ctrl + R = sincronizar · Ctrl + L = cerrar la bóveda
//   quickshell ipc call bitwarden toggle
BarPopup {
    id: win

    padding: 12
    spacing: 12
    maxHeight: 640
    // Con una pregunta de rbw se puede ir a otra ventana (p. ej. a copiar la clave de la
    // API en el navegador) sin que se cierre; al volver, un clic en el panel recupera el foco
    keepOpen: view === "pin"

    // El panel y Bitwarden.open van juntos
    onVisibleChanged: {
        if (visible) Bitwarden.open = true;
        else Bitwarden.open = false;
    }
    onClosingChanged: if (closing) Bitwarden.open = false
    Connections {
        target: Bitwarden
        function onOpenChanged() {
            if (Bitwarden.open && !win.visible) win.toggleOnMainScreen();
            else if (!Bitwarden.open && win.visible) win.close();
        }
    }

    // "setup" | "pin" | "locked" | "vault" | "generator" | "missing" | "loading"
    readonly property string view: !Bitwarden.checked ? "loading"
        : !Bitwarden.installed ? "missing"
        : Bitwarden.pin ? "pin"
        : generatorOn ? "generator"
        : Bitwarden.email === "" ? "setup"
        : !Bitwarden.unlocked ? "locked" : "vault"
    property bool generatorOn: false
    readonly property var selectedItem: Bitwarden.results[list.currentIndex] ?? null

    // Al cerrar se guarda la búsqueda un minuto: copias el usuario, lo pegas, vuelves a
    // abrir y sigue elegida la misma entrada para copiar la contraseña
    onReadyChanged: {
        if (ready) {
            resetTimer.stop();
            focusView();
        } else {
            pinField.text = "";
            masterField.text = "";
            resetTimer.restart();
        }
    }
    Timer {
        id: resetTimer
        interval: 60000
        onTriggered: {
            search.text = "";
            win.generatorOn = false;
            list.currentIndex = 0;
        }
    }
    readonly property bool ready: visible && !closing
    onViewChanged: Qt.callLater(focusView)
    function focusView() {
        if (view === "vault") search.focusInput();
        else if (view === "pin") pinField.focusInput();
        else if (view === "setup") mailField.focusInput();
        else if (view === "locked") masterField.focusInput();
        else keys.forceActiveFocus();
    }

    // Teclas cuando no hay campo de texto (bóveda cerrada, generador…)
    Item {
        id: keys
        Layout.preferredHeight: 0
        Keys.onPressed: e => win.commonKey(e)
    }
    function commonKey(e) {
        const ctrl = e.modifiers & Qt.ControlModifier;
        if (e.key === Qt.Key_Escape) {
            if (generatorOn && Bitwarden.unlocked) generatorOn = false;
            else Bitwarden.open = false;
        } else if (ctrl && e.key === Qt.Key_G && view !== "pin") {
            generatorOn = !generatorOn;
            if (generatorOn && Bitwarden.generated === "") regenerate();
        } else if (view === "generator" && (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)) {
            Bitwarden.copyGenerated();
        } else if (view === "generator" && e.key === Qt.Key_Space) {
            regenerate();
        } else {
            return false;
        }
        e.accepted = true;
        return true;
    }

    // --- Cabecera ---
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 10

        Icon {
            text: Theme.iBitwarden
            color: Bitwarden.unlocked ? Design.accent : Design.onSurfaceVariant
            font.pixelSize: 22
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Txt {
                text: "Bitwarden"
                textStyle: Design.headline
            }
            Txt {
                Layout.fillWidth: true
                visible: text !== ""
                text: Bitwarden.busy !== "" ? Bitwarden.busy
                    : confirmSwitch.running ? "Pulsa otra vez para cambiar de cuenta"
                    : Bitwarden.error !== "" ? Bitwarden.error
                    : Bitwarden.email
                textStyle: Design.caption
                color: Bitwarden.busy === "" && (confirmSwitch.running || Bitwarden.error !== "") ? Design.error : Design.onSurfaceVariant
            }
        }
        IconBtn {
            visible: Bitwarden.unlocked
            icon: Theme.iRefresh
            onClicked: Bitwarden.sync()
        }
        IconBtn {
            visible: Bitwarden.unlocked
            icon: Theme.iLock
            onClicked: Bitwarden.lock()
        }
        // Cambiar de cuenta (segundo clic en 3 s para confirmar)
        IconBtn {
            visible: Bitwarden.email !== "" && win.view !== "pin"
            icon: Theme.iLogout
            iconColor: confirmSwitch.running ? Design.error : Design.onSurfaceVariant
            onClicked: {
                if (confirmSwitch.running) {
                    confirmSwitch.stop();
                    win.generatorOn = false;
                    Bitwarden.switchAccount();
                } else {
                    confirmSwitch.start();
                }
            }
            Timer {
                id: confirmSwitch
                interval: 3000
            }
        }
    }

    Segmented {
        visible: Bitwarden.installed && win.view !== "pin"
        Layout.fillWidth: true
        options: ["Bóveda", "Generador"]
        current: win.generatorOn ? 1 : 0
        follow: false
        onSelected: i => {
            win.generatorOn = i === 1;
            if (win.generatorOn && Bitwarden.generated === "") win.regenerate();
        }
    }

    // --- Falta rbw ---
    Message {
        visible: win.view === "missing"
        icon: Theme.iAlert
        title: "Falta rbw"
        text: "Instálalo con  sudo pacman -S rbw"
    }
    Message {
        visible: win.view === "loading"
        icon: Theme.iLock
        title: "Cargando…"
    }

    // --- Primera vez: el correo de la cuenta ---
    ColumnLayout {
        visible: win.view === "setup"
        Layout.fillWidth: true
        Layout.margins: 20
        spacing: 12

        Txt {
            text: "Inicia sesión en Bitwarden"
            textStyle: Design.title
        }
        Txt {
            Layout.fillWidth: true
            text: "Escribe el correo de tu cuenta (bitwarden.com). Luego se pedirá la contraseña maestra y, si la tienes, la verificación en dos pasos. Si es la primera vez en este equipo, Bitwarden pedirá la clave de la API (client_id y client_secret, en la web: Ajustes → Seguridad → Claves)."
            wrapMode: Text.Wrap
            color: Design.onSurfaceVariant
        }
        RowLayout {
            spacing: 8
            Field {
                id: mailField
                Layout.fillWidth: true
                icon: Theme.iAccount
                placeholder: "correo@ejemplo.com"
                onKeyPressed: e => {
                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) Bitwarden.setup(mailField.text);
                    else if (!win.commonKey(e)) return;
                    e.accepted = true;
                }
            }
            Btn {
                kind: "filled"
                text: "Continuar"
                onClicked: Bitwarden.setup(mailField.text)
            }
        }
    }

    // --- Bóveda cerrada: la contraseña maestra aquí mismo ---
    ColumnLayout {
        visible: win.view === "locked"
        Layout.fillWidth: true
        Layout.topMargin: 14
        Layout.bottomMargin: 6
        spacing: 10

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 56
            implicitHeight: 56
            radius: 28
            color: Design.tonal
            Icon {
                anchors.centerIn: parent
                text: Theme.iLock
                color: Design.onTonal
                font.pixelSize: 26
            }
        }
        Txt {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "Bóveda cerrada"
            textStyle: Design.headline
        }
        Txt {
            Layout.fillWidth: true
            Layout.topMargin: -8
            Layout.bottomMargin: 6
            horizontalAlignment: Text.AlignHCenter
            text: "Escribe tu contraseña maestra para abrirla"
            textStyle: Design.caption
            color: Design.onSurfaceVariant
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Field {
                id: masterField
                Layout.fillWidth: true
                icon: Theme.iKey
                placeholder: "Contraseña maestra"
                echoMode: showMaster.checked ? TextInput.Normal : TextInput.Password
                onKeyPressed: e => {
                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) win.unlockNow();
                    else if (!win.commonKey(e)) return;
                    e.accepted = true;
                }
            }
            IconBtn {
                id: showMaster
                icon: checked ? Theme.iEyeOff : Theme.iEye
                onClicked: checked = !checked
            }
        }
        Btn {
            Layout.fillWidth: true
            kind: "filled"
            icon: Theme.iLockOpen
            text: Bitwarden.busy !== "" ? Bitwarden.busy : "Desbloquear"
            onClicked: win.unlockNow()
        }
    }
    function unlockNow() {
        if (Bitwarden.busy !== "" || masterField.text === "") return;
        Bitwarden.unlockWith(masterField.text);
        masterField.text = "";
        showMaster.checked = false;
    }

    // --- Pregunta de rbw (contraseña maestra, código 2FA…) ---
    ColumnLayout {
        visible: win.view === "pin"
        Layout.fillWidth: true
        Layout.margins: 20
        spacing: 12

        Txt {
            Layout.fillWidth: true
            text: win.es((Bitwarden.pin?.desc ?? "") || (Bitwarden.pin?.title ?? "")) || (/client/i.test(Bitwarden.pin?.prompt ?? "") ? "Verificar este equipo" : "Bitwarden pregunta")
            textStyle: Design.title
            wrapMode: Text.Wrap
        }
        RowLayout {
            spacing: 8
            Field {
                id: pinField
                Layout.fillWidth: true
                icon: Theme.iKey
                placeholder: win.es((Bitwarden.pin?.prompt ?? "").replace(/:\s*$/, "")) || "Contraseña"
                echoMode: showPin.checked ? TextInput.Normal : TextInput.Password
                onKeyPressed: e => {
                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) win.answer();
                    else if (e.key === Qt.Key_Escape) Bitwarden.cancelPin();
                    else return;
                    e.accepted = true;
                }
            }
            IconBtn {
                icon: Theme.iClipboard
                onClicked: pinField.paste()
            }
            IconBtn {
                id: showPin
                icon: checked ? Theme.iEyeOff : Theme.iEye
                onClicked: checked = !checked
            }
        }
        // Dónde está la clave de la API (la pide rbw register)
        Txt {
            visible: /client/i.test(Bitwarden.pin?.prompt ?? "")
            Layout.fillWidth: true
            text: "Bitwarden pide verificar este equipo. La clave está en vault.bitwarden.com → Ajustes → Seguridad → Claves → «Ver clave de la API» (client_id y client_secret). Puedes ir al navegador a copiarla sin que esto se cierre y pegarla con el botón del portapapeles."
            wrapMode: Text.Wrap
            color: Design.onSurfaceVariant
        }
        Txt {
            visible: text !== ""
            Layout.fillWidth: true
            text: win.es(Bitwarden.pin?.error ?? "")
            color: Design.error
            wrapMode: Text.Wrap
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 8
            Btn {
                kind: "outline"
                text: "Cancelar"
                onClicked: Bitwarden.cancelPin()
            }
            Btn {
                kind: "filled"
                text: "Aceptar"
                onClicked: win.answer()
            }
        }
    }
    // Los textos de rbw (en inglés) que se conocen, en español
    function es(text) {
        return text
            .replace(/^Please enter the master password for (.*)$/i, "Escribe la contraseña maestra de $1")
            .replace(/^Master Password$/i, "Contraseña maestra")
            .replace(/^Enter the 6 digit verification code from your authenticator app\.?$/i, "Escribe el código de 6 cifras de tu app de autenticación")
            .replace(/^Enter the .*code.*email.*$/i, "Escribe el código que te llegó por correo")
            .replace(/^Authenticator App$/i, "Código 2FA")
            .replace(/^(Email )?Code$/i, "Código")
            .replace(/^API key client__?id$/i, "client_id de la clave de la API")
            .replace(/^API key client__?secret$/i, "client_secret de la clave de la API")
            .replace(/^Log in to (.*)$/i, "Iniciar sesión en $1")
            .replace(/^Incorrect password\.?.*$/i, "Contraseña incorrecta")
            .replace(/^Invalid code\.?.*$/i, "Código incorrecto");
    }
    function answer() {
        // Las claves de la API no llevan espacios: se quitan los que se cuelan al pegar
        const key = /client/i.test(Bitwarden.pin?.prompt ?? "");
        Bitwarden.answerPin(key ? pinField.text.replace(/\s+/g, "") : pinField.text);
        pinField.text = "";
        showPin.checked = false;
    }

    // --- Bóveda ---
    Field {
        id: search
        visible: win.view === "vault"
        Layout.fillWidth: true
        big: true
        icon: Theme.iSearch
        placeholder: Bitwarden.items.length > 0 ? `Buscar en ${Bitwarden.items.length} ${Bitwarden.items.length === 1 ? "entrada" : "entradas"}…` : "Buscar en la bóveda…"
        onTextChanged: Bitwarden.query = text
        onKeyPressed: e => {
            const ctrl = e.modifiers & Qt.ControlModifier;
            const enter = e.key === Qt.Key_Return || e.key === Qt.Key_Enter;
            const n = list.count;
            if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab || ctrl && (e.key === Qt.Key_J || e.key === Qt.Key_N)) {
                if (n > 0) list.currentIndex = (list.currentIndex + 1) % n;
            } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab || ctrl && (e.key === Qt.Key_K || e.key === Qt.Key_P)) {
                if (n > 0) list.currentIndex = (list.currentIndex - 1 + n) % n;
            } else if (enter) {
                Bitwarden.copy(win.selectedItem, "password");
            } else if (ctrl && e.key === Qt.Key_U) {
                Bitwarden.copy(win.selectedItem, "username");
            } else if (ctrl && e.key === Qt.Key_T) {
                Bitwarden.copy(win.selectedItem, "totp");
            } else if (ctrl && e.key === Qt.Key_R) {
                Bitwarden.sync();
            } else if (ctrl && e.key === Qt.Key_L) {
                Bitwarden.lock();
            } else if (!win.commonKey(e)) {
                return;
            }
            e.accepted = true;
        }
    }

    ListView {
        id: list
        visible: win.view === "vault" && count > 0
        Layout.fillWidth: true
        implicitHeight: Math.min(contentHeight, 9 * 50)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Bitwarden.results
        highlightFollowsCurrentItem: false
        // Igual que en el lanzador: al cambiar los resultados, la primera; el ratón
        // solo selecciona si se mueve de verdad
        property point lastMouse: Qt.point(-2, -2)
        onModelChanged: {
            currentIndex = 0;
            lastMouse = Qt.point(-2, -2);
        }
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool selected: ListView.isCurrentItem

            width: list.width
            height: 50

            Rectangle {
                visible: row.selected
                anchors.fill: parent
                radius: Design.radiusSm
                color: Design.tonal
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: mouse => {
                    const p = mapToGlobal(mouse.x, mouse.y);
                    if (list.lastMouse.x === -2) {
                        list.lastMouse = p;
                        return;
                    }
                    if (p.x === list.lastMouse.x && p.y === list.lastMouse.y) return;
                    list.lastMouse = p;
                    list.currentIndex = row.index;
                }
                onClicked: Bitwarden.copy(row.modelData, "password")
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 12

                // Icono de la web; si no hay, la inicial (o el tipo, si no es un inicio de sesión)
                Rectangle {
                    id: badge
                    readonly property string icon: Bitwarden.iconOf(row.modelData)
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: Design.radiusSm
                    color: row.selected ? Design.alpha(Design.onTonal, 0.15) : Design.surface2
                    Image {
                        id: siteIcon
                        anchors.centerIn: parent
                        visible: badge.icon !== "" && status === Image.Ready
                        width: 20
                        height: 20
                        source: badge.icon
                        sourceSize: Qt.size(40, 40)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                    Txt {
                        anchors.centerIn: parent
                        visible: row.modelData.type === "Login" && !siteIcon.visible
                        text: (row.modelData.name ?? "?").charAt(0).toUpperCase()
                        textStyle: Design.headline
                        color: row.selected ? Design.onTonal : Design.onSurfaceVariant
                    }
                    Icon {
                        anchors.centerIn: parent
                        visible: row.modelData.type !== "Login"
                        text: row.modelData.type === "Note" ? Theme.iNote : row.modelData.type === "Identity" ? Theme.iAccount : Theme.iKey
                        color: row.selected ? Design.onTonal : Design.onSurfaceVariant
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Txt {
                        Layout.fillWidth: true
                        text: row.modelData.name ?? ""
                        color: row.selected ? Design.onTonal : Design.onSurface
                    }
                    Txt {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: [row.modelData.user, row.modelData.folder].filter(s => s).join(" · ")
                        textStyle: Design.caption
                        color: row.selected ? Design.alpha(Design.onTonal, 0.75) : Design.onSurfaceVariant
                    }
                }
                // Copiar de la seleccionada: usuario (o correo), contraseña y código 2FA
                Row {
                    visible: row.selected && row.modelData.type === "Login"
                    spacing: 2
                    RowAction {
                        visible: (row.modelData.user ?? "") !== ""
                        icon: Theme.iAccount
                        onClicked: Bitwarden.copy(row.modelData, "username")
                    }
                    RowAction {
                        icon: Theme.iKey
                        onClicked: Bitwarden.copy(row.modelData, "password")
                    }
                    RowAction {
                        icon: Theme.iTwoFactor
                        onClicked: Bitwarden.copy(row.modelData, "totp")
                    }
                }
            }
        }
    }
    Txt {
        visible: win.view === "vault" && list.count === 0
        Layout.alignment: Qt.AlignHCenter
        Layout.margins: 16
        text: Bitwarden.items.length === 0 ? "Cargando la bóveda…" : "Sin resultados"
        color: Design.onSurfaceVariant
    }
    // Atajos
    Flow {
        visible: win.view === "vault"
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 14
        Hint { keys: "↵"; text: "contraseña" }
        Hint { keys: "Ctrl U"; text: "usuario o correo" }
        Hint { keys: "Ctrl T"; text: "2FA" }
        Hint { keys: "Ctrl G"; text: "generador" }
        Hint { keys: "Ctrl L"; text: "cerrar" }
    }

    // --- Generador ---
    ColumnLayout {
        visible: win.view === "generator"
        Layout.fillWidth: true
        Layout.margins: 6
        spacing: 14

        // La contraseña
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 64
            radius: Design.radiusMd
            color: Design.surface0
            border.color: Design.outlineVariant

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 10
                spacing: 6
                Text {
                    Layout.fillWidth: true
                    text: Bitwarden.generated
                    color: Design.onSurface
                    font.family: Design.monoFont
                    font.pixelSize: 15
                    elide: Text.ElideRight
                }
                IconBtn {
                    icon: Theme.iRefresh
                    onClicked: win.regenerate()
                }
                IconBtn {
                    icon: Theme.iCopy
                    kind: "tonal"
                    onClicked: Bitwarden.copyGenerated()
                }
            }
        }
        Segmented {
            id: kind
            Layout.fillWidth: true
            options: ["Aleatoria", "Sin símbolos", "Números", "Palabras"]
            onCurrentChanged: {
                genLength.value = current === 3 ? 5 : current === 2 ? 6 : 20;
                win.regenerate();
            }
        }
        RowLayout {
            spacing: 14
            Txt {
                text: kind.current === 3 ? "Palabras" : "Largo"
                color: Design.onSurfaceVariant
            }
            Slide {
                Layout.fillWidth: true
                value: (genLength.value - genLength.min) / (genLength.max - genLength.min)
                onMoved: v => {
                    const n = Math.round(genLength.min + v * (genLength.max - genLength.min));
                    if (n === genLength.value) return;
                    genLength.value = n;
                    win.regenerate();
                }
            }
            Txt {
                Layout.preferredWidth: 28
                horizontalAlignment: Text.AlignRight
                text: genLength.value
                textStyle: Design.headline
                font.features: { "tnum": 1 }
            }
        }
        Flow {
            Layout.fillWidth: true
            spacing: 14
            Hint { keys: "↵"; text: "copiar" }
            Hint { keys: "Espacio"; text: "otra" }
            Hint { keys: "Esc"; text: Bitwarden.unlocked ? "volver" : "cerrar" }
        }
    }
    QtObject {
        id: genLength
        property int value: 20
        readonly property int min: kind.current === 3 ? 3 : 4
        readonly property int max: kind.current === 3 ? 12 : 64
    }
    Connections {
        target: Bitwarden
        function onGeneratorRequested() {
            win.generatorOn = true;
            if (Bitwarden.generated === "") win.regenerate();
        }
    }
    function regenerate() {
        Bitwarden.generate(["all", "nosymbols", "numbers", "words"][kind.current], genLength.value);
    }

    // Mensaje centrado con icono
    component Message: ColumnLayout {
        property string icon
        property string title
        property string text
        Layout.fillWidth: true
        Layout.margins: 30
        spacing: 8
        Icon {
            Layout.alignment: Qt.AlignHCenter
            text: parent.icon
            font.pixelSize: 32
            color: Design.onSurfaceVariant
        }
        Txt {
            Layout.alignment: Qt.AlignHCenter
            text: parent.title
            textStyle: Design.title
        }
        Txt {
            Layout.alignment: Qt.AlignHCenter
            visible: text !== ""
            text: parent.text
            color: Design.onSurfaceVariant
        }
    }

    // Botón pequeño de la fila seleccionada
    component RowAction: IconBtn {
        size: 30
        iconSize: 16
        iconColor: Design.onTonal
    }

    // Tecla y lo que hace
    component Hint: Row {
        property string keys
        property string text
        spacing: 6
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: keyText.implicitWidth + 12
            height: 20
            radius: Design.radiusXs
            color: Design.surface2
            border.color: Design.border
            Txt {
                id: keyText
                anchors.centerIn: parent
                text: parent.parent.keys
                textStyle: Design.caption
                color: Design.onSurfaceVariant
            }
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.text
            textStyle: Design.caption
            color: Design.muted
        }
    }
}
