class_name CrossBlast
extends Node2D
## W's explosion: a burning cross that fades out.

const LIFETIME := 0.35

var _bar := Vector2.ZERO


## `bar` is the size of one arm of the cross (length x width).
func setup(at: Vector2, direction: Vector2, bar: Vector2) -> void:
	position = at
	rotation = direction.angle()
	_bar = bar


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func _draw() -> void:
	for bar in [_bar, Vector2(_bar.y, _bar.x)]:
		draw_rect(Rect2(-bar * 0.5, bar), Color(1.0, 0.48, 0.1, 0.45))
		draw_rect(Rect2(-bar * 0.25, bar * 0.5), Color(1.0, 0.82, 0.48, 0.8))
	draw_circle(Vector2.ZERO, _bar.y * 0.45, Color(1.0, 0.95, 0.82))
