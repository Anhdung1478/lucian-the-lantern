extends GutTest
## Units that feel alive: the walk sway, lunges and recoils, the squash of a
## hit, the fade-in of a spawn and the burst of a death. They move only the
## art, never the body; they are off on Low quality and when nothing renders.

var lucian: Lucian


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real settings.
	if GameSettings._instance == null or GameSettings._instance.path == GameSettings.DEFAULT_PATH:
		GameSettings._instance = GameSettings.new("user://test_unit_motion_settings.json")
	Juice.renders = true
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	lucian.position = Vector2(2000, 0)
	add_child_autofree(lucian)


func after_each() -> void:
	Juice.renders = false
	GameSettings.instance().set_value(&"quality", "high")


## A unit that stands still: only what a test does moves its art.
func _data(frees := false) -> EnemyData:
	var data := EnemyData.new()
	data.id = &"test_unit"
	data.max_hp = 500.0
	data.damage = 10.0
	data.radius = 30.0
	data.move_speed = 0.0
	data.attack_range = 110.0
	data.frees = frees
	return data


func _unit(at := Vector2.ZERO, data := _data()) -> EnemyUnit:
	var unit := EnemyUnit.new()
	unit.setup(data, 1, 1, lucian)
	unit.position = at
	add_child_autofree(unit)
	return unit


## A unit whose fade-in is over.
func _grown_unit(at := Vector2.ZERO, data := _data()) -> EnemyUnit:
	var unit := _unit(at, data)
	await wait_physics_frames(roundi(UnitMotion.SPAWN_TIME * 60.0) + 3)
	return unit


func _lethal() -> DamageInfo:
	return DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test")


func _bursts() -> Array[Node]:
	return get_children().filter(func(node: Node) -> bool: return node is DeathBurst and not node.is_queued_for_deletion())


## A sprite under a plain unit, moved by a UnitMotion of its own.
func _lone_motion(home := Vector2.ZERO) -> UnitMotion:
	var unit := Node2D.new()
	add_child_autofree(unit)
	var sprite := Node2D.new()
	sprite.position = home
	unit.add_child(sprite)
	var motion := UnitMotion.new()
	motion.setup(sprite, unit, 30.0)
	unit.add_child(motion)
	return motion


# --- The motion itself ---------------------------------------------------


func test_nothing_renders_headless_so_nothing_moves() -> void:
	Juice.renders = false
	assert_false(Juice.on())
	var motion := _lone_motion()
	assert_false(motion.is_physics_processing(), "it never runs")
	motion.lunge()
	motion.flinch()
	motion.appear()
	motion.die(0.4)
	assert_false(motion.is_moving())
	assert_eq(motion.art.scale, Vector2.ONE)


func test_low_quality_turns_the_motion_off() -> void:
	GameSettings.instance().set_value(&"quality", "low")
	assert_false(Juice.on())
	var motion := _lone_motion()
	motion.lunge()
	motion.flinch()
	motion.appear()
	(motion.get_parent() as Node2D).position += Vector2(8, 0)
	await wait_physics_frames(3)
	assert_false(motion.is_moving())
	assert_eq(motion.art.position, Vector2.ZERO)
	assert_eq(motion.art.rotation, 0.0)
	assert_eq(motion.art.scale, Vector2.ONE)


func test_a_walking_unit_sways_and_settles_once_it_stands() -> void:
	var motion := _lone_motion()
	var unit := motion.get_parent() as Node2D
	var turned := 0.0
	var swelled := 1.0
	# A step on every physics frame, as a walking unit takes.
	var step := func() -> void: unit.position += Vector2(5, 0)
	get_tree().physics_frame.connect(step)
	for frame in 30:
		await wait_physics_frames(1)
		turned = maxf(turned, absf(motion.art.rotation))
		swelled = maxf(swelled, motion.art.scale.x)
	get_tree().physics_frame.disconnect(step)
	assert_gt(turned, UnitMotion.SWAY * 0.6, "it turns a little each way")
	assert_lte(turned, UnitMotion.SWAY + 0.001, "never more than the sway")
	assert_gt(swelled, 1.01, "and swells with each step")
	assert_eq(motion.art.position, Vector2.ZERO, "a sway is no step aside")
	await wait_physics_frames(roundi(UnitMotion.SETTLE * 60.0) + 4)
	assert_false(motion.is_moving(), "standing: at rest")
	assert_eq(motion.art.rotation, 0.0)
	assert_eq(motion.art.scale, Vector2.ONE)


func test_a_dash_adds_no_more_stride_than_a_run() -> void:
	var motion := _lone_motion()
	var unit := motion.get_parent() as Node2D
	await wait_physics_frames(1)
	var before := motion._phase
	unit.position += Vector2(4000, 0)
	await wait_physics_frames(1)
	assert_almost_eq(motion._phase - before, UnitMotion.MAX_STEP / UnitMotion.STRIDE * TAU, 0.001)


