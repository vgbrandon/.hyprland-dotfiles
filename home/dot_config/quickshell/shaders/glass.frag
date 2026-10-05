#version 440
// Vidrio "liquid glass": muestra el fondo (ya desenfocado) detrás del elemento,
// lo refracta cerca del borde como un vidrio grueso, separa un poco los colores
// en el borde y le añade un brillo de luz desde arriba a la izquierda.
// Compilar: /usr/lib/qt6/bin/qsb --qt6 -o glass.frag.qsb glass.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;   // tamaño del elemento (px)
    vec2 itemPos;    // posición del elemento en la pantalla (px)
    vec2 screenSize; // tamaño de la pantalla (px)
    float radius;    // radio de las esquinas (px)
    float bezel;     // ancho del borde que refracta (px)
    float refraction;// desplazamiento máximo en el borde (px)
    vec4 tint;       // color del vidrio (alfa = intensidad)
};
layout(binding = 1) uniform sampler2D source;

float sdRoundRect(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
    vec2 half_ = itemSize * 0.5;
    vec2 px = qt_TexCoord0 * itemSize;
    vec2 c = px - half_;
    float r = min(radius, min(half_.x, half_.y));
    float d = sdRoundRect(c, half_, r);

    // Normal del borde (hacia afuera)
    vec2 e = vec2(1.0, 0.0);
    vec2 n = vec2(sdRoundRect(c + e.xy, half_, r) - sdRoundRect(c - e.xy, half_, r),
                  sdRoundRect(c + e.yx, half_, r) - sdRoundRect(c - e.yx, half_, r));
    n = n / max(length(n), 1e-4);

    // 0 en el borde, 1 hacia el centro
    float inside = clamp(-d / bezel, 0.0, 1.0);
    float edge = 1.0 - inside;
    vec2 offset = -n * edge * edge * refraction;

    vec2 base = itemPos + px;
    vec3 col;
    col.r = texture(source, (base + offset * 1.12) / screenSize).r;
    col.g = texture(source, (base + offset) / screenSize).g;
    col.b = texture(source, (base + offset * 0.88) / screenSize).b;

    col = mix(col, tint.rgb, tint.a);

    // Brillo: línea fina en el borde, más fuerte arriba a la izquierda
    float rim = 1.0 - smoothstep(0.0, 2.0, -d);
    float light = clamp(dot(n, normalize(vec2(-0.6, -0.8))), 0.0, 1.0);
    col += rim * (0.18 + 0.5 * light);
    col += edge * 0.05;

    // Borde suavizado
    float alpha = 1.0 - smoothstep(-1.0, 0.5, d);
    fragColor = vec4(col * alpha, alpha) * qt_Opacity;
}
