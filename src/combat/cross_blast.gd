class_name CrossBlast
extends Node2D
## W's explosion: a burning cross that fades out.

const LIFETIME := 0.35

## One arm of the cross: length × width.
var bar := Vector2.ZERO


func setup(at: Vector2, direction: Vector2, arm: Vector2) -> void:
	position = at
	rotation = direction.angle()
	bar = arm


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func _draw() -> void:
	for arm in [bar, Vector2(bar.y, bar.x)]:
		draw_rect(Rect2(-arm * 0.5, arm), Color(1.0, 0.48, 0.1, 0.45))
		draw_rect(Rect2(-arm * 0.25, arm * 0.5), Color(1.0, 0.82, 0.48, 0.8))
	draw_circle(Vector2.ZERO, bar.y * 0.45, Color(1.0, 0.95, 0.82))
