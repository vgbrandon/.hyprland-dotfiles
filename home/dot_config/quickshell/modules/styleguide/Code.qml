import QtQuick
import qs.services

// Texto monoespaciado coloreado con los papeles de la paleta, para las vistas previas de
// las apps (terminal, editor). lines: una lista de líneas y cada línea, de trozos
// [papel, texto] o [papel, texto, papel del fondo]. Papel: «accent», «term_red»…
Text {
    property var lines: []
    property int size: 12

    function col(role) {
        return Theme.scheme[role.startsWith("term_") ? role : "p_" + role] ?? "#808080";
    }
    function esc(s) {
        return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/ /g, "&nbsp;");
    }

    textFormat: Text.RichText
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: size
    lineHeight: 1.3
    text: lines.map(l => l.map(p => `<span style="color:${col(p[0])}${p[2] ? ";background-color:" + col(p[2]) : ""}">${esc(p[1])}</span>`).join("")).join("<br>")
}
