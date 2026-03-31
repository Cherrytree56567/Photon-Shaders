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

#define BLOOM_RAYS 16
#define BLOOM_STEPS 20
#define BLOOM_DIST 0.08

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

    vec3 bloom = vec3(0.0);
    for (int r = 0; r < BLOOM_RAYS; r++) {
        float angle = (float(r) / float(BLOOM_RAYS)) * 3.14159 * 2.0;
        vec2 rayDir = vec2(cos(angle), sin(angle));

        for (int s = 1; s <= BLOOM_STEPS; s++) {
            float t = float(s) / float(BLOOM_STEPS);
            vec2 sampleUV = texcoord + rayDir * t * BLOOM_DIST;

            float weight = 1.0 - t;
            bloom += texture(colortex4, sampleUV).rgb * weight;
        }
    }

    bloom /= float(BLOOM_RAYS * BLOOM_STEPS);
    OutColor.rgb += bloom * 9.0;

    if (depth == 1.0) {
        return;
    }
}