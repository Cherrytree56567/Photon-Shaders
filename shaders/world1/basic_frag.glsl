#version 460

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D specular;
uniform sampler2D normals;
uniform sampler2D water;
uniform float sunAngle;
uniform vec3 shadowLightPosition;
uniform float wetness;
uniform int worldTime;
uniform int entityId;

/* DRAWBUFFERS:01234 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 lightmapOut;
layout(location = 2) out vec4 normalOut;
layout(location = 3) out vec4 colortex3;
layout(location = 4) out vec4 bloomOut;

in vec2 texCoord;
in vec3 foliageColor;
in vec2 lightMapCoords;
in vec3 normal;
in vec4 tangent;
in vec2 mcentity;
in vec4 viewPos;
in vec4 worldPos;

#define FRESNEL 1.0

/*
const int colortex2Format = RGBA16F;
*/

void main() {
    vec3 lightColor = pow(texture(lightmap, lightMapCoords).rgb, vec3(2.2));
    lightmapOut = vec4(lightMapCoords, 0.0, 1.0);
    normalOut = vec4(normal * 0.5 + 0.5, 1.0);

    vec4 specularData = texture(specular, texCoord);

    vec4 gtex = texture(gtexture, texCoord);

    vec4 outputColorData = pow(gtex, vec4(2.2));
    vec3 outputColor = outputColorData.rgb * pow(foliageColor, vec3(2.2));
    float transparancy = outputColorData.a;
    if (transparancy < .1) {
        discard;
    }

    bloomOut = vec4(0.0, 0.0, 0.0, 0.0);

    bool isEndermanEye = gtex.r > 0.5 && gtex.b > 0.4 && gtex.g < 0.3;

    if (isEndermanEye && (entityId == 1)) {
        bloomOut = vec4(1.0, 0.0, 0.6, 1.0);
    }

    vec3 sky_color = vec3(0.0, 0.0, 1.0);
    if (sunAngle <= .5) {
        sky_color = vec3(0.0);
    }

    if ((abs(mcentity.x - 10007.0) < 0.5) && (outputColorData.r > 0.5)) {
        bloomOut = vec4(1.0, 0.38, 0.0, 1.0);
    }

    vec3 bitangent = cross(tangent.rgb, normal.xyz) * tangent.w;
    mat3 TBNMatrix = mat3(tangent.xyz, bitangent.xyz, normal.xyz);

    vec4 NormalsTex = texture(normals, texCoord).rgba;

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

    if (abs(mcentity.x - 10005.0) < 0.5) {
        smoothness = 1.0;
        f0 = 1.0;
    }

    float actualWetness = wetness * (lightMapCoords.y > 0.96 ? 1.0 : 0.0);
    float wetShine = clamp(actualWetness - 0.5 * porosity, 0.0, 1.0);

    f0 += (1.0 - f0) * wetShine * 0.7;
    smoothness += (1.0 - smoothness) * wetShine;

    vec3 reflectColor = outputColor;
    reflectColor *= 1.0 - porosity * actualWetness * 0.7;

    vec3 rayDir = normalize(viewPos.xyz);

    vec3 tbnNormal = normalize(TBNMatrix * (NormalsTex.xyz * 2.0 - 1.0));

    float fresnel = pow(clamp(1.0 + dot(tbnNormal, rayDir), 0.0, 1.0), 6.0) * FRESNEL;
    float reflectiveStrength = f0 + (1.0 - f0) * fresnel * smoothness;

    colortex3 = vec4(smoothness, reflectiveStrength, (abs(mcentity.x-10006.0) < 0.5 ? 1.0 : 0.0), f0);

    vec3 sunDir = normalize(shadowLightPosition);

    float blockLight = lightMapCoords.x;
    vec3 torchColor = vec3(0.8, 0.5, 0.1);

    float isMoon = sunAngle > 0.5 ? 1.0 : 0.0;
    float moonFactor = 1.0 - isMoon * 0.88;

    float diffuse = 0.3;
    if (mcentity.x == 10005.0) diffuse = 0.5;

    vec3 torchLight = pow(blockLight, 2.0) * torchColor * 0.5;
    
    outColor0 = pow(vec4(reflectColor * diffuse + (reflectColor * torchLight), transparancy), vec4(1/2.2));
}