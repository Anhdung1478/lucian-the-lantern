class_name LucianVisuals
extends Node2D
## Everything Lucian looks like. Rotated to face his aim; swap the art here
## without touching gameplay code.


func face(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		rotation = direction.angle()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 30.0, Color("2a3142"))
	draw_line(Vector2.ZERO, Vector2(40, 0), Color("ffe9a8"), 6.0)
