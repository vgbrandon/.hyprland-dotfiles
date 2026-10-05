#version 440
// Marco de vidrio para paneles: relleno translúcido con un degradado suave y un
// brillo en el borde (luz desde arriba a la izquierda). El desenfoque de lo que
// hay detrás lo pone Hyprland (layer rules con blur en hyprland.lua).
// Compilar: /usr/lib/qt6/bin/qsb --qt6 -o glassframe.frag.qsb glassframe.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    float radius;
    vec4 fill;      // color del vidrio (con alfa)
    float rim;      // intensidad del brillo del borde
};

float sdRoundRect(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
    vec2 half_ = itemSize * 0.5;
    vec2 c = qt_TexCoord0 * itemSize - half_;
    float r = min(radius, min(half_.x, half_.y));
    float d = sdRoundRect(c, half_, r);

    vec2 e = vec2(1.0, 0.0);
    vec2 n = vec2(sdRoundRect(c + e.xy, half_, r) - sdRoundRect(c - e.xy, half_, r),
                  sdRoundRect(c + e.yx, half_, r) - sdRoundRect(c - e.yx, half_, r));
    n = n / max(length(n), 1e-4);

    // Relleno un poco más claro arriba (sensación de grosor)
    vec3 col = fill.rgb + vec3(0.06) * (1.0 - qt_TexCoord0.y);
    float a = fill.a;

    // Brillo: línea fina en el borde, más fuerte arriba a la izquierda, y un
    // resplandor interior suave
    float line = 1.0 - smoothstep(0.0, 1.6, -d);
    float glow = 1.0 - smoothstep(0.0, 14.0, -d);
    float light = clamp(dot(n, normalize(vec2(-0.6, -0.8))), 0.0, 1.0);
    float highlight = rim * (line * (0.25 + 0.6 * light) + glow * 0.06);
    col += highlight;
    a = min(1.0, a + highlight);

    float mask = 1.0 - smoothstep(-1.0, 0.5, d);
    fragColor = vec4(col * a, a) * mask * qt_Opacity;
}
