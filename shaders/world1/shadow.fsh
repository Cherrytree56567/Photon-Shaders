#version 330 compatibility

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

const float shadowDistanceRenderMul = 1.0;
const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;
const int shadowMapResolution = 2048;

void main() {
    color = texture(gtexture, texcoord) * glcolor;

    if (color.a < 0.1) {
        discard;
    }
}