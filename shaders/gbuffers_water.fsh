#version 460

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D specular;
uniform sampler2D normals;
uniform float sunAngle;
uniform vec3 shadowLightPosition;

/* DRAWBUFFERS:0123 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 lightmapOut;
layout(location = 2) out vec4 normalOut;

in vec2 texCoord;
in vec3 foliageColor;
in vec2 lightMapCoords;
in vec3 normal;

void main() {
    vec3 lightColor = pow(texture(lightmap, lightMapCoords).rgb, vec3(2.2));
    lightmapOut = vec4(lightMapCoords, 0.0, 1.0);
    normalOut = vec4(normal * 0.5 + 0.5, 1.0);

    vec4 outputColorData = pow(texture(gtexture, texCoord), vec4(2.2));
    vec3 outputColor = outputColorData.rgb * pow(foliageColor, vec3(2.2)) * lightColor;
    float transparancy = outputColorData.a;
    if (transparancy < .1) {
        discard;
    }

    outColor0 = pow(vec4(outputColor, transparancy), vec4(1/2.2));
}