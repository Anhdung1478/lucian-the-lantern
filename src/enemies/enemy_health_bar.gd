class_name EnemyHealthBar
extends Node2D
## HP bar drawn above an enemy. Drawn by hand instead of using a Control so it
## can never swallow clicks aimed at the enemy.

@export var size := Vector2(90, 10)
@export var fill_color := Color("c8312b")

var _ratio := 1.0


func set_health(current: float, maximum: float) -> void:
	_ratio = clampf(current / maximum, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect.grow(2.0), Color(0, 0, 0, 0.8))
	draw_rect(Rect2(rect.position, Vector2(size.x * _ratio, size.y)), fill_color)
