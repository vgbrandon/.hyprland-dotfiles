import QtQuick
import Quickshell.Wayland
import qs.services

// Bloqueo de la sesión: una superficie por monitor mientras Lock.locked
WlSessionLock {
    locked: Lock.locked

    LockSurface {}
}
