class_name FxBlast
extends FxPiece
## A skin's W cross: two arms of `bar` (length × width) through its centre,
## turned to the missile's direction. Its main shape lasts
## CrossBlast.LIFETIME, like Classic's.

var bar := Vector2.ZERO


func _init() -> void:
	lifetime = CrossBlast.LIFETIME


func setup(at: Vector2, direction: Vector2, arm: Vector2) -> void:
	position = at
	rotation = direction.angle()
	bar = arm
