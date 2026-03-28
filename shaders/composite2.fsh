#version 460

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform float near;
uniform float far;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 OutColor;

in vec2 texcoord;

#define REFLECTION_THRESHOLD 0.25

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
    vec4 homPos = projectionMatrix * vec4(position, 1.0);
    return homPos.xyz / homPos.w;
}

float lineariseDepth(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

float getDepthAt(vec2 uv) {
    return lineariseDepth(texture(depthtex0, uv).r);
}

// TODO: CRITICAL: Add 16Bit Normals

void main() {
    OutColor = texture(colortex0, texcoord);

    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        return;
    }

    vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    
    vec4 normals = texture(colortex2, texcoord) * 2.0 - 1.0;
    normals.xyz = normalize(normals.xyz);

    vec4 PBR = texture(colortex3, texcoord);

    float smoothness = PBR.r;
    float reflectiveStrength = PBR.g;
    float isWater = PBR.b;
    float f0 = PBR.a;/*

    if ((smoothness * reflectiveStrength > REFLECTION_THRESHOLD) || isWater > 0.5) {
        vec3 pos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 lastRayPos = pos * 0.5 + 0.5;
        pos = projectAndDivide(gbufferProjectionInverse, pos);

        vec3 raySPD = normalize(reflect(normalize(pos), normals.xyz));

        float fresnel = pow(1.0 - max(0.0, dot(normals.xyz, raySPD)), FRESNEL_EXPONENT);
        fresnel = f0 + (1.0 - f0) * f;

        vec3 rayPos = pos;

        bool hit = false;
        bool OutOfBounds = false;

        float tracingDist = raySPF.x > 0.0 ? abs(pos.z) : far;

        for (float i = 1.0; i < SSR_STEPS && !hit && !oob; i++) {
            rayPos = (pos + raySPD.xyz * tracingDist * pow(i / SSR_STEPS, 2.0));

            vec4 rayPos2 = gbufferProjection * vec4(rayPos.xyz, 1.0);
            rayPos2 /= rayPos2.w;
            rayPos2.xy = rayPos2.xy * 0.5 + 0.5;
            rayPos = rayPos2.xyz;

            oob = rayPos.x < 0.0 || rayPos.x > 1.0 || rayPos.y < 0.0 || rayPos.y > 1.0 || rayPos.z < 0.0;

            float bias = 0.1 + (abs(pos.z) - 0.0) * pow(1.0 - 1.0 * i / SSR_STEPS, 2.0);

            float depth = getDepthAt(rayPos.xy);

            hit = depth + bias < rayPos.z && !oob && depth + bias + rayPos.z * 0.1 + abs(lastRayPos.z - rayPos.z) > rayPos.z;

            lastRayPos = !hit ? rayPos : lastRayPos;
        } // 36.01
    }*/
}