extends GutTest
## Act 6's enemies: the Spectral Rider's charge, the Chain Warden's chain and
## its perch, the Lantern Soul that goes free, and the stage's routing. Lone
## units on small maps for the moves; a real 6-x Stage for the rewards.

const MAP_SIZE := Vector2(3000, 2000)
## A wall 80 wide standing across the middle of the small map.
const WALL := [Vector2(1460, 400), Vector2(1540, 400), Vector2(1540, 1600), Vector2(1460, 1600)]
## An abyss strip 100 wide.
const ABYSS := [Vector2(1250, 400), Vector2(1350, 400), Vector2(1350, 1600), Vector2(1250, 1600)]
## A small abyss square, where a perched warden stands.
const LEDGE_ABYSS := [Vector2(900, 900), Vector2(1100, 900), Vector2(1100, 1100), Vector2(900, 1100)]

var lucian: Lucian
## Warnings and shots go here, so they are freed with the test.
var effects: Node2D
## [DamageInfo, amount] per hit Lucian took.
var received: Array[Array] = []


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_act6_enemies_save_slot_")
	received.clear()
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	effects = Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	add_child_autofree(lucian)
	lucian.global_position = Vector2.ZERO
	lucian.damage_received.connect(func(info: DamageInfo, amount: float) -> void: received.append([info, amount]))


func after_each() -> void:
	get_tree().paused = false


func _data(id: String) -> EnemyData:
	return load("res://data/enemies/%s.tres" % id) as EnemyData


## A Specter at `at` with its attack ready (act 1: no scaling to muddy numbers).
func _specter(id: String, at: Vector2) -> Specter:
	var specter := Specter.new()
	specter.setup(_data(id), 1, 1, lucian)
	specter.position = at
	specter.projectile_parent = effects
	specter.warning_parent = effects
	add_child_autofree(specter)
	specter._attack_left = 0.0
	return specter


func _map(polygons: Array, chasm := false) -> StageMap:
	var map := StageMap.new()
	map.size = MAP_SIZE
	for polygon in polygons:
		if chasm:
			map.chasm_polygons.append(PackedVector2Array(polygon))
		else:
			map.wall_polygons.append(PackedVector2Array(polygon))
	add_child_autofree(map)
	return map


func _warnings(parent: Node) -> Array:
	return parent.get_children().filter(func(node: Node) -> bool: return node is GroundWarning and not node.is_queued_for_deletion())


func _lethal() -> DamageInfo:
	return DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test")


func _until_warning(parent: Node, limit := 240) -> GroundWarning:
	for frame in limit:
		var found := _warnings(parent)
		if not found.is_empty():
			return found[0]
		await wait_physics_frames(1)
	return null


func _stage(act: int, stage_number: int) -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, stage_number))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


# --- the Spectral Rider ------------------------------------------------------


func test_the_rider_marks_an_800_by_90_line_toward_lucian_for_0_8_seconds() -> void:
	var rider := _specter("spectral_rider", Vector2(-600, 0))
	var warning := await _until_warning(effects)
	assert_not_null(warning, "a line goes down")
	assert_eq([warning.reach, warning.width, warning.warn_time], [800.0, 90.0, 0.8])
	assert_eq([Specter.CHARGE_LENGTH, Specter.CHARGE_WIDTH, Specter.CHARGE_WARN], [800.0, 90.0, 0.8])
	assert_almost_eq(warning.direction, Vector2.RIGHT, Vector2(0.01, 0.01))
	assert_eq(warning.global_position, rider.global_position)
	var spot := rider.global_position
	await wait_physics_frames(20)
	assert_eq(rider.global_position, spot, "it stands while the warning runs")
	assert_false(rider.is_charging())


func test_the_rider_charges_along_the_warning_hits_for_60_and_pushes_150() -> void:
	var rider := _specter("spectral_rider", Vector2(-600, 0))
	var landed := [Vector2.ZERO]
	rider.landed.connect(func() -> void: landed[0] = rider.global_position)
	var warning := await _until_warning(effects)
	assert_not_null(warning)
	var charged: bool = await wait_until(func() -> bool: return rider.is_charging(), 2.0)
	assert_true(charged, "it charges when the mark fires")
	assert_eq(rider.collision_mask, Layers.WORLD | Layers.CHASM)
	var hit: bool = await wait_until(func() -> bool: return not received.is_empty(), 2.0)
	assert_true(hit, "Lucian stood in the line")
	assert_eq(received.size(), 1)
	assert_eq(received[0][0].type, DamageInfo.Type.PHYSICAL)
	assert_eq(received[0][0].amount, 60.0)
	await wait_physics_frames(30)
	assert_eq(received.size(), 1, "once")
	assert_almost_eq(lucian.global_position.x, 150.0, 6.0, "pushed 150 along the charge")
	assert_almost_eq(lucian.global_position.y, 0.0, 6.0)
	assert_almost_eq(landed[0], Vector2(200, 0), Vector2(2, 2), "he ran the full 800 from his spot")
	assert_false(rider.is_charging())


