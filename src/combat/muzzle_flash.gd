class_name MuzzleFlash
extends Node2D
## A quick flash at a gun muzzle.

const LIFETIME := 0.08


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.85, 0.45, 0.45))
	draw_circle(Vector2.ZERO, 7.0, Color("fffbe8"))
