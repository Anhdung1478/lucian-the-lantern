class_name DashTrail
extends Node2D
## A dash's trail: light streaks along its path that fade out.

const LIFETIME := 0.3
const STREAK_OFFSETS := [-14.0, 0.0, 14.0]
## E's light blue. Item dashes pass their own color.
const LIGHT := Color(0.62, 0.77, 1.0)

var color := LIGHT

var _length := 0.0


func setup(from: Vector2, to: Vector2, trail_color := LIGHT) -> void:
	position = from
	rotation = (to - from).angle()
	_length = from.distance_to(to)
	color = trail_color


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_rect(Rect2(0, -24, _length, 48), Color(color, 0.18))
	var streak := Color(color.lerp(Color.WHITE, 0.6), 0.7)
	for offset: float in STREAK_OFFSETS:
		draw_line(Vector2(0, offset), Vector2(_length, offset), streak, 3.0)
