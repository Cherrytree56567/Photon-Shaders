#version 460

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform float near;
uniform float far;
uniform int isEyeInWater;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 OutColor;

in vec2 texcoord;

/*
const int colortex4Format = RGBA16F;
const bool colortex4MipmapEnabled = true;
*/

#define BLOOM_STEPS 6
#define BLOOM_RADIUS 10.0

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

    vec3 bloom = vec3(0.0);
    float blurSize = 0.004;
    float radius = BLOOM_RADIUS;
    float totalWeight = 0.0;
    float linearD = lineariseDepth(depth);
    float lod = log2(linearD / near) * 0.5;

    for (int x = -10; x <= 10; x++) {
        for (int y = -10; y <= 10; y++) {
            float dist = length(vec2(x, y));
            if (dist <= radius) {
                float weight = exp(-(dist * dist) / (2.0 * radius * radius));
                vec2 offset = vec2(x, y) * blurSize;
                bloom += textureLod(colortex4, texcoord + offset, lod).rgb * weight;
                totalWeight += weight;
            }
        }
    }

    bloom /= totalWeight;
    OutColor.rgb += bloom * 5.5;
}