#version 460

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D specular;
uniform sampler2D normals;
uniform float sunAngle;
uniform vec3 shadowLightPosition;
uniform float wetness;

/* DRAWBUFFERS:0123 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 lightmapOut;
layout(location = 2) out vec4 normalOut;
layout(location = 3) out vec4 colortex3;

in vec2 texCoord;
in vec3 foliageColor;
in vec2 lightMapCoords;
in vec3 normal;
in vec4 tangent;
in vec2 mcentity;
in vec4 viewPos;

#define FRESNEL 3

void main() {
    vec3 lightColor = pow(texture(lightmap, lightMapCoords).rgb, vec3(2.2));
    lightmapOut = vec4(lightMapCoords, 0.0, 1.0);
    normalOut = vec4(normal * 0.5 + 0.5, 1.0);

    vec4 specularData = texture(specular, texCoord);

    vec4 outputColorData = pow(texture(gtexture, texCoord), vec4(2.2));
    vec3 outputColor = outputColorData.rgb * pow(foliageColor, vec3(2.2)) * lightColor;
    float transparancy = outputColorData.a;
    if (transparancy < .1) {
        discard;
    }

    vec3 sky_color = vec3(0.0, 0.0, 1.0);
    if (sunAngle <= .5) {
        sky_color = vec3(0.0);
    }

    vec3 bitangent = cross(tangent.rgb, normal.xyz) * tangent.w;
    mat3 TBNMatrix = mat3(tangent.xyz, bitangent.xyz, normal.xyz);

    vec4 NormalsTex = texture(normals, texCoord).rgba;
    NormalsTex.xy = NormalsTex.xy * 2.0 - 1.0;
    NormalsTex.z = sqrt(max(0.0, 1.0 - dot(NormalsTex.xy,  NormalsTex.xy)));
    NormalsTex.xyz = normalize(TBNMatrix * NormalsTex.xyz);

    float f0 = specularData.g;
    bool metal = specularData.g >= 229.5;

    float perceptualSmoothness = specularData.r;
    float roughness = pow(1.0 - perceptualSmoothness, 2.0);
    float smoothness = 1.0 - roughness;

    float porosity = specularData.b < 64.5 / 255.0 ? specularData.b / 64.0 : 0.0;
    float sss = specularData.b >= 64.5 / 255.0 ? (specularData.b - 64.0) / (255.0 - 64.0) : 0.0;

    float emmisive = specularData.a >= 254.5 / 255.0 ? 0.0 : specularData.a;

    if (abs(mcentity.x - 10003.0) < 0.5) {
        porosity = 1.0;
    }

    if (abs(mcentity.x - 10002.0) < 0.5) {
        sss = 1.0;
    }

    if (abs(mcentity.x - 10006.0) < 0.5) {
        smoothness = 1.0;
    }

    float actualWetness = wetness * (lightMapCoords.y > 0.96 ? 1.0 : 0.0);
    float wetShine = clamp(actualWetness - 0.5 * porosity, 0.0, 1.0);

    f0 += (1.0 - f0) * wetShine * 0.7;
    smoothness += (1.0 - smoothness) * wetShine;

    vec3 reflectColor = outputColor;
    reflectColor *= 1.0 - porosity * actualWetness * 0.7;

    vec3 rayDir = normalize(viewPos.xyz);

    float fresnel = pow(clamp(1.0 + dot(NormalsTex.xyz, rayDir), 0.0, 1.0), 6.0) * FRESNEL;
    float reflectiveStrength = f0 + (1.0 - f0) * fresnel * smoothness;

    vec3 sunDir = normalize(shadowLightPosition);

    float lightDot = clamp(dot(sunDir, NormalsTex.xyz), 0.0, 1.0); 
    float diffuse = lightDot * (1.0 - reflectiveStrength) + 0.2;
    if (mcentity.x == 10005.0) diffuse = 0.5;
    outColor0 = pow(vec4(reflectColor * diffuse, transparancy), vec4(1/2.2));

    vec3 reflectedRay = reflect(rayDir, NormalsTex.rgb);

    float sunReflect = pow(clamp(dot(reflectedRay, sunDir), 0.0, 1.0), 1.0 + 11.0 * smoothness);

    sunReflect *= clamp(dot(normal.xyz, sunDir) * 100.0, 0.0, 1.0);

    sunReflect *= smoothness;

    outColor0.rgb += reflectiveStrength * sunReflect * (metal ? outputColor : vec3(1.0));
    outColor0.a = outColor0.a >= 1.0 / 255.0 ? min(1.0, outColor0.a + reflectiveStrength * sunReflect) : outColor0.a;

    outColor0.rgb = clamp(outColor0.rgb + outputColor.rgb * emmisive, 0.0, 1.0);
}