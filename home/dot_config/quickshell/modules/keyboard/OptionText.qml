import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.components.design
import qs.services

// Opción con título, explicación y lo que se ponga a la derecha (un botón)
RowLayout {
    id: ot
    property string title
    property string subtitle
    default property alias trailing: trail.data

    Layout.fillWidth: true
    spacing: 12
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Txt { Layout.fillWidth: true; text: ot.title }
        Txt {
            Layout.fillWidth: true
            text: ot.subtitle
            textStyle: Design.caption
            color: Design.onSurfaceVariant
            wrapMode: Text.Wrap
        }
    }
    RowLayout {
        id: trail
    }
}
