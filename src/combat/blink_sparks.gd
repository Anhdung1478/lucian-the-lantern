class_name BlinkSparks
extends Node2D
## Flash's mark: yellow sparks ringing the spot Lucian blinked from, drifting
## out and up as they fade.

const LIFETIME := 0.6
const COUNT := 16
## The sparks start around Lucian's body and drift up to this much farther out.
const RADIUS := 32.0
const DRIFT := 24.0
## How far they float up over their life.
const RISE := 14.0
const COLOR := Color("ffd84a")
const CORE_COLOR := Color("fffbe8")

## One per spark: angle, distance factor and size, rolled once so they don't
## jitter.
var _sparks: Array[Vector3] = []
var _age := 0.0


func _ready() -> void:
	for i in COUNT:
		_sparks.append(Vector3(TAU * (i + randf_range(-0.3, 0.3)) / COUNT, randf_range(0.8, 1.15), randf_range(2.0, 3.6)))


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _age / LIFETIME
	var fade := 1.0 - t
	# A thin ring pops out at the moment of the blink.
	draw_arc(Vector2.ZERO, RADIUS + DRIFT * t, 0.0, TAU, 48, Color(COLOR, 0.5 * fade * fade), 2.0, true)
	for spark in _sparks:
		var point := Vector2.from_angle(spark.x) * (RADIUS * spark.y + DRIFT * t) + Vector2(0, -RISE * t)
		var size := spark.z * (0.4 + 0.6 * fade)
		draw_circle(point, size + 2.5, Color(COLOR, 0.45 * fade))
		draw_circle(point, size, Color(COLOR, fade))
		draw_circle(point, size * 0.45, Color(CORE_COLOR, fade))
