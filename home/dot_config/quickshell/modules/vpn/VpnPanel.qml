import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.containers
import qs.components.controls
import qs.components.design
import qs.services

// Panel de la VPN (clic en el escudo de la barra; la lógica está en services/Vpn.qml):
// estado (servidor, carga, protocolo e IP pública), conectar o desconectar y los ajustes
// que permite el plan (kill switch e IPv6). Si el llavero está bloqueado, lo ofrece
// desbloquear con el diálogo de contraseña.
BarPopup {
    id: panel

    onVisibleChanged: if (visible) Vpn.refresh()

    readonly property string stateIcon: Vpn.locked ? Theme.iShieldLock
        : Vpn.busy ? Theme.iShieldSync
        : Vpn.connected ? Theme.iShieldCheck : Theme.iShieldOff

    PanelHeader {
        Layout.rightMargin: 4
        icon: panel.stateIcon
        iconColor: Vpn.connected ? Design.accent : Design.onSurface
        title: "VPN"
        subtitle: Vpn.action === "connect" ? "Conectando…"
            : Vpn.action === "disconnect" ? "Desconectando…"
            : Vpn.connected ? "Protegido" : "Sin proteger"

        Switch {
            // Pasa enseguida a lo pedido; mientras Proton trabaja, el servicio ignora más
            // pulsaciones
            checked: Vpn.wanted
            enabled: !Vpn.locked
            onToggled: Vpn.toggle()
        }
    }

    // --- Estado ---
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: stateRow.implicitHeight + 28
        radius: Design.radiusMd
        color: Vpn.connected ? Design.accentContainer : Design.surface1
        border.color: Design.border
        Behavior on color { ColorAnimation { duration: Design.normal } }

        RowLayout {
            id: stateRow
            x: 14
            y: 14
            width: parent.width - 28
            spacing: 14

            Rectangle {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 44
                implicitHeight: 44
                radius: 22
                color: Vpn.connected ? Design.accent : Design.surface3
                Icon {
                    anchors.centerIn: parent
                    text: panel.stateIcon
                    font.pixelSize: 22
                    color: Vpn.connected ? Design.onAccent : Design.onSurfaceVariant
                }
            }
            ColumnLayout {
                id: stateCol
                Layout.fillWidth: true
                spacing: 3
                Txt {
                    Layout.fillWidth: true
                    text: Vpn.connected ? Vpn.server : "Tu conexión va sin VPN"
                    textStyle: Design.headline
                    color: Vpn.connected ? Design.onAccentContainer : Design.onSurface
                    elide: Text.ElideRight
                }
                Txt {
                    Layout.fillWidth: true
                    visible: Vpn.connected && Vpn.location !== ""
                    text: Vpn.location
                    color: Vpn.connected ? Design.onAccentContainer : Design.onSurfaceVariant
                    elide: Text.ElideRight
                }
                Txt {
                    Layout.fillWidth: true
                    visible: Vpn.connected && (Vpn.load >= 0 || Vpn.protocol !== "")
                    text: [Vpn.load >= 0 ? "Carga " + Vpn.load + " %" : "", Vpn.protocol === "wireguard" ? "WireGuard" : Vpn.protocol]
                        .filter(x => x).join("  ·  ")
                    textStyle: Design.caption
                    color: Vpn.connected ? Design.onAccentContainer : Design.onSurfaceVariant
                    opacity: 0.85
                }
                Txt {
                    Layout.fillWidth: true
                    visible: Vpn.ip !== ""
                    text: "IP pública " + Vpn.ip + (Vpn.ipPlace !== "" ? "  ·  " + Vpn.ipPlace : "")
                    textStyle: Design.caption
                    color: Vpn.connected ? Design.onAccentContainer : Design.onSurfaceVariant
                    opacity: 0.85
                    font.features: { "tnum": 1 }
                }
            }
        }
    }

    // --- El llavero bloqueado ---
    Rectangle {
        visible: Vpn.locked
        Layout.fillWidth: true
        implicitHeight: lockCol.implicitHeight + 24
        radius: Design.radiusMd
        color: Design.alpha(Design.warning, 0.1)
        border.color: Design.alpha(Design.warning, 0.4)
        ColumnLayout {
            id: lockCol
            x: 12
            y: 12
            width: parent.width - 24
            spacing: 10
            Txt {
                Layout.fillWidth: true
                text: "Proton guarda tu sesión en el llavero del sistema, que está bloqueado. Desbloquéalo con tu contraseña para continuar."
                wrapMode: Text.Wrap
                textStyle: Design.caption
            }
            Btn {
                kind: "filled"
                icon: Theme.iShieldKey
                text: Vpn.unlocking ? "¿No sale? Volver a pedirla" : "Desbloquear el llavero"
                onClicked: Vpn.unlock()
            }
        }
    }

    // --- Conectar / desconectar ---
    Btn {
        visible: !Vpn.locked
        Layout.fillWidth: true
        kind: Vpn.connected ? "tonal" : "filled"
        icon: Vpn.connected ? Theme.iShieldOff : Theme.iShieldCheck
        text: Vpn.action === "connect" ? "Conectando…"
            : Vpn.action === "disconnect" ? "Desconectando…"
            : Vpn.connected ? "Desconectar" : "Conectar al más rápido"
        onClicked: Vpn.toggle()
    }

    Txt {
        visible: Vpn.notice !== ""
        Layout.fillWidth: true
        text: Vpn.notice
        color: Design.error
        wrapMode: Text.Wrap
        textStyle: Design.caption
    }

    // --- Ajustes ---
    Section {
        title: "Ajustes"
        SwitchRow {
            icon: Theme.iShieldLock
            text: "Kill switch"
            checked: Vpn.killSwitch
            onToggled: Vpn.setKillSwitch(!Vpn.killSwitch)
        }
        SwitchRow {
            icon: Theme.iWeb
            text: "IPv6"
            checked: Vpn.ipv6
            onToggled: Vpn.setIpv6(!Vpn.ipv6)
        }
    }

    Txt {
        Layout.fillWidth: true
        visible: Vpn.free
        text: "Plan gratuito: Proton elige el servidor gratis más rápido (10 países). Elegir país, P2P, Secure Core y Tor son de los planes de pago."
        wrapMode: Text.Wrap
        textStyle: Design.caption
        color: Design.muted
    }
    Txt {
        Layout.fillWidth: true
        visible: Vpn.account !== ""
        text: "Cuenta: " + Vpn.account
        textStyle: Design.caption
        color: Design.muted
        elide: Text.ElideMiddle
    }
}
