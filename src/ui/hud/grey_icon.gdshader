shader_type canvas_item;
// Turns an icon grey and a little darker: the skill can't be used right now.

void fragment() {
	float light = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = vec3(light * 0.7);
}
