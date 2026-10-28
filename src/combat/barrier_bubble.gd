class_name BarrierBubble
extends Node2D
## Barrier's golden bubble around Lucian while its shield lasts: it pops in,
## shimmers, and fades once the shield is gone. A child of Lucian.

## Big enough to hold all of Lucian, cape included.
const RADIUS := 66.0
const COLOR := Color("ffcf5a")
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
	draw_circle(Vector2.ZERO, radius, Color(COLOR, 0.1))
	draw_arc(Vector2.ZERO, radius - 5.0, 0.0, TAU, 64, Color(COLOR, 0.18 + 0.1 * pulse), 8.0, true)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(RIM_COLOR, 0.6 + 0.3 * pulse), 2.5, true)
	# A fixed highlight up-left, like light on glass, and a glint going round.
	draw_arc(Vector2.ZERO, radius * 0.78, PI * 1.08, PI * 1.42, 16, Color(1.0, 1.0, 1.0, 0.55), 3.0, true)
	var glint := _age * GLINT_SPEED
	draw_arc(Vector2.ZERO, radius, glint, glint + 0.5, 12, Color(1.0, 1.0, 1.0, 0.8), 3.0, true)
