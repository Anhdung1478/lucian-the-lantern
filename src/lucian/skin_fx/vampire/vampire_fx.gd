class_name VampireFx
extends SkinFx
## Vampire: blood. Crimson and black red, drops and bats; dark, wet sounds.


func _init() -> void:
	q_sound = &"cast_q_vampire"
	w_sound = &"cast_w_vampire"
	e_sound = &"cast_e_vampire"
	shot_sound = &"shot_vampire"


func q_beam(from: Vector2, direction: Vector2, length: float, width: float) -> Node2D:
	var beam := VampireBeam.new()
	beam.setup(from, direction, length, width)
	return beam


func w_blast(at: Vector2, direction: Vector2, bar: Vector2) -> Node2D:
	var blast := VampireBlast.new()
	blast.setup(at, direction, bar)
	return blast


func e_trail(body: Texture2D) -> DashTrail:
	var trail := VampireTrail.new()
	trail.body = body
	return trail


func shot_look(kind: ShotLook.Kind) -> ShotLook:
	return VampireShot.new(kind)


func muzzle_flash() -> Node2D:
	return VampireFlash.new()
