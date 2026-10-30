extends GutTest
## V1.1: the skills draw with the equipped skin's SkinFx and play its sounds,
## and a skin's effects never change what its skills hit, how hard, or how
## far E goes.

const Slot := ChampionProgress.Slot


## A test set that marks every piece it builds.
class FakeFx extends SkinFx:
	var last_trail: DashTrail

	func _init() -> void:
		q_sound = &"fake_q"
		w_sound = &"fake_w"
		e_sound = &"fake_e"
		shot_sound = &"fake_shot"

	func q_beam(from: Vector2, direction: Vector2, length: float, width: float) -> Node2D:
		var beam := FakeBeam.new()
		beam.position = from
		beam.rotation = direction.angle()
		beam.size = Vector2(length, width)
		return beam

	func w_blast(at: Vector2, _direction: Vector2, bar: Vector2) -> Node2D:
		var blast := FakeBlast.new()
		blast.position = at
		blast.bar = bar
		return blast

	func e_trail(body: Texture2D) -> DashTrail:
		var trail := FakeTrail.new()
		trail.body = body
		last_trail = trail
		return trail

	func shot_look(kind: ShotLook.Kind) -> ShotLook:
		return FakeLook.new(kind)

	func muzzle_flash() -> Node2D:
		return FakeFlash.new()


class FakeBeam extends Node2D:
	var size := Vector2.ZERO


class FakeBlast extends Node2D:
	var bar := Vector2.ZERO


class FakeTrail extends DashTrail:
	var body: Texture2D


class FakeLook extends ShotLook:
	pass


class FakeFlash extends Node2D:
	pass


var lucian: Lucian
var dummy: TrainingDummy
var effects: Node2D
var sfx: Sfx
var fake: FakeFx
## Final damage of each hit on the dummy.
var hits: Array[float] = []


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real settings.
	if GameSettings._instance == null or GameSettings._instance.path == GameSettings.DEFAULT_PATH:
		GameSettings._instance = GameSettings.new("user://test_skin_fx_casts_settings.json")
	hits.clear()
	sfx = Sfx.new()
	add_child_autofree(sfx)
	effects = Node2D.new()
	add_child_autofree(effects)
	dummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	dummy.position = Vector2(600, 0)
	add_child_autofree(dummy)
	dummy.damage_taken.connect(func(_info: DamageInfo, amount: float) -> void: hits.append(amount))
	fake = FakeFx.new()
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	lucian.projectile_parent = effects
	add_child_autofree(lucian)
	lucian.cheat_infinite_mana = true
	_wear(fake)


func after_each() -> void:
	GameSettings.instance().set_value(&"quality", "high")


## Classic's stats and art with `fx`'s effects, so only the effects differ.
func _wear(fx: SkinFx) -> void:
	var skin := Skins.find(&"classic").duplicate() as SkinData
	skin.fx = fx
	lucian.apply_skin(skin)


func _found(type: Variant) -> Array:
	return effects.get_children().filter(func(node: Node) -> bool:
		return is_instance_of(node, type) and not node.is_queued_for_deletion())


## The hits of one cast of `slot` toward `aim` per skin, each skin's effects
## on Classic's stats.
func _cast_with_every_skin(slot: ChampionProgress.Slot, aim: Vector2, seconds: float) -> Array:
	var per_skin := []
	for skin in Skins.ALL:
		_wear(skin.fx)
		lucian.position = Vector2.ZERO
		lucian.skills[slot].cooldown.clear()
		hits.clear()
		lucian.try_cast(slot, aim)
		await wait_seconds(seconds)
		if slot == Slot.R:
			(lucian.skills[Slot.R] as TheCulling).stop()
			await wait_seconds(0.3)
		per_skin.append(hits.duplicate())
	return per_skin


func test_q_draws_the_skin_beam_at_q_size_and_plays_its_sound() -> void:
	lucian.try_rank_up(Slot.Q)
	lucian.try_cast(Slot.Q, dummy.position)
	await wait_seconds(0.4)
	var beams := _found(FakeBeam)
	assert_eq(beams.size(), 1)
	assert_eq(beams[0].size, Vector2(800.0 - Lucian.GUN_REACH, 60.0))
	assert_eq(beams[0].position, Vector2(Lucian.GUN_REACH, 0))
	assert_eq(_found(LaserBeam).size(), 0)
	assert_eq(hits.size(), 1, "Q still hits")
	assert_true(sfx._last_played.has(&"fake_q"))


func test_w_flies_the_skin_missile_and_bursts_in_the_skin_cross() -> void:
	lucian.try_rank_up(Slot.W)
	lucian.try_cast(Slot.W, dummy.position)
	await wait_seconds(0.3)
	var missiles := _found(LinearProjectile)
	assert_eq(missiles.size(), 1)
	assert_true(missiles[0].look is FakeLook)
	assert_eq(missiles[0].look.kind, ShotLook.Kind.MISSILE)
	assert_true(sfx._last_played.has(&"fake_w"))
	await wait_seconds(0.5)
	var blasts := _found(FakeBlast)
	assert_eq(blasts.size(), 1)
	assert_eq(blasts[0].bar, Vector2(400, 60))
	assert_eq(_found(CrossBlast).size(), 0)
	assert_eq(hits.size(), 1, "W still hits")


