shader_type canvas_item;

const int MAX_BLOB_COUNT = 16;

uniform vec2 screen_size;
uniform float feather;
uniform float sum_influence;
uniform float threshold;

uniform int blob_count = 3;
uniform vec2 positions[MAX_BLOB_COUNT];
uniform float radii[MAX_BLOB_COUNT];
uniform vec3 base_color : source_color;

void fragment() {
	float ratio_factor = screen_size.x / screen_size.y;

	float alpha_sum = 0.0;
	vec3 color_sum = vec3(0.0, 0.46, 0.32);
	for (int i = 0; i < blob_count; i++)
	{
		float dist = distance(UV * vec2(ratio_factor, 1.0), positions[i]);
		float alpha = (sum_influence * radii[i]) / dist;
		alpha_sum += alpha;
	}
	float alpha = smoothstep(threshold, threshold + feather, alpha_sum);
	COLOR = vec4(base_color, alpha);
}