func test_a_lunge_goes_forward_and_comes_back() -> void:
	var motion := _lone_motion()
	motion.lunge()
	var furthest := 0.0
	for frame in 8:
		await wait_physics_frames(1)
		furthest = maxf(furthest, motion.art.position.x)
		assert_eq(motion.art.position.y, 0.0, "straight along its facing")
	assert_gt(furthest, 30.0 * UnitMotion.LUNGE * 0.7, "toward what it faces")
	assert_lte(furthest, 30.0 * UnitMotion.LUNGE + 0.001)
	await wait_physics_frames(roundi(UnitMotion.LUNGE_TIME * 60.0))
	assert_eq(motion.art.position, Vector2.ZERO, "back")
	assert_false(motion.is_moving())


func test_a_recoil_goes_back_and_returns() -> void:
	var motion := _lone_motion()
	motion.recoil()
	var furthest := 0.0
	for frame in 6:
		await wait_physics_frames(1)
		furthest = minf(furthest, motion.art.position.x)
	assert_lt(furthest, -30.0 * UnitMotion.RECOIL * 0.7, "away from what it faces")
	await wait_physics_frames(roundi(UnitMotion.RECOIL_TIME * 60.0))
	assert_eq(motion.art.position, Vector2.ZERO)


func test_a_flinch_squashes_and_springs_back() -> void:
	var motion := _lone_motion()
	motion.flinch()
	await wait_physics_frames(1)
	assert_lt(motion.art.scale.x, 0.95, "shorter along its facing")
	assert_gt(motion.art.scale.y, 1.02, "wider across it")
	await wait_physics_frames(roundi(UnitMotion.SQUASH_TIME * 60.0) + 2)
	assert_eq(motion.art.scale, Vector2.ONE)


func test_the_art_keeps_its_own_place() -> void:
	var motion := _lone_motion(Vector2(0, -4))
	motion.lunge()
	await wait_physics_frames(3)
	assert_eq(motion.art.position.y, -4.0)
	assert_gt(motion.art.position.x, 0.0)
	await wait_physics_frames(roundi(UnitMotion.LUNGE_TIME * 60.0))
	assert_eq(motion.art.position, Vector2(0, -4))


# --- Enemies -------------------------------------------------------------


func test_an_enemy_fades_and_grows_in_but_fights_at_once() -> void:
	var unit := _unit()
	assert_eq(unit.modulate.a, 0.0, "unseen at first")
	assert_almost_eq(unit.sprite.scale.x, UnitMotion.SPAWN_SCALE, 0.001, "and small")
	assert_true(unit.is_in_group(&"enemies"), "there from the first frame")
	assert_gt(unit.take_damage(DamageInfo.create(10.0, DamageInfo.Type.TRUE, &"test")), 0.0, "and it can be hit")
	await wait_physics_frames(8)
	assert_between(unit.modulate.a, 0.2, 0.8)
	await wait_physics_frames(roundi(UnitMotion.SPAWN_TIME * 60.0))
	assert_eq(unit.modulate.a, 1.0)
	assert_eq(unit.sprite.scale, Vector2.ONE)


func test_a_melee_hit_lunges_the_art_not_the_body() -> void:
	lucian.global_position = Vector2(100, 0)
	var unit: EnemyUnit = await _grown_unit()
	var hp := lucian.hp
	unit._attack_left = 0.0
	await wait_physics_frames(4)
	assert_lt(lucian.hp, hp, "the hit landed at once, as before")
	assert_gt(unit.sprite.position.x, 2.0, "its art steps at him")
	assert_eq(unit.global_position, Vector2.ZERO, "its body stays")
	assert_eq(unit.visuals.position, Vector2.ZERO)


func test_a_bolt_kicks_the_art_back() -> void:
	var unit: EnemyUnit = await _grown_unit()
	unit.fire_bolt(unit.make_hit(), 500.0, 600.0)
	await wait_physics_frames(3)
	assert_lt(unit.sprite.position.x, -1.0)
	assert_eq(unit.global_position, Vector2.ZERO)


func test_a_hit_squashes_the_art() -> void:
	var unit: EnemyUnit = await _grown_unit()
	unit.take_damage(DamageInfo.create(10.0, DamageInfo.Type.TRUE, &"test"))
	await wait_physics_frames(1)
	assert_lt(unit.sprite.scale.x, 0.95)
	assert_eq(unit.visuals.scale, Vector2.ONE, "the visuals keep their scale for leaps")


func test_a_death_flattens_the_art_and_bursts() -> void:
	var unit: EnemyUnit = await _grown_unit(Vector2(300, 200))
	unit.take_damage(_lethal())
	assert_eq(_bursts().size(), 1, "one burst, beside it in its parent")
	var burst := _bursts()[0] as DeathBurst
	assert_eq(burst.position, Vector2(300, 200))
	assert_eq(burst.radius, unit.radius)
	await wait_physics_frames(8)
	assert_true(is_instance_valid(unit), "the fade takes as long as before")
	assert_lt(unit.sprite.scale.y, 0.9, "flattening")
	var id := unit.get_instance_id()
	await wait_until(func() -> bool: return not is_instance_id_valid(id), 2.0)
	assert_false(is_instance_id_valid(id), "then it goes")
	await wait_until(func() -> bool: return _bursts().is_empty(), 2.0)
	assert_eq(_bursts().size(), 0, "the burst frees itself")