func test_e_leaves_the_skin_trail_with_lucians_body() -> void:
	lucian.try_rank_up(Slot.E)
	lucian.try_cast(Slot.E, Vector2(0, 1000))
	var trails := _found(FakeTrail)
	assert_eq(trails.size(), 1)
	assert_eq(trails[0].body, lucian.visuals.body_texture())
	assert_true(sfx._last_played.has(&"fake_e"))
	await wait_seconds(0.3)
	assert_almost_eq(trails[0].length, 280.0, 2.0)


func test_on_low_effects_e_makes_no_trail_and_frees_the_skin_one() -> void:
	GameSettings.instance().set_value(&"quality", "low")
	lucian.try_rank_up(Slot.E)
	lucian.try_cast(Slot.E, Vector2(0, 1000))
	assert_eq(_found(DashTrail).size(), 0)
	assert_false(is_instance_valid(fake.last_trail))


func test_an_e_of_zero_length_frees_the_skin_trail() -> void:
	lucian.try_rank_up(Slot.E)
	lucian.try_cast(Slot.E, lucian.position)
	assert_eq(_found(DashTrail).size(), 0)
	assert_false(is_instance_valid(fake.last_trail))


func test_basic_attacks_and_lightslinger_carry_the_skin_look_flash_and_sound() -> void:
	var looks := []
	effects.child_entered_tree.connect(func(node: Node) -> void:
		if node is AttackProjectile:
			var look := (node as AttackProjectile).look
			looks.append([look is FakeLook, look.kind]))
	lucian.passive.charge()
	lucian.passive.fire_basic_attack(dummy)
	await wait_seconds(0.25)
	assert_eq(looks.size(), 2, "the attack and Lightslinger's second shot")
	for look in looks:
		assert_true(look[0])
		assert_eq(look[1], ShotLook.Kind.BOLT)
	var flashes := _found(FakeFlash)
	assert_eq(flashes.size(), 2)
	assert_almost_eq(flashes[0].rotation, lucian.visuals.global_rotation, 0.0001)
	assert_true(sfx._last_played.has(&"fake_shot"))


func test_r_bullets_carry_the_skin_look() -> void:
	lucian.progress.set_level(6)
	lucian.try_rank_up(Slot.R)
	var looks := []
	effects.child_entered_tree.connect(func(node: Node) -> void:
		if node is LinearProjectile:
			var look := (node as LinearProjectile).look
			looks.append([look is FakeLook, look.kind]))
	lucian.try_cast(Slot.R, dummy.position)
	await wait_seconds(0.5)
	assert_gt(looks.size(), 2)
	for look in looks:
		assert_true(look[0])
		assert_eq(look[1], ShotLook.Kind.BULLET)
	assert_gt(_found(FakeFlash).size(), 2)


func test_q_hits_the_same_with_every_skins_effects() -> void:
	lucian.try_rank_up(Slot.Q)
	var per_skin: Array = await _cast_with_every_skin(Slot.Q, dummy.position, 0.45)
	assert_eq(per_skin[0].size(), 1)
	for i in per_skin.size():
		assert_eq(per_skin[i], per_skin[0], str(Skins.ALL[i].id))


func test_w_hits_the_same_with_every_skins_effects() -> void:
	lucian.try_rank_up(Slot.W)
	var per_skin: Array = await _cast_with_every_skin(Slot.W, dummy.position, 0.8)
	assert_eq(per_skin[0].size(), 1)
	for i in per_skin.size():
		assert_eq(per_skin[i], per_skin[0], str(Skins.ALL[i].id))


func test_r_bullets_hit_the_same_with_every_skins_effects() -> void:
	lucian.progress.set_level(6)
	lucian.try_rank_up(Slot.R)
	var per_skin: Array = await _cast_with_every_skin(Slot.R, dummy.position, 0.6)
	var first: float = per_skin[0][0]
	for i in per_skin.size():
		assert_gt(per_skin[i].size(), 2, str(Skins.ALL[i].id))
		for amount: float in per_skin[i]:
			assert_almost_eq(amount, first, 0.0001, str(Skins.ALL[i].id))


func test_e_goes_as_far_with_every_skins_effects() -> void:
	lucian.try_rank_up(Slot.E)
	for skin in Skins.ALL:
		_wear(skin.fx)
		lucian.position = Vector2.ZERO
		lucian.skills[Slot.E].cooldown.clear()
		lucian.try_cast(Slot.E, Vector2(0, -2000))
		await wait_seconds(0.4)
		assert_almost_eq(lucian.position.y, -280.0, 2.0, str(skin.id))
