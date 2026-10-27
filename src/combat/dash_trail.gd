class_name DashTrail
extends Node2D
## E's trail: light streaks along the dash path that fade out.

const LIFETIME := 0.3
const STREAK_OFFSETS := [-14.0, 0.0, 14.0]

var _length := 0.0


func setup(from: Vector2, to: Vector2) -> void:
	position = from
	rotation = (to - from).angle()
	_length = from.distance_to(to)


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_rect(Rect2(0, -24, _length, 48), Color(0.62, 0.77, 1.0, 0.18))
	for offset: float in STREAK_OFFSETS:
		draw_line(Vector2(0, offset), Vector2(_length, offset), Color(0.85, 0.92, 1.0, 0.7), 3.0)