func test_a_step_sideways_dodges_the_rider() -> void:
	var rider := _specter("spectral_rider", Vector2(-600, 0))
	var landed := [0]
	rider.landed.connect(func() -> void: landed[0] += 1)
	var warning := await _until_warning(effects)
	assert_not_null(warning)
	lucian.global_position = Vector2(0, 200)
	var done: bool = await wait_until(func() -> bool: return landed[0] == 1, 3.0)
	assert_true(done, "he charged")
	assert_true(received.is_empty(), "and missed")
	assert_almost_eq(lucian.global_position, Vector2(0, 200), Vector2(1, 1), "no push")


func test_a_wall_stops_the_rider() -> void:
	_map([WALL])
	lucian.global_position = Vector2(1850, 1000)
	var rider := _specter("spectral_rider", Vector2(1100, 1000))
	var landed := [0]
	rider.landed.connect(func() -> void: landed[0] += 1)
	var done: bool = await wait_until(func() -> bool: return landed[0] == 1, 4.0)
	assert_true(done)
	assert_lt(rider.global_position.x, 1460.0 - rider.radius * 0.85 + 2.0, "short of the wall")
	assert_gt(rider.global_position.x, 1250.0, "he ran up to it")
	assert_true(received.is_empty(), "Lucian is behind it")


func test_the_abyss_stops_the_rider() -> void:
	_map([ABYSS], true)
	lucian.global_position = Vector2(1900, 1000)
	var rider := _specter("spectral_rider", Vector2(1100, 1000))
	var landed := [0]
	rider.landed.connect(func() -> void: landed[0] += 1)
	var done: bool = await wait_until(func() -> bool: return landed[0] == 1, 4.0)
	assert_true(done)
	assert_lt(rider.global_position.x, 1250.0 - rider.radius * 0.85 + 2.0, "short of the edge")


func test_a_far_rider_walks_in_until_lucian_is_in_range_then_marks() -> void:
	lucian.global_position = Vector2(1500, 0)
	var rider := _specter("spectral_rider", Vector2.ZERO)
	var warning := await _until_warning(effects, 600)
	assert_not_null(warning)
	assert_gt(rider.global_position.x, 400.0, "he walked in first")
	assert_lte(rider.distance_to_target(), 800.0 + Lucian.HIT_RADIUS + 1.0)


func test_a_rider_charges_again_after_4_seconds() -> void:
	var rider := _specter("spectral_rider", Vector2(-600, 0))
	var charges := [0]
	rider.landed.connect(func() -> void: charges[0] += 1)
	var first: bool = await wait_until(func() -> bool: return charges[0] == 1, 3.0)
	assert_true(first)
	lucian.global_position = rider.global_position + Vector2(500, 0)
	assert_eq(_data("spectral_rider").attack_interval, 4.0)
	var again: bool = await wait_until(func() -> bool: return charges[0] == 2, 6.0)
	assert_true(again, "a second charge")


func test_a_rider_killed_during_its_warning_never_charges() -> void:
	var rider := _specter("spectral_rider", Vector2(-600, 0))
	var warning := await _until_warning(effects)
	assert_not_null(warning)
	rider.take_damage(_lethal())
	await wait_physics_frames(60)
	assert_true(received.is_empty())
	assert_false(is_instance_valid(rider) and rider.is_charging())
	assert_true(_warnings(effects).is_empty(), "the warning went with him")


# --- the Chain Warden --------------------------------------------------------


func test_the_warden_marks_a_700_by_60_line_for_0_8_seconds() -> void:
	lucian.global_position = Vector2(600, 0)
	var warden := _specter("chain_warden", Vector2.ZERO)
	var warning := await _until_warning(effects)
	assert_not_null(warning)
	assert_eq([warning.reach, warning.width, warning.warn_time], [700.0, 60.0, 0.8])
	assert_eq([Specter.CHAIN_LENGTH, Specter.CHAIN_WIDTH, Specter.CHAIN_WARN, Specter.CHAIN_SPEED], [700.0, 60.0, 0.8, 1200.0])
	assert_almost_eq(warning.direction, Vector2.RIGHT, Vector2(0.01, 0.01))
	var spot := warden.global_position
	await wait_physics_frames(20)
	assert_eq(warden.global_position, spot, "600 is within its 500-700: it stands")


func test_the_chain_hits_for_45_and_pulls_lucian_300_toward_the_warden() -> void:
	lucian.global_position = Vector2(600, 0)
	var warden := _specter("chain_warden", Vector2.ZERO)
	var hit: bool = await wait_until(func() -> bool: return not received.is_empty(), 3.0)
	assert_true(hit)
	assert_eq(received[0][0].type, DamageInfo.Type.PHYSICAL)
	assert_eq(received[0][0].amount, 45.0)
	await wait_physics_frames(40)
	assert_eq(received.size(), 1)
	assert_almost_eq(lucian.global_position.x, 300.0, 6.0, "300 of the 600 closed")
	assert_almost_eq(lucian.global_position.y, 0.0, 6.0)


