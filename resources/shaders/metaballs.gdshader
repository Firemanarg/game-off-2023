shader_type canvas_item;

uniform vec2 screen_size;
uniform float feather;
uniform float sum_influence;
uniform float threshold;

uniform vec2 positions[3];
uniform float radii[3];
uniform vec3 base_color : source_color;

void fragment() {
	float ratio_factor = screen_size.x / screen_size.y;

	float alpha_sum = 0.0;
	vec3 color_sum = vec3(0.0, 0.46, 0.32);
	for (int i = 0; i < positions.length(); i++)
	{
		float dist = distance(UV * vec2(ratio_factor, 1.0), positions[i]);
		float alpha = (sum_influence * radii[i]) / dist;
		alpha_sum += alpha;
	}
	float alpha = smoothstep(threshold, threshold + feather, alpha_sum);
	COLOR = vec4(base_color, alpha);
}
