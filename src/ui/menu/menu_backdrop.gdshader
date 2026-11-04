shader_type canvas_item;
// Behind a menu: the screen behind it, blurred, darkened and vignetted.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
// How far apart the blur's taps are, in pixels.
uniform float spread = 4.0;
// How much darker the blurred screen gets (0 none, 1 black).
uniform float darken = 0.5;
// How much darker its corners get on top of that.
uniform float vignette = 0.55;

void fragment() {
	vec3 sum = vec3(0.0);
	float total = 0.0;
	// 13 taps in a diamond.
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			if (abs(x) + abs(y) > 2) {
				continue;
			}
			float weight = 1.0 / (1.0 + float(x * x + y * y));
			sum += texture(screen_texture, SCREEN_UV + vec2(float(x), float(y)) * SCREEN_PIXEL_SIZE * spread).rgb * weight;
			total += weight;
		}
	}
	vec3 color = sum / total * (1.0 - darken);
	float edge = smoothstep(0.3, 0.9, length((UV - vec2(0.5)) * vec2(1.3, 1.0)));
	COLOR = vec4(color * (1.0 - vignette * edge), 1.0);
}
