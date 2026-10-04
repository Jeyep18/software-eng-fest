shader_type canvas_item;

void fragment() {
	vec4 art = texture(TEXTURE, UV);
	float from_white = max(max(1.0 - art.r, 1.0 - art.g), 1.0 - art.b);
	float alpha = smoothstep(0.02, 0.18, from_white);
	COLOR = vec4(clamp((art.rgb - vec3(1.0 - alpha)) / max(alpha, 0.001), 0.0, 1.0), art.a * alpha);
}
