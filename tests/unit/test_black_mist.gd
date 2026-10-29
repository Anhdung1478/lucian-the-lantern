extends GutTest
## Act 5's Black Mist: enemies inside a bank are veiled while Lucian is far.

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
