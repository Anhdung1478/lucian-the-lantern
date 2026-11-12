class_name ClassicFx
extends SkinFx
## Classic: the Sentinel's light. Warm white-gold with a teal edge (the
## lantern's colour), clean and holy rather than fiery. The sounds are the
## base ones.


func q_beam(from: Vector2, direction: Vector2, length: float, width: float) -> Node2D:
	var beam := ClassicBeam.new()
	beam.setup(from, direction, length, width)
	return beam


func w_blast(at: Vector2, direction: Vector2, bar: Vector2) -> Node2D:
	var blast := ClassicBlast.new()
	blast.setup(at, direction, bar)
	return blast
