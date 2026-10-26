import QtQuick
import QtQuick.Layouts

// Paso «El tema»: cada papel y de qué color del generador sale (o «calculado»), en
// armonía análoga y con la regla 60-30-10. Con tokens: true, cada papel dice también qué
// token de Design lo usa (lo muestra la guía de estilo).
GuideStep {
    id: step
    // Un PaletteData
    property var data
    property bool tokens: false
    readonly property var r: data ? data.r : null
    readonly property var org: data ? data.org : null

    function role(key, name, token) {
        return tokens ? [key, name, token] : [key, name];
    }

    visible: !!r
    title: "El tema"
    subtitle: "Cada papel y de qué color del generador sale. «Calculado» = la imagen no tenía un color ahí y se deriva del tono base."

    GuideLabel { text: "Los tonos (10 %: lo que destaca)" }
    RowLayout {
        Layout.fillWidth: true
        spacing: 18
        Repeater {
            model: step.r && step.org ? [
                { from: step.org.base, to: step.r.accent, n: "Acento", d: "Lo principal: botones, interruptores, lo lleno", t: "accent" },
                { from: step.org.second, to: step.r.accent2, n: "Acento 2", d: "Vecino análogo, más apagado: lo que suena", t: "second" },
                { from: step.org.third, to: step.r.accent3, n: "Acento 3", d: "El otro vecino: recursos, enlaces", t: "third" }
            ] : []
            FromCard {
                required property var modelData
                Layout.fillWidth: true
                from: modelData.from
                to: modelData.to
                name: modelData.n
                detail: modelData.d
                token: step.tokens ? modelData.t : ""
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 24

        RoleGroup {
            Layout.fillWidth: true
            source: step.r
            label: "Neutros (60 %) · del tono base, casi grises"
            roles: step.r ? [
                step.role("background", "Fondo", "background"), step.role("surface1", "Superficie", "surface1"),
                step.role("surface3", "Elevado", "surface3"), step.role("outlineVariant", "Separador", "outlineVariant"),
                step.role("outline", "Contorno", "outline"), step.role("subtext", "Texto 2.º", "onSurfaceVariant"),
                step.role("text", "Texto", "onSurface")
            ] : []
        }
        RoleGroup {
            Layout.preferredWidth: 260
            source: step.r
            label: "Profundo (30 %) · lo encendido"
            roles: step.r ? [
                step.role("container", "Contenedor", "accentContainer"), step.role("onContainer", "Sobre él", "onAccentContainer"),
                step.role("hi", "Énfasis suave", "hi")
            ] : []
        }
        RoleGroup {
            Layout.preferredWidth: 300
            source: step.r
            label: "Estados · apagados, hacia el tono base"
            roles: step.r ? [
                step.role("error", "Error", "error"), step.role("warning", "Aviso", "warning"),
                step.role("success", "Éxito", "success"), step.role("info", "Info", "info")
            ] : []
        }
    }

    GuideLabel { text: "Degradado del visualizador (vecino 3 → acento → vecino 2, de profundo a claro)" + (step.tokens ? "  ·  Design.gradient" : "") }
    Row {
        spacing: 0
        Repeater {
            model: step.r ? step.r.gradient : []
            Rectangle { required property string modelData; width: 72; height: 22; color: modelData }
        }
    }
}