func test_a_death_in_the_middle_of_the_fade_in_still_fades_out() -> void:
	var unit := _unit()
	await wait_physics_frames(6)
	var seen := unit.modulate.a
	assert_between(seen, 0.2, 0.6, "half faded in")
	unit.take_damage(_lethal())
	await wait_physics_frames(6)
	assert_true(is_instance_valid(unit))
	assert_lte(unit.modulate.a, seen, "the fade-in no longer runs")
	var id := unit.get_instance_id()
	await wait_until(func() -> bool: return not is_instance_id_valid(id), 2.0)
	assert_false(is_instance_id_valid(id), "it fades out and goes")


func test_a_freed_soul_and_an_escape_keep_their_own_end() -> void:
	var soul: EnemyUnit = await _grown_unit(Vector2.ZERO, _data(true))
	var runner := _unit(Vector2(400, 0))
	await wait_physics_frames(20)
	soul.take_damage(_lethal())
	runner.escape()
	await wait_physics_frames(15)
	assert_eq(_bursts().size(), 0, "no burst for either")
	assert_eq(soul.sprite.scale, Vector2.ONE, "the hit's squash is over, and nothing flattens it")
	assert_eq(runner.sprite.scale, Vector2.ONE)


func test_low_quality_keeps_enemies_plain() -> void:
	GameSettings.instance().set_value(&"quality", "low")
	lucian.global_position = Vector2(100, 0)
	var unit := _unit()
	assert_eq(unit.modulate.a, 1.0, "no fade-in")
	assert_eq(unit.sprite.scale, Vector2.ONE)
	unit._attack_left = 0.0
	await wait_physics_frames(4)
	assert_eq(unit.sprite.position, Vector2.ZERO, "no lunge")
	unit.take_damage(_lethal())
	assert_eq(_bursts().size(), 0, "no burst")
	await wait_physics_frames(3)
	assert_eq(unit.sprite.scale, Vector2.ONE, "the plain fade")


# --- Lucian --------------------------------------------------------------


func test_lucians_art_kicks_back_with_a_shot_and_his_muzzles_stay() -> void:
	await wait_physics_frames(1)
	var muzzle := lucian.visuals.muzzle_position(LucianVisuals.Gun.LEFT)
	var body: Sprite2D = lucian.get_node("Visuals/Body")
	lucian.flash_muzzle(LucianVisuals.Gun.LEFT)
	await wait_physics_frames(3)
	assert_lt(body.position.x, -1.0, "his art kicks back")
	assert_eq(lucian.visuals.muzzle_position(LucianVisuals.Gun.LEFT), muzzle, "the shot still leaves from the same point")
	assert_eq(lucian.global_position, Vector2(2000, 0))


func test_lucians_art_squashes_when_he_is_hit() -> void:
	await wait_physics_frames(1)
	var body: Sprite2D = lucian.get_node("Visuals/Body")
	lucian.take_damage(DamageInfo.create(20.0, DamageInfo.Type.PHYSICAL, &"basic"))
	await wait_physics_frames(1)
	assert_lt(body.scale.x, 0.95)
	assert_eq(lucian.visuals.scale, Vector2.ONE)
	await wait_physics_frames(roundi(UnitMotion.SQUASH_TIME * 60.0) + 2)
	assert_eq(body.scale, Vector2.ONE)


func test_lucians_art_sways_as_he_walks() -> void:
	var body: Sprite2D = lucian.get_node("Visuals/Body")
	lucian.command_move(lucian.global_position + Vector2(600, 0))
	var turned := 0.0
	for frame in 40:
		await wait_physics_frames(1)
		turned = maxf(turned, absf(body.rotation))
	assert_gt(turned, UnitMotion.SWAY * 0.5)
	assert_eq(lucian.visuals.rotation, 0.0, "his facing is his aim, untouched")


# --- The burst -----------------------------------------------------------


func test_a_bursts_color_comes_from_the_art() -> void:
	assert_eq(DeathBurst.color_of(null), DeathBurst.FALLBACK)
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.1, 0.1, 0.12))
	image.fill_rect(Rect2i(4, 4, 8, 8), Color(0.1, 0.4, 0.9))
	var found := DeathBurst._read_color(image)
	assert_gt(found.b, found.r + 0.3, "the vivid blue wins over the dark outline")
	assert_eq(DeathBurst._read_color(Image.create(8, 8, false, Image.FORMAT_RGBA8)), DeathBurst.FALLBACK, "nothing opaque: the fallback")
	assert_eq(DeathBurst._read_color(null), DeathBurst.FALLBACK)
