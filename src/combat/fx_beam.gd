class_name FxBeam
extends FxPiece
## A skin's Q beam: `length` × `width` from where it starts, along its
## rotation. Its main shape lasts LaserBeam.LIFETIME, like Classic's.

var length := 0.0
var width := 0.0


func _init() -> void:
	lifetime = LaserBeam.LIFETIME


func setup(from: Vector2, direction: Vector2, beam_length: float, beam_width: float) -> void:
	position = from
	rotation = direction.angle()
	length = beam_length
	width = beam_width
