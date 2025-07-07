#version 460 core

out vec4 frag_color;

in vec3 out_normal;
in vec2 out_uv;

uniform sampler2D texture0;

void main() {
    vec3 normal = normalize(out_normal);

    vec3 light_dir = normalize(vec3(0, 1.0, 0));

    float brightness = max(dot(normal, light_dir), 0.0);

    brightness = max(brightness, 0.1);

    vec4 tex_color = texture(texture0, out_uv);

    frag_color = vec4(tex_color.rgb * brightness, tex_color.a);
}
