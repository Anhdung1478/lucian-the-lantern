shader_type canvas_item;
// Ghost's afterimage: Lucian's outline filled with a pale teal, a little of
// his shading left so it doesn't read as a blob.

uniform vec4 tint : source_color = vec4(0.62, 1.0, 0.9, 1.0);

void fragment() {
	float light = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = tint.rgb * mix(0.7, 1.0, light);
}
