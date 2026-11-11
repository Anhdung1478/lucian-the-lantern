extends GutTest
## Act 5's Black Mist: enemies inside a bank are veiled while Lucian is far,
## and regenerate while hurt.

const BANK := Vector3(1000, 1000, 400)
var lucian: Lucian
var mist: BlackMist


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	lucian.position = Vector2(2500, 1000)
	add_child_autofree(lucian)
	mist = BlackMist.new()
	mist.banks.append(BANK)
	mist.lucian = lucian
	add_child_autofree(mist)


func _data(kind := &"normal") -> EnemyData:
	var data := EnemyData.new()
	data.id = &"test_unit"
	data.kind = kind
	data.max_hp = 500.0
	data.damage = 10.0
	data.radius = 28.0
	data.move_speed = 0.0
	return data


func _unit(at: Vector2, kind := &"normal") -> EnemyUnit:
	var unit := EnemyUnit.new()
	var data := _data(kind)
	unit.setup(data, 1, 1, lucian)
	unit.position = at
	add_child_autofree(unit)
	return unit


func test_it_draws_between_the_floor_and_the_units() -> void:
	assert_gt(mist.z_index, StageMap.FLOOR_Z)
	assert_lt(mist.z_index, lucian.z_index)
	assert_eq(BlackMist.REVEAL_RANGE, 350.0)


func test_an_enemy_in_a_bank_is_veiled_while_lucian_is_far() -> void:
	var inside := _unit(Vector2(1000, 1000))
	var outside := _unit(Vector2(2000, 2000))
	await wait_physics_frames(2)
	assert_true(inside.veiled)
	assert_false(outside.veiled, "out of the mist")


func test_it_shows_up_close() -> void:
	var unit := _unit(Vector2(1000, 1000))
	lucian.global_position = Vector2(1000 + BlackMist.REVEAL_RANGE - 10.0, 1000)
	await wait_physics_frames(2)
	assert_false(unit.veiled, "close")
	lucian.global_position = Vector2(1000 + BlackMist.REVEAL_RANGE + 10.0, 1000)
	await wait_physics_frames(2)
	assert_true(unit.veiled, "and far again")


func test_a_veiled_enemy_is_still_hit() -> void:
	var unit := _unit(Vector2(1000, 1000))
	await wait_physics_frames(2)
	assert_true(unit.veiled)
	var before := unit.hp
	var dealt := unit.take_damage(DamageInfo.create(50.0, DamageInfo.Type.TRUE, &"test"))
	assert_gt(dealt, 0.0)
	assert_lt(unit.hp, before)
	assert_true(unit.is_in_group(&"enemies"), "still a target")


func test_the_radar_skips_a_veiled_enemy() -> void:
	var unit := _unit(Vector2(1000, 1000))
	assert_true(Radar.shows(unit))
	await wait_physics_frames(2)
	assert_true(unit.veiled)
	assert_false(Radar.shows(unit))


func test_a_mini_boss_and_a_boss_are_never_veiled() -> void:
	var mini := _unit(Vector2(1000, 1000), &"mini_boss")
	var boss := _unit(Vector2(1050, 1000), &"boss")
	var elite := _unit(Vector2(950, 1000), &"elite")
	await wait_physics_frames(2)
	assert_false(mini.veiled)
	assert_false(boss.veiled)
	assert_true(elite.veiled, "an elite is")
	assert_true(Radar.shows(mini))


func test_an_enemy_leaving_the_mist_is_unveiled() -> void:
	var unit := _unit(Vector2(1000, 1000))
	await wait_physics_frames(2)
	unit.global_position = Vector2(2000, 2000)
	await wait_physics_frames(2)
	assert_false(unit.veiled)


## P17: a hurt normal or elite enemy in a bank regenerates 2% of its max HP
## a second; one out of the mist, a boss, a mini boss or one at full HP
## doesn't.
func test_a_hurt_enemy_in_a_bank_regenerates_2_percent_a_second() -> void:
	assert_eq(BlackMist.REGEN, 0.02)
	var inside := _unit(Vector2(1000, 1000))
	var elite := _unit(Vector2(950, 1000), &"elite")
	var outside := _unit(Vector2(2000, 2000))
	var mini := _unit(Vector2(1000, 950), &"mini_boss")
	var boss := _unit(Vector2(1050, 1000), &"boss")
	var full := _unit(Vector2(1000, 1050))
	for unit: EnemyUnit in [inside, elite, outside, mini, boss]:
		unit.hp = 300.0
	mist._physics_process(1.0)
	assert_almost_eq(inside.hp, 310.0, 0.001)
	assert_almost_eq(elite.hp, 310.0, 0.001)
	assert_eq(outside.hp, 300.0, "out of the mist")
	assert_eq(mini.hp, 300.0)
	assert_eq(boss.hp, 300.0)
	assert_eq(full.hp, 500.0)
	inside.hp = 499.0
	mist._physics_process(1.0)
	assert_eq(inside.hp, 500.0, "never past full")


func test_grievous_wounds_cuts_the_mist_regeneration() -> void:
	var unit := _unit(Vector2(1000, 1000))
	unit.hp = 300.0
	unit.add_status(Enemy.GRIEVOUS_WOUNDS, 3.0)
	mist._physics_process(1.0)
	assert_almost_eq(unit.hp, 306.0, 0.001)


func test_the_regeneration_shows_only_once_the_enemy_is_seen() -> void:
	var unit := _unit(Vector2(1000, 1000))
	unit.hp = 300.0
	var shown: Array[float] = []
	unit.healed.connect(func(amount: float) -> void: shown.append(amount))
	mist._physics_process(1.0)
	assert_true(unit.veiled)
	unit._heal_number_step(EnemyUnit.HEAL_NUMBER_TIME)
	assert_eq(shown.size(), 0, "the veil hides it")
	lucian.global_position = Vector2(1000 + BlackMist.REVEAL_RANGE - 10.0, 1000)
	mist._physics_process(1.0)
	assert_false(unit.veiled)
	unit._heal_number_step(EnemyUnit.HEAL_NUMBER_TIME)
	assert_eq(shown.size(), 1)
	assert_almost_eq(shown[0], 10.0, 0.001)


func test_a_forest_stage_puts_the_mist_in_its_world() -> void:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 5, 1))
	add_child_autofree(stage)
	await wait_physics_frames(2)
	assert_is(stage.arena, DeadForestMap)
	var found := stage.get_node("World").get_children().filter(func(node: Node) -> bool: return node is BlackMist)
	assert_eq(found.size(), 1)
	assert_eq(found[0].banks, stage.arena.mist)
	assert_eq(found[0].lucian, stage.lucian)
