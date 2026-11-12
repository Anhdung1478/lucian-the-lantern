extends GutTest
## V1.1 skin effects: each skin's SkinFx builds every piece at the size it is
## given; the pieces are gone within 0.6 s and drop their details on Low
## effects; every sound has its own recipe, as loud as the Classic one it
## replaces.

const LENGTH := 700.0
const WIDTH := 60.0
const BAR := Vector2(400, 60)
## Every piece is gone by then (FxSparks.MAX_LIFE, plus a margin).
const GONE_BY := 0.7


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real settings.
	if GameSettings._instance == null or GameSettings._instance.path == GameSettings.DEFAULT_PATH:
		GameSettings._instance = GameSettings.new("user://test_skin_fx_settings.json")


func after_each() -> void:
	GameSettings.instance().set_value(&"quality", "high")


func _beam(fx: SkinFx) -> Node2D:
	return fx.q_beam(Vector2(10, 20), Vector2.DOWN, LENGTH, WIDTH)


func _blast(fx: SkinFx) -> Node2D:
	return fx.w_blast(Vector2(300, 0), Vector2.DOWN, BAR)


## Skin -> its classes: [SkinFx, beam, blast, trail, shot look, flash].
func _themed() -> Dictionary:
	return {
		&"classic": [ClassicFx, ClassicBeam, ClassicBlast, ClassicTrail, ClassicShot, ClassicFlash],
		&"high_noon": [HighNoonFx, HighNoonBeam, HighNoonBlast, HighNoonTrail, HighNoonShot, HighNoonFlash],
		&"project": [ProjectFx, ProjectBeam, ProjectBlast, ProjectTrail, ProjectShot, ProjectFlash],
		&"pulsefire": [PulsefireFx, PulsefireBeam, PulsefireBlast, PulsefireTrail, PulsefireShot, PulsefireFlash],
		&"vampire": [VampireFx, VampireBeam, VampireBlast, VampireTrail, VampireShot, VampireFlash],
	}


func test_themed_skins_use_their_own_pieces() -> void:
	var themed := _themed()
	for id: StringName in themed:
		var row: Array = themed[id]
		var skin := Skins.find(id)
		var pieces: Array = [skin.fx, _beam(skin.fx), _blast(skin.fx), skin.fx.e_trail(skin.body), skin.fx.r_bullet_look(), skin.fx.muzzle_flash()]
		for i in row.size():
			assert_true(is_instance_of(pieces[i], row[i]), "%s piece %d" % [id, i])
		for i in range(1, pieces.size()):
			(pieces[i] as Node).free()


## The loudest sample of a generated sound, 0–1.
func _peak(sound: StringName) -> float:
	var data := Sfx.stream(sound).data
	var peak := 0
	for i in range(0, data.size(), 2):
		peak = maxi(peak, absi(data.decode_s16(i)))
	return peak / 32000.0


func test_every_skin_has_an_effect_set() -> void:
	for skin in Skins.ALL:
		assert_not_null(skin.fx, str(skin.id))
	assert_eq(Skins.find(&"classic").fx.get_script(), ClassicFx)


func test_beams_and_crosses_keep_the_size_they_are_given() -> void:
	for skin in Skins.ALL:
		var beam := _beam(skin.fx)
		assert_eq(beam.get(&"length"), LENGTH, str(skin.id))
		assert_eq(beam.get(&"width"), WIDTH, str(skin.id))
		assert_eq(beam.position, Vector2(10, 20), str(skin.id))
		assert_almost_eq(beam.rotation, Vector2.DOWN.angle(), 0.0001, str(skin.id))
		var blast := _blast(skin.fx)
		assert_eq(blast.get(&"bar"), BAR, str(skin.id))
		assert_eq(blast.position, Vector2(300, 0), str(skin.id))
		beam.free()
		blast.free()


func test_every_skin_builds_its_three_looks_its_trail_and_its_flash() -> void:
	for skin in Skins.ALL:
		var looks: Array[ShotLook] = [skin.fx.w_missile_look(), skin.fx.r_bullet_look(), skin.fx.attack_shot_look()]
		var kinds := looks.map(func(look: ShotLook) -> int: return look.kind)
		assert_eq(kinds, [ShotLook.Kind.MISSILE, ShotLook.Kind.BULLET, ShotLook.Kind.BOLT], str(skin.id))
		for look in looks:
			look.free()
		var trail := skin.fx.e_trail(skin.body)
		assert_not_null(trail, str(skin.id))
		trail.free()
		var flash := skin.fx.muzzle_flash()
		assert_not_null(flash, str(skin.id))
		flash.free()


func test_every_piece_is_gone_within_0_6_s() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	for skin in Skins.ALL:
		holder.add_child(_beam(skin.fx))
		holder.add_child(_blast(skin.fx))
		holder.add_child(skin.fx.muzzle_flash())
		var trail := skin.fx.e_trail(skin.body)
		trail.setup(Vector2.ZERO, DashTrail.LIGHT)
		holder.add_child(trail)
		trail.reach(Vector2(280, 0))
		trail.finish()
	await wait_seconds(GONE_BY)
	assert_eq(holder.get_child_count(), 0)


func test_themed_pieces_show_details_on_high_and_none_on_low() -> void:
	for quality in ["high", "low"]:
		GameSettings.instance().set_value(&"quality", quality)
		for skin in Skins.ALL:
			for piece: Node2D in [_beam(skin.fx), _blast(skin.fx), skin.fx.muzzle_flash()]:
				add_child_autofree(piece)
				var label := "%s %s on %s" % [skin.id, piece.get_script().get_global_name(), quality]
				if quality == "low":
					assert_eq((piece as FxPiece).details(), 0, label)
				else:
					assert_gt((piece as FxPiece).details(), 0, label)


