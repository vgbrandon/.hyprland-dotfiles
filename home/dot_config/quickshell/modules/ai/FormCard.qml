import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.base
import qs.services

// Pregunta del agente (formulario de OpenCode): un campo por pregunta.
//   string con opciones → botones (y texto libre si "custom") · string → texto
//   boolean → interruptor · number / integer → número · multiselect → varias opciones
//   external → botón que abre la dirección
// Responder envía todas las respuestas; Omitir cancela la pregunta.
Rectangle {
    id: root

    required property var form

    // Respuestas: { clave: valor }
    property var answer: {
        const a = {};
        for (const f of form.fields ?? []) {
            if (f.default !== undefined) a[f.key] = f.default;
            else if (f.type === "boolean") a[f.key] = false;
            else if (f.type === "multiselect") a[f.key] = [];
        }
        return a;
    }
    function set(key, value) {
        const a = Object.assign({}, answer);
        a[key] = value;
        answer = a;
    }
    // Campos visibles (los "when" dependen de otras respuestas)
    function shown(f) {
        if (f.hidden) return false;
        return (f.when ?? []).every(w => w.op === "eq" ? answer[w.key] === w.value : answer[w.key] !== w.value);
    }
    readonly property bool complete: (form.fields ?? []).every(f => !shown(f) || !f.required
        || (answer[f.key] !== undefined && answer[f.key] !== "" && !(Array.isArray(answer[f.key]) && answer[f.key].length === 0)))

    implicitHeight: column.implicitHeight + 20
    radius: Theme.radiusSmall
    color: Theme.withAlpha(Theme.primary, 0.08)
    border.color: Theme.withAlpha(Theme.primary, 0.45)
    border.width: 1

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 10
        anchors.leftMargin: 12
        spacing: 10

        RowLayout {
            spacing: 8
            Icon {
                text: Theme.iOpenCode
                color: Theme.primary
                font.pixelSize: 15
            }
            Label {
                Layout.fillWidth: true
                // OpenCode titula "Questions" a las preguntas del agente
                text: !root.form.title || root.form.title === "Questions" ? "El agente pregunta" : root.form.title
                wrapMode: Text.Wrap
                font.weight: Font.DemiBold
            }
        }

        Repeater {
            model: root.form.fields ?? []

            ColumnLayout {
                id: field
                required property var modelData
                readonly property var f: modelData
                visible: root.shown(f)
                Layout.fillWidth: true
                spacing: 6

                Label {
                    visible: (field.f.title ?? "") !== ""
                    Layout.fillWidth: true
                    text: field.f.title + (field.f.required ? " *" : "")
                    wrapMode: Text.Wrap
                }
                Label {
                    visible: (field.f.description ?? "") !== ""
                    Layout.fillWidth: true
                    text: field.f.description ?? ""
                    wrapMode: Text.Wrap
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                }

                // Opciones (una o varias)
                Flow {
                    visible: (field.f.options ?? []).length > 0
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: field.f.options ?? []

                        Chip {
                            required property var modelData
                            readonly property var value: root.answer[field.f.key]
                            text: modelData.label
                            // Más marcadas que en el resto del panel: se ven como botones sobre la tarjeta
                            color: selected ? Theme.primary : Theme.surfaceHigh
                            selected: field.f.type === "multiselect" ? (value ?? []).includes(modelData.value) : value === modelData.value
                            onClicked: {
                                if (field.f.type === "multiselect") {
                                    const cur = (value ?? []).slice();
                                    const i = cur.indexOf(modelData.value);
                                    if (i >= 0) cur.splice(i, 1);
                                    else cur.push(modelData.value);
                                    root.set(field.f.key, cur);
                                } else {
                                    root.set(field.f.key, modelData.value);
                                }
                            }
                        }
                    }
                }

                // Texto o número (si no hay opciones, o si admite una respuesta propia)
                Rectangle {
                    visible: ["string", "number", "integer"].includes(field.f.type)
                        && ((field.f.options ?? []).length === 0 || field.f.custom === true)
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Design.radiusSm
                    color: Theme.surface
                    border.color: textField.activeFocus ? Theme.withAlpha(Theme.primary, 0.5) : Theme.surfaceHigh
                    border.width: 1

                    TextInput {
                        id: textField
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        color: Theme.text
                        selectionColor: Theme.withAlpha(Theme.primary, 0.4)
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 1
                        inputMethodHints: field.f.type === "string" ? Qt.ImhNone : Qt.ImhFormattedNumbersOnly
                        onTextEdited: {
                            if (field.f.type === "string") root.set(field.f.key, text);
                            else if (text.trim() === "") root.set(field.f.key, undefined);
                            else root.set(field.f.key, field.f.type === "integer" ? parseInt(text) : parseFloat(text));
                        }

                        Text {
                            visible: textField.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: field.f.placeholder ?? ((field.f.options ?? []).length > 0 ? "Otra respuesta…" : "Respuesta…")
                            color: Theme.subtext
                            font: textField.font
                        }
                    }
                }

                // Sí / no
                RowLayout {
                    visible: field.f.type === "boolean"
                    spacing: 10
                    Switch {
                        checked: root.answer[field.f.key] === true
                        onToggled: root.set(field.f.key, !(root.answer[field.f.key] === true))
                    }
                    Label {
                        text: root.answer[field.f.key] === true ? "Sí" : "No"
                        color: Theme.subtext
                    }
                }

                // Enlace externo
                TextButton {
                    visible: field.f.type === "external"
                    small: true
                    icon: Theme.iChevronRight
                    text: "Abrir"
                    onClicked: Qt.openUrlExternally(field.f.url)
                }
            }
        }

        RowLayout {
            spacing: 6
            Item { Layout.fillWidth: true }
            TextButton {
                small: true
                flat: true
                text: "Omitir"
                onClicked: AI.cancelForm(root.form)
            }
            TextButton {
                small: true
                accent: true
                text: "Responder"
                enabled: root.complete
                onClicked: {
                    // Sin los campos ocultos ni los vacíos
                    const a = {};
                    for (const f of root.form.fields ?? [])
                        if (root.shown(f) && root.answer[f.key] !== undefined && root.answer[f.key] !== "") a[f.key] = root.answer[f.key];
                    AI.replyForm(root.form, a);
                }
            }
        }
    }
}
