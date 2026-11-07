import QtQuick
import QtQuick.Layouts

// Paso «El tema»: cada token y de qué color de la imagen sale (o «calculado»), con
// la armonía de la imagen y la regla 60-30-10. Con tokens: true, cada uno dice también qué
// propiedad de Design lo usa.
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
    subtitle: "Cada token y de qué color de la imagen sale. «Calculado» = la imagen no tenía un color ahí y se deriva de la armonía."

    GuideLabel { text: "Los tonos (10 %: lo que destaca)" }
    RowLayout {
        Layout.fillWidth: true
        spacing: 18
        Repeater {
            model: step.r && step.org ? [
                { from: step.org.primary, to: step.r.primary, n: "Primario", d: "Lo principal: botones, interruptores, lo lleno", t: "accent" },
                { from: step.org.secondary, to: step.r.secondary, n: "Secundario", d: "Según la armonía de la imagen: lo que suena", t: "second" },
                { from: step.org.tertiary, to: step.r.tertiary, n: "Terciario", d: "Según la armonía de la imagen: recursos, enlaces", t: "third" }
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
                step.role("bg", "Fondo", "background"), step.role("surface", "Superficie", "surface1"),
                step.role("overlay", "Elevado", "surface3"), step.role("border", "Separador", "outlineVariant"),
                step.role("outline", "Contorno", "outline"), step.role("subtext", "Texto 2.º", "onSurfaceVariant"),
                step.role("text", "Texto", "onSurface")
            ] : []
        }
        RoleGroup {
            Layout.preferredWidth: 260
            source: step.r
            label: "Profundo (30 %) · lo encendido"
            roles: step.r ? [
                step.role("primary_container", "Contenedor", "accentContainer"), step.role("on_primary_container", "Sobre él", "onAccentContainer"),
                step.role("emphasis", "Énfasis suave", "hi")
            ] : []
        }
        RoleGroup {
            Layout.preferredWidth: 300
            source: step.r
            label: "Estados · reconocibles y separados de los acentos"
            roles: step.r ? [
                step.role("error", "Error", "error"), step.role("warning", "Aviso", "warning"),
                step.role("success", "Éxito", "success"), step.role("info", "Info", "info")
            ] : []
        }
    }

    GuideLabel { text: "Degradado del visualizador (hacia el terciario → primario → hacia el secundario, de profundo a claro)" + (step.tokens ? "  ·  Design.gradient" : "") }
    Row {
        spacing: 0
        Repeater {
            model: step.r ? Array.from({ length: 8 }, (_, i) => step.r["gradient_" + i]) : []
            Rectangle { required property string modelData; width: 72; height: 22; color: modelData }
        }
    }
}
