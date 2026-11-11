class_name LucianVisuals
extends Node2D
## Everything Lucian looks like. Rotated to face his aim; swap the art here
## without touching gameplay code. His body art sways as he walks, kicks back
## with each shot and squashes when he is hit (see UnitMotion): the muzzles,
## his facing and his body never move with it.

enum Gun { LEFT, RIGHT }

## Small motion of his body art (made in _ready).
var motion: UnitMotion

@onready var _muzzles: Array[Marker2D] = [$MuzzleLeft, $MuzzleRight]


func _ready() -> void:
	motion = UnitMotion.new()
	motion.setup($Body, get_parent(), Lucian.HIT_RADIUS)
	add_child(motion)


func face(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		rotation = direction.angle()


func muzzle_position(gun: Gun) -> Vector2:
	return _muzzles[gun].global_position


func body_texture() -> Texture2D:
	return ($Body as Sprite2D).texture
