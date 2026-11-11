shader_type canvas_item;

// Мягкая виньетка оптической линзы нательной камеры.
void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv);
	float vig = smoothstep(0.42, 0.74, dist);
	COLOR = vec4(0.01, 0.02, 0.03, vig * 0.45);
}