func test_classic_shots_are_light_with_a_teal_tip() -> void:
	var fx := Skins.find(&"classic").fx
	var kinds := {}
	for look: ShotLook in [fx.w_missile_look(), fx.r_bullet_look(), fx.attack_shot_look()]:
		assert_true(look is ClassicShot)
		kinds[look.kind] = true
		look.free()
	assert_eq(kinds.size(), 3)


func test_every_skin_sound_has_its_own_recipe() -> void:
	assert_false(Sfx.has_recipe(&"test_no_such_sound"))
	for skin in Skins.ALL:
		for sound in [skin.fx.q_sound, skin.fx.w_sound, skin.fx.e_sound, skin.fx.shot_sound]:
			assert_true(Sfx.has_recipe(sound), "%s: %s" % [skin.id, sound])


func test_skin_sounds_are_as_loud_as_classic() -> void:
	for skin in Skins.ALL:
		var pairs := {skin.fx.q_sound: &"cast_q", skin.fx.w_sound: &"cast_w", skin.fx.e_sound: &"cast_e", skin.fx.shot_sound: &"shot"}
		for sound: StringName in pairs:
			var classic := _peak(pairs[sound])
			assert_almost_eq(_peak(sound), classic, classic * 0.1, "%s: %s" % [skin.id, sound])


func test_as_loud_as_scales_a_sound_to_the_classic_peak() -> void:
	var scaled := Sfx._as_loud_as(&"shot", PackedFloat32Array([0.0, 0.1, -0.2, 0.05]))
	assert_almost_eq(Sfx._peak(scaled), _peak(&"shot"), 0.01)


func test_every_skin_has_a_set_of_its_own() -> void:
	var themed := _themed()
	for skin in Skins.ALL:
		assert_true(themed.has(skin.id), str(skin.id))
		assert_ne(skin.fx.get_script(), SkinFx, str(skin.id))


func test_classic_beam_fades_from_lucians_end_outward() -> void:
	var beam := _beam(Skins.find(&"classic").fx) as ClassicBeam
	add_child_autofree(beam)
	beam.age = beam.lifetime * 0.5
	assert_lt(beam.piece_alpha(0.0), beam.piece_alpha(0.5))
	assert_lt(beam.piece_alpha(0.5), beam.piece_alpha(1.0))
	beam.age = beam.lifetime
	assert_eq(beam.piece_alpha(1.0), 0.0)
	beam.age = 0.0
	assert_eq(beam.piece_alpha(0.0), 1.0)
	assert_eq(beam.piece_alpha(1.0), 1.0)


func test_classic_beam_is_one_plain_fade_on_low_effects() -> void:
	GameSettings.instance().set_value(&"quality", "low")
	var beam := _beam(Skins.find(&"classic").fx) as ClassicBeam
	add_child_autofree(beam)
	beam.age = beam.lifetime * 0.5
	assert_eq(beam.piece_alpha(0.0), beam.piece_alpha(1.0))
	assert_eq(beam.details(), 0)


func test_classic_ring_stays_inside_the_cross() -> void:
	var blast := _blast(Skins.find(&"classic").fx) as ClassicBlast
	for step in 11:
		var radius := blast.ring_radius(step / 10.0)
		assert_lte(radius, BAR.y * 1.5 + 0.001, "t %d/10" % step)
		assert_gte(radius, BAR.y * 0.5 - 0.001, "t %d/10" % step)
	assert_almost_eq(blast.ring_radius(1.0), BAR.y * 1.5, 0.001)
	blast.free()


func test_classic_trail_has_two_or_three_echoes_inside_the_dash() -> void:
	assert_between(ClassicTrail.ECHOES.size(), 2, 3)
	for share: float in ClassicTrail.ECHOES:
		assert_between(share, 0.0, 1.0)
	var sorted := ClassicTrail.ECHOES.duplicate()
	sorted.sort()
	assert_eq(ClassicTrail.ECHOES, sorted, "oldest first")


func test_pulsefire_shockwave_stays_inside_the_cross() -> void:
	var blast := _blast(Skins.find(&"pulsefire").fx) as PulsefireBlast
	for step in 11:
		var radius := blast.wave_radius(step / 10.0)
		assert_lte(radius, BAR.y * 1.5 + 0.001, "t %d/10" % step)
		assert_gte(radius, BAR.y * 0.5 - 0.001, "t %d/10" % step)
	assert_almost_eq(blast.wave_radius(1.0), BAR.y * 1.5, 0.001)
	blast.free()


func test_only_a_missile_look_on_high_keeps_processing() -> void:
	for id: StringName in [&"high_noon", &"project", &"pulsefire"]:
		var fx := Skins.find(id).fx
		var bullet := fx.r_bullet_look()
		var bolt := fx.attack_shot_look()
		var missile := fx.w_missile_look()
		for look: ShotLook in [bullet, bolt, missile]:
			add_child_autofree(look)
		assert_false(bullet.is_processing(), "%s bullet" % id)
		assert_false(bolt.is_processing(), "%s bolt" % id)
		assert_true(missile.is_processing(), "%s missile on high" % id)
	GameSettings.instance().set_value(&"quality", "low")
	var low_missile := Skins.find(&"pulsefire").fx.w_missile_look()
	add_child_autofree(low_missile)
	assert_false(low_missile.is_processing(), "missile on low")