func test_a_sidestep_dodges_the_chain() -> void:
	lucian.global_position = Vector2(600, 0)
	_specter("chain_warden", Vector2.ZERO)
	var warning := await _until_warning(effects)
	assert_not_null(warning)
	lucian.global_position = Vector2(600, 200)
	await wait_seconds(1.6)
	assert_true(received.is_empty())
	assert_almost_eq(lucian.global_position, Vector2(600, 200), Vector2(1, 1))


func test_the_abyss_edge_stops_the_pull() -> void:
	_map([ABYSS], true)
	lucian.global_position = Vector2(1600, 1000)
	_specter("chain_warden", Vector2(1000, 1000))
	var hit: bool = await wait_until(func() -> bool: return not received.is_empty(), 3.0)
	assert_true(hit)
	await wait_physics_frames(40)
	# A full pull would end at 1300, inside the abyss (1250-1350).
	assert_gt(lucian.global_position.x, 1350.0, "he stopped at the edge")
	assert_lt(lucian.global_position.x, 1450.0, "after being pulled up to it")


func test_a_perched_warden_never_moves_but_still_chains() -> void:
	_map([LEDGE_ABYSS], true)
	# Too close for an unperched warden (it would back off).
	lucian.global_position = Vector2(1300, 1000)
	var warden := _specter("chain_warden", Vector2(1000, 1000))
	warden.perched = true
	var warning := await _until_warning(effects)
	assert_not_null(warning, "it still chains")
	assert_eq(warden.global_position, Vector2(1000, 1000))
	var hit: bool = await wait_until(func() -> bool: return not received.is_empty(), 3.0)
	assert_true(hit)
	await wait_physics_frames(30)
	assert_eq(warden.global_position, Vector2(1000, 1000), "never moved")


func test_an_unperched_warden_keeps_500_to_700_away() -> void:
	lucian.global_position = Vector2(200, 0)
	var warden := _specter("chain_warden", Vector2.ZERO)
	warden._attack_left = 99.0
	await wait_physics_frames(60)
	assert_lt(warden.global_position.x, -50.0, "too close: it backs away")
	lucian.global_position = Vector2(1200, 0)
	var closer: bool = await wait_until(func() -> bool: return warden.distance_to_target() <= 700.0, 6.0)
	assert_true(closer, "too far: it comes in")


func test_a_warden_killed_during_its_warning_never_chains() -> void:
	lucian.global_position = Vector2(600, 0)
	var warden := _specter("chain_warden", Vector2.ZERO)
	var warning := await _until_warning(effects)
	assert_not_null(warning)
	warden.take_damage(_lethal())
	await wait_seconds(1.5)
	assert_true(received.is_empty())


# --- the Mist Walker and the Lantern Soul ------------------------------------


func test_the_stage_makes_monsters_of_walkers_and_souls_and_specters_of_the_rest() -> void:
	var stage: Stage = await _stage(6, 1)
	var at: Vector2 = stage.arena.spawn_points[0]
	assert_true(stage.spawn_enemy(&"mist_walker", at) is Monster)
	assert_true(stage.spawn_enemy(&"lantern_soul", at) is Monster)
	assert_true(stage.spawn_enemy(&"spectral_rider", at) is Specter)
	assert_true(stage.spawn_enemy(&"chain_warden", at) is Specter)


func test_a_soul_spits_a_bolt_for_22_magic() -> void:
	var soul := Monster.new()
	soul.setup(_data("lantern_soul"), 1, 1, lucian)
	soul.position = Vector2(500, 0)
	soul.projectile_parent = effects
	add_child_autofree(soul)
	soul._attack_left = 0.0
	var hit: bool = await wait_until(func() -> bool: return not received.is_empty(), 4.0)
	assert_true(hit)
	assert_eq(received[0][0].type, DamageInfo.Type.MAGIC)
	assert_eq(received[0][0].amount, 22.0)


func test_a_freed_soul_pays_like_a_kill_and_plays_the_freed_fade() -> void:
	var stage: Stage = await _stage(6, 1)
	var soul := stage.spawn_enemy(&"lantern_soul", stage.arena.spawn_points[0]) as EnemyUnit
	await wait_physics_frames(1)
	var gold := stage.wallet.gold
	var kills := stage.stats.kills
	stage.lucian.progress.xp = 0
	soul.take_damage(_lethal())
	var data := _data("lantern_soul")
	assert_gt(stage.wallet.gold, gold, "gold")
	assert_gt(stage.lucian.progress.xp, 0, "XP")
	assert_almost_eq(float(stage.wallet.gold - gold), data.gold * data.reward_scale(6), 12.0, "act 6's rate")
	assert_eq(stage.stats.kills, kills + 1)
	await wait_physics_frames(20)
	assert_true(is_instance_valid(soul), "a slower fade than the grey one")
	assert_lt(soul.visuals.position.y, -5.0, "it rises")
	assert_gt(soul.sprite.modulate.g, 1.0, "brighter")
