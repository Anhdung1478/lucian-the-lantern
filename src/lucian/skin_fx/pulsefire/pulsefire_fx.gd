class_name PulsefireFx
extends SkinFx
## Pulsefire: a time rift. A white core in pale and deep blue, rings, clock
## faces and afterimages; shimmering sounds.


func _init() -> void:
	q_sound = &"cast_q_pulsefire"
	w_sound = &"cast_w_pulsefire"
	e_sound = &"cast_e_pulsefire"
	shot_sound = &"shot_pulsefire"


func q_beam(from: Vector2, direction: Vector2, length: float, width: float) -> Node2D:
	var beam := PulsefireBeam.new()
	beam.setup(from, direction, length, width)
	return beam


func w_blast(at: Vector2, direction: Vector2, bar: Vector2) -> Node2D:
	var blast := PulsefireBlast.new()
	blast.setup(at, direction, bar)
	return blast


func e_trail(body: Texture2D) -> DashTrail:
	var trail := PulsefireTrail.new()
	trail.body = body
	return trail


func shot_look(kind: ShotLook.Kind) -> ShotLook:
	return PulsefireShot.new(kind)


func muzzle_flash() -> Node2D:
	return PulsefireFlash.new()
