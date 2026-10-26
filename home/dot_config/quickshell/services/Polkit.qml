pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// Agente de polkit de la sesión: cuando una app pide permisos de administrador
// (pkexec, montar discos, gestionar servicios…), polkit le pregunta aquí y la ventana
// modules/polkit/PolkitWindow.qml pide la contraseña. Sustituye al de polkit-gnome
// (solo puede haber un agente por sesión).
Singleton {
    id: root

    readonly property bool registered: agent.isRegistered
    // Petición en curso (AuthFlow) o null
    readonly property var flow: agent.isActive ? agent.flow : null

    PolkitAgent {
        id: agent
    }
}
