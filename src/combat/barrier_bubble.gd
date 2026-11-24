class_name BarrierBubble
extends Node2D
## Barrier's golden bubble around Lucian while its shield lasts: it pops in,
## shimmers with faceted golden hexagonal-arc highlights, and fades once the
## shield is gone. A child of Lucian.

## Big enough to hold all of Lucian, cape included.
const RADIUS := 66.0
const COLOR := Color("ffcf5a")
const DEEP_GOLD := Color("e69a28")
const RIM_COLOR := Color("ffe9a8")
## Seconds to pop in and to fade out.
const POP := 0.15
const FADE := 0.25
## The rim's glow pulses this many times a second; a glint circles it.
const PULSE := 1.5
const GLINT_SPEED := 2.4

var _age := 0.0
var _fading := false


func _process(delta: float) -> void:
	_age += delta
	if not _fading and (get_parent() as Lucian).barrier <= 0.0:
		_fading = true
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, FADE)
		tween.tween_callback(queue_free)
	queue_redraw()


func _draw() -> void:
	# Pops in from 60% size with a little overshoot.
	var pop := minf(_age / POP, 1.0)
	var radius := RADIUS * (0.6 + 0.4 * pop + 0.08 * sin(pop * PI))
	var pulse := 0.5 + 0.5 * sin(_age * TAU * PULSE)
	# Soft luminous inner dome shimmer.
	SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * (radius * 1.06), Color(DEEP_GOLD, 0.14 + 0.05 * pulse), 0.55)
	draw_circle(Vector2.ZERO, radius, Color(COLOR, 0.08 + 0.04 * pulse))
	# Faceted translucent golden hexagonal-arc shield ribs.
	var hex_rot := _age * 0.35
	var hex_r := radius * 0.86
	var hex_pts := PackedVector2Array()
	for i in 7:
		hex_pts.append(Vector2.from_angle(hex_rot + TAU * i / 6.0) * hex_r)
	draw_polyline(hex_pts, Color(RIM_COLOR, 0.18 + 0.1 * pulse), 1.6, true)
	for i in 6:
		var ang := hex_rot + TAU * i / 6.0
		var inner_pt := Vector2.from_angle(ang) * (radius * 0.56)
		var outer_pt := Vector2.from_angle(ang) * (radius * 0.96)
		draw_line(inner_pt, outer_pt, Color(RIM_COLOR, 0.16 + 0.1 * pulse), 1.4, true)
		# Translucent faceted highlight arc on alternating hex panels.
		var panel_a := 0.16 + 0.14 * (0.5 + 0.5 * sin(_age * 4.0 + i * 1.1))
		draw_arc(Vector2.ZERO, radius * 0.84, ang + 0.12, ang + TAU / 6.0 - 0.12, 10, Color(RIM_COLOR, panel_a), 3.0, true)
	# Inner glow band & crisp luminous rim.
	draw_arc(Vector2.ZERO, radius - 5.0, 0.0, TAU, 64, Color(COLOR, 0.22 + 0.12 * pulse), 9.0, true)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(RIM_COLOR, 0.68 + 0.28 * pulse), 2.6, true)
	# Specular highlight up-left, like light on curved crystal, plus dual orbiting glints.
	draw_arc(Vector2.ZERO, radius * 0.78, PI * 1.06, PI * 1.44, 18, Color(1.0, 1.0, 1.0, 0.58), 3.2, true)
	var glint := _age * GLINT_SPEED
	draw_arc(Vector2.ZERO, radius, glint, glint + 0.55, 14, Color(1.0, 1.0, 1.0, 0.88), 3.2, true)
	draw_arc(Vector2.ZERO, radius, glint + PI, glint + PI + 0.35, 10, Color(RIM_COLOR, 0.65), 2.2, true)
