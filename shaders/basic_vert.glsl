#version 460

in vec3 vaPosition;
in vec2 vaUV0;
in vec4 vaColor;
in ivec2 vaUV2;
in vec2 mc_midTexCoord;
in vec3 vaNormal;
in vec4 at_tangent;
attribute vec4 mc_Entity;

layout(location = 0) in vec3 position;

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
out vec4 tangent;
out vec2 mcentity;
out vec4 viewPos;
out vec4 worldPos;

void main() {
    texCoord = vaUV0;
    foliageColor = vaColor.rgb;
    lightMapCoords = vaUV2 / 240.0;
    mat3 normalMatrix = transpose(inverse(mat3(modelViewMatrix)));
    normal = normalize(normalMatrix * vaNormal);
    tangent = vec4(normalize(normalMatrix * at_tangent.xyz), at_tangent.w);
    mcentity = mc_Entity.xy;

    viewPos = modelViewMatrix * vec4(vaPosition + chunkOffset, 1);
    worldPos = gbufferModelViewInverse * viewPos;
    worldPos.xyz += cameraPosition;

    /*
     * Make Leaves Wavy
    */
    if (mc_Entity.x == 10001.0) {
        float skyLight = lightMapCoords.y;

        if (skyLight > 0.9) {
            worldPos.xyz += sin(worldTime*.1) * .02 + sin(worldTime*.1) * .02;
            viewPos = gbufferModelView * vec4(worldPos.xyz - cameraPosition, 1.0);
        }
    }

    /*
     * Make Grass Wavy
    */
    if (mc_Entity.x == 10002.0) {
        if (texCoord.y < mc_midTexCoord.y) {
            worldPos.xyz += sin(worldTime*.1) * .05;
            viewPos = gbufferModelView * vec4(worldPos.xyz - cameraPosition, 1.0);
        }
    }

    gl_Position = projectionMatrix * viewPos;
}