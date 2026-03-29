#version 460

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform float near;
uniform float far;
uniform int isEyeInWater;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 OutColor;

in vec2 texcoord;

#define REFLECTION_THRESHOLD 0.25
#define FRESNEL_EXPONENT 3.0
#define SSR_REFINEMENT_STEPS 5
#define SSR_STEPS 10

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
    float f0 = PBR.a;
    if (isEyeInWater == 1) {
        return;
    }

    if ((smoothness * reflectiveStrength > REFLECTION_THRESHOLD) || (isWater > 0.5 && isEyeInWater != 1)) {
        vec3 pos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 lastRayPos = pos * 0.5 + 0.5;
        pos = projectAndDivide(gbufferProjectionInverse, pos);

        vec3 raySPD = normalize(reflect(normalize(pos), normals.xyz));

        float fresnel = pow(1.0 - max(0.0, dot(normals.xyz, raySPD)), FRESNEL_EXPONENT);
        fresnel = f0 + (1.0 - f0) * fresnel;

        vec3 rayPos = pos;

        bool hit = false;
        bool OutOfBounds = false;

        float tracingDist = raySPD.z > 0.0 ? abs(pos.z) : far;

        for (float i = 1.0; i < SSR_STEPS; i++) {
            rayPos = (pos + raySPD.xyz * tracingDist * pow(i / SSR_STEPS, 2.0));

            vec4 rayPos2 = gbufferProjection * vec4(rayPos.xyz, 1.0);
            rayPos2.xy /= rayPos2.w;
            rayPos2.xy = rayPos2.xy * 0.5 + 0.5;
            rayPos = rayPos2.xyz;

            OutOfBounds = rayPos.x < 0.0 || rayPos.x > 1.0 || rayPos.y < 0.0 || rayPos.y > 1.0 || rayPos.z < 0.0;

            float bias = 0.1 + (abs(pos.z) - 0.0) * pow(1.0 - 1.0 * i / SSR_STEPS, 2.0);

            float depth = getDepthAt(rayPos.xy);

            hit = depth + bias < rayPos.z && !OutOfBounds && depth + bias + rayPos.z * 0.1 + abs(lastRayPos.z - rayPos.z) > rayPos.z;

            lastRayPos = !hit ? rayPos : lastRayPos;
        }

        if (hit || (!OutOfBounds && raySPD.z < -0.01)) {
            float depth;
            pos = rayPos;
            float reverse = -1.0;
            float refined = 1.0;
            float raySpeed = 1.0;

            for (int ray = 0; ray < SSR_REFINEMENT_STEPS; ray++) {
                raySpeed *= 0.5;
                refined += raySpeed * reverse;
                rayPos = mix(lastRayPos, pos, refined);

                depth = getDepthAt(rayPos.xy);
                hit = depth < rayPos.z;

                reverse = hit ? -1.0 : 1.0;
            }

            fresnel *= (
                (isWater > 0.5) ? 
                (clamp(min((1.0 - abs(rayPos.x - 0.5) * 2.0) * 20.0, (1.0 - abs(rayPos.y - 0.5) * 2.0) * 5.0), 0.0, 1.0)) : 
                (clamp(min((1.0 - abs(rayPos.x - 0.5) * 2.0), (1.0 - abs(rayPos.y - 0.5) * 2.0)), 0.0, 1.0))
                );
            
            float rayLOD = 8.0 * (1.0 - smoothness);

            vec3 reflection = textureLod(colortex0, rayPos.xy, rayLOD).rgb;

            if (f0 > 230.0 / 255.0) {
                reflection *= pow(OutColor.rgb, vec3(2.0));
            }

            OutColor.rgb = mix(OutColor.rgb, reflection, fresnel);
        }
    }
}