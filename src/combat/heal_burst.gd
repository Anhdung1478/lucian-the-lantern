class_name HealBurst
extends Node2D
## Heal's effect on Lucian: a radiant restorative vertical light shimmer,
## expanding double emerald rings, and rising crosses around him. A child of
## Lucian, so it moves with him.

const LIFETIME := 0.9
const COLOR := Color("6fd36f")
const BRIGHT := Color("a8ff9e")
const CROSS_COLOR := Color("e4ffe0")
const CROSSES := 8
## The ring spreads from Lucian's body out to this radius.
const RING_START := 24.0
const RING_END := 84.0
## How far the crosses float up over their life.
const RISE := 60.0

## One per cross: angle, distance from Lucian and size, rolled once.
var _crosses: Array[Vector3] = []
var _age := 0.0


func _ready() -> void:
	for i in CROSSES:
		_crosses.append(Vector3(TAU * (i + randf_range(-0.28, 0.28)) / CROSSES, randf_range(16.0, 42.0), randf_range(5.0, 8.2)))


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_age / LIFETIME, 0.0, 1.0)
	var fade := 1.0 - t
	var out := 1.0 - pow(1.0 - t, 2.2)
	var pop := minf(t * 9.0, 1.0)
	# Soft radiant vertical restorative light pillar & shimmer rays.
	var pillar_a := pop * fade * fade
	SoftShape.ellipse(self, Vector2(0.0, -18.0 * t), Vector2(36.0, 62.0), Color(COLOR, 0.28 * pillar_a), 0.25)
	SoftShape.ellipse(self, Vector2(0.0, -24.0 * t), Vector2(18.0, 48.0), Color(CROSS_COLOR, 0.38 * pillar_a), 0.3)
	for rx: float in [-20.0, -8.0, 6.0, 19.0]:
		var rise_y := -16.0 - 46.0 * t
		var h := lerpf(34.0, 18.0, t)
		DashTrail.draw_speed_needle(self, rx, rx, rise_y + h, rise_y - h, 2.2, Color(BRIGHT, 0.45 * pillar_a))
	# Expanding double restorative rings.
	var outer_r := lerpf(RING_START, RING_END, out)
	var inner_r := lerpf(RING_START * 0.7, RING_END * 0.72, sqrt(t))
	draw_arc(Vector2.ZERO, outer_r, 0.0, TAU, 64, Color(COLOR, 0.72 * fade * fade), lerpf(5.0, 1.2, t), true)
	draw_arc(Vector2.ZERO, inner_r, 0.0, TAU, 56, Color(CROSS_COLOR, 0.58 * fade * fade), lerpf(3.0, 0.8, t), true)
	# Rising luminous healing crosses.
	var alpha := pop * fade
	for cross in _crosses:
		var center := Vector2.from_angle(cross.x) * cross.y + Vector2(0, -RISE * t)
		var arm := cross.z * (0.7 + 0.3 * fade)
		var width := arm * 0.56
		SoftShape.ellipse(self, center, Vector2.ONE * (arm * 1.45), Color(COLOR, 0.3 * alpha), 0.25)
		for rect: Rect2 in [
			Rect2(center.x - arm, center.y - width * 0.5, arm * 2.0, width),
			Rect2(center.x - width * 0.5, center.y - arm, width, arm * 2.0),
		]:
			draw_rect(rect.grow(1.5), Color(COLOR.darkened(0.35), alpha * 0.85))
			draw_rect(rect, Color(CROSS_COLOR, alpha))
