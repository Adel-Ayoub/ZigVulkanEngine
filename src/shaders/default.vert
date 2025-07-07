#version 460 core

layout (location = 0) in vec3 a_pos;
layout (location = 1) in vec2 a_uv;
layout (location = 2) in vec3 a_normal;

out vec3 out_normal;
out vec2 out_uv;

uniform mat4 u_projection;
uniform mat4 u_view;
uniform mat4 u_model;

void main()
{
    mat3 normal_matrix = transpose(inverse(mat3(u_model)));
    out_normal = normalize(normal_matrix * a_normal);

    out_uv = a_uv;

    gl_Position = u_projection * u_view * u_model * vec4(a_pos, 1.0);
}
