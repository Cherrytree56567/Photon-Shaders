#version 330 compatibility

out vec2 texcoord;
out vec4 glcolor;
out vec2 localUV;

void main() {
    vec4 pos = gl_Vertex;
    pos.y *= 2.5;

	gl_Position = gl_ModelViewProjectionMatrix * pos;
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}