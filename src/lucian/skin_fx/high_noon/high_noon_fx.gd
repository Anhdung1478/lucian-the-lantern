class_name HighNoonFx
extends SkinFx
## High Noon: hellfire. An ember-orange and deep-red palette with embers and
## smoke; revolver-and-fire sounds.


func _init() -> void:
	q_sound = &"cast_q_high_noon"
	w_sound = &"cast_w_high_noon"
	e_sound = &"cast_e_high_noon"
	shot_sound = &"shot_high_noon"


func q_beam(from: Vector2, direction: Vector2, length: float, width: float) -> Node2D:
	var beam := HighNoonBeam.new()
	beam.setup(from, direction, length, width)
	return beam


func w_blast(at: Vector2, direction: Vector2, bar: Vector2) -> Node2D:
	var blast := HighNoonBlast.new()
	blast.setup(at, direction, bar)
	return blast


func e_trail(body: Texture2D) -> DashTrail:
	var trail := HighNoonTrail.new()
	trail.body = body
	return trail


func shot_look(kind: ShotLook.Kind) -> ShotLook:
	return HighNoonShot.new(kind)


func muzzle_flash() -> Node2D:
	return HighNoonFlash.new()
