#version 460

in vec3 vaPosition;
in vec2 vaUV0;
in vec4 vaColor;
in ivec2 vaUV2;
in vec2 mc_midTexCoord;
in vec3 vaNormal;
in vec4 at_tangent;
in vec2 mc_Entity;

uniform vec3 chunkOffset;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform int worldTime;

out vec2 texCoord;
out vec3 foliageColor;
out vec2 lightMapCoords;
out vec3 normal;

void main() {
    texCoord = vaUV0;
    foliageColor = vaColor.rgb;
    lightMapCoords = (vaUV2 + 0.5) / 256.0;
    mat3 normalMatrix = transpose(inverse(mat3(modelViewMatrix)));
    normal = normalize(normalMatrix * vaNormal);

    vec4 viewPos = modelViewMatrix * vec4(vaPosition + chunkOffset, 1);

    gl_Position = projectionMatrix * viewPos;
}