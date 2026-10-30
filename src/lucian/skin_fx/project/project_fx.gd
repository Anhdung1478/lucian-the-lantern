class_name ProjectFx
extends SkinFx
## PROJECT: a hologram. Cyan light, scan lines, pixels and glitches;
## square-wave synth sounds.


func _init() -> void:
	q_sound = &"cast_q_project"
	w_sound = &"cast_w_project"
	e_sound = &"cast_e_project"
	shot_sound = &"shot_project"


func q_beam(from: Vector2, direction: Vector2, length: float, width: float) -> Node2D:
	var beam := ProjectBeam.new()
	beam.setup(from, direction, length, width)
	return beam


func w_blast(at: Vector2, direction: Vector2, bar: Vector2) -> Node2D:
	var blast := ProjectBlast.new()
	blast.setup(at, direction, bar)
	return blast


func e_trail(body: Texture2D) -> DashTrail:
	var trail := ProjectTrail.new()
	trail.body = body
	return trail


func shot_look(kind: ShotLook.Kind) -> ShotLook:
	return ProjectShot.new(kind)


func muzzle_flash() -> Node2D:
	return ProjectFlash.new()
