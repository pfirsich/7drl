in VSOUT {
    vec2 texCoord;
    vec3 normal;
    vec3 worldPos;
    vec3 eye;
} vsOut;

out vec4 fragColor;

uniform vec4 color;
uniform vec3 cameraPosition;

void main() {
    float NdotL = max(0.1, dot(vsOut.normal, normalize(cameraPosition - vsOut.worldPos)));
    fragColor = vec4(color.rgb * NdotL, color.a);
}
