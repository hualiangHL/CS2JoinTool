#version 420
layout(std140, binding=0) uniform qt_buffer {
    float qt_Opacity;
};
layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

void main() {
    fragColor = vec4(1.0, 0.0, 0.0, 0.5) * qt_Opacity;
}
