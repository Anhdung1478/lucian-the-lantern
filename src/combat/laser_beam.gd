class_name LaserBeam
extends Node2D
## Q's beam: a bright gold-white line that fades out.

const LIFETIME := 0.25

var _length := 0.0
var _width := 0.0


func setup(from: Vector2, direction: Vector2, length: float, width: float) -> void:
	position = from
	rotation = direction.angle()
	_length = length
	_width = width


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_rect(Rect2(0, -_width * 0.5, _length, _width), Color(1.0, 0.8, 0.35, 0.35))
	draw_rect(Rect2(0, -_width * 0.22, _length, _width * 0.44), Color(1.0, 0.95, 0.75, 0.85))
	draw_rect(Rect2(0, -_width * 0.08, _length, _width * 0.16), Color.WHITE)
