class_name LucianVisuals
extends Node2D
## Everything Lucian looks like. Rotated to face his aim; swap the art here
## without touching gameplay code.

enum Gun { LEFT, RIGHT }

@onready var _muzzles: Array[Marker2D] = [$MuzzleLeft, $MuzzleRight]


func face(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		rotation = direction.angle()


func muzzle_position(gun: Gun) -> Vector2:
	return _muzzles[gun].global_position


func body_texture() -> Texture2D:
	return ($Body as Sprite2D).texture
