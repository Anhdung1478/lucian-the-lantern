class_name HealBurst
extends Node2D
## Heal's effect on Lucian: a green ring spreading out and crosses rising
## around him. A child of Lucian, so it moves with him.

const LIFETIME := 0.9
const COLOR := Color("6fd36f")
const CROSS_COLOR := Color("c8ffc0")
const CROSSES := 7
## The ring spreads from Lucian's body out to this radius.
const RING_START := 26.0
const RING_END := 80.0
## How far the crosses float up over their life.
const RISE := 56.0

## One per cross: angle, distance from Lucian and size, rolled once.
var _crosses: Array[Vector3] = []
var _age := 0.0


func _ready() -> void:
	for i in CROSSES:
		_crosses.append(Vector3(TAU * (i + randf_range(-0.3, 0.3)) / CROSSES, randf_range(14.0, 38.0), randf_range(5.0, 8.0)))


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _age / LIFETIME
	var fade := 1.0 - t
	draw_circle(Vector2.ZERO, RING_START + 10.0, Color(COLOR, 0.2 * fade))
	draw_arc(Vector2.ZERO, lerpf(RING_START, RING_END, sqrt(t)), 0.0, TAU, 64, Color(COLOR, 0.7 * fade * fade), 4.0, true)
	# The crosses pop in over the first tenth, then rise and fade.
	var alpha := minf(t * 10.0, 1.0) * fade
	for cross in _crosses:
		var center := Vector2.from_angle(cross.x) * cross.y + Vector2(0, -RISE * t)
		var arm := cross.z
		var width := arm * 0.6
		for rect: Rect2 in [Rect2(center.x - arm, center.y - width * 0.5, arm * 2.0, width), Rect2(center.x - width * 0.5, center.y - arm, width, arm * 2.0)]:
			draw_rect(rect.grow(1.5), Color(COLOR.darkened(0.4), alpha))
			draw_rect(rect, Color(CROSS_COLOR, alpha))
