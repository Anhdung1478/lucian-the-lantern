extends GutTest
## Act 5's enemies: the sapling bomber (Specter), the Maiden of the Mist and
## the Broodmother with their summons, the web spit. Lone units for the
## moves; a real Stage for the wave, the rewards and the summons.

## Far enough from a blast's centre that Lucian is outside it.
const BLAST_OUT := 120.0 + 18.0 + 40.0

var lucian: Lucian
## Warnings and shots go here, so they are freed with the test.
var effects: Node2D
## [DamageInfo, amount] per hit Lucian took.
var received: Array[Array] = []


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_act5_enemies_save_slot_")
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


func _specter(id: String, at: Vector2) -> Specter:
	var specter := Specter.new()
	specter.setup(_data(id), 1, 1, lucian)
	specter.position = at
	specter.projectile_parent = effects
	specter.warning_parent = effects
	add_child_autofree(specter)
	return specter


func _monster(id: String, at: Vector2) -> Monster:
	var monster := Monster.new()
	monster.setup(_data(id), 1, 1, lucian)
	monster.position = at
	monster.projectile_parent = effects
	add_child_autofree(monster)
	return monster


func _warnings(parent: Node) -> Array:
	return parent.get_children().filter(func(node: Node) -> bool: return node is GroundWarning and not node.is_queued_for_deletion())


func _lethal() -> DamageInfo:
	return DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test")


## Frames until a warning is down on `parent` (up to `limit`).
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


## `id` spawned alone in the stage's fighting wave, Lucian able to be fought.
func _alone_in_wave(stage: Stage, id: StringName) -> EnemyUnit:
	stage.skip_break()
	for i in 20:
		stage.runner.tick(WaveRunner.GROUP_GAP)
	var unit := stage.spawn_enemy(id, stage.arena.spawn_points[0], stage.runner.wave)
	stage.runner.enemy_spawned()
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy != unit:
			enemy.take_damage(_lethal())
	stage.lucian.invulnerable = false
	return unit


func _units(id: StringName) -> Array[Node]:
	return get_tree().get_nodes_in_group(&"enemies").filter(func(enemy: Node) -> bool:
		return enemy is EnemyUnit and (enemy as EnemyUnit).data.id == id and (enemy as EnemyUnit).is_alive())


# --- the sapling -----------------------------------------------------------

func test_a_sapling_runs_in_then_stops_and_warns_before_it_blasts() -> void:
	var sapling := _specter("sapling", Vector2(500, 0))
	var warning := await _until_warning(effects)
	assert_not_null(warning, "a circle goes down")
	assert_lte(sapling.distance_to_target(), 80.0 + Lucian.HIT_RADIUS, "it stopped within 80")
	assert_eq(warning.reach, Specter.BLAST_RADIUS)
	assert_eq(warning.reach, 120.0)
	assert_eq(warning.warn_time, Specter.BLAST_WARN)
	assert_eq(warning.warn_time, 0.6)
	assert_eq(warning.global_position, sapling.global_position, "on its own spot")
	assert_true(received.is_empty(), "no hit yet")
	var spot := sapling.global_position
	await wait_physics_frames(10)
	assert_eq(sapling.global_position, spot, "it stands still while the warning runs")
	assert_true(sapling.is_alive())


func test_the_blast_hits_for_30_magic_and_the_sapling_vanishes() -> void:
	var sapling := _specter("sapling", Vector2(300, 0))
	var vanished: Array[bool] = []
	sapling.escaped.connect(func(_unit: EnemyUnit) -> void: vanished.append(true))
	var hit: bool = await wait_until(func() -> bool: return not received.is_empty(), 4.0)
	assert_true(hit)
	assert_eq(received.size(), 1)
	assert_eq(received[0][0].type, DamageInfo.Type.MAGIC)
	assert_eq(received[0][0].amount, 30.0)
	assert_true(sapling.has_escaped, "it vanishes")
	assert_eq(sapling.escape_note, "", "quietly")
	assert_eq(vanished.size(), 1)
	assert_false(sapling.dead, "a vanish is not a death")


func test_the_blast_hurts_only_inside_the_circle() -> void:
	var sapling := _specter("sapling", Vector2(300, 0))
	var warning := await _until_warning(effects)
	assert_not_null(warning)
	lucian.global_position = sapling.global_position + Vector2(BLAST_OUT, 0)
	var done: bool = await wait_until(func() -> bool: return sapling.has_escaped, 4.0)
	assert_true(done, "it still goes off")
	assert_true(received.is_empty(), "Lucian stepped out: nothing hit")


func test_a_sapling_killed_before_its_warning_fires_never_blasts() -> void:
	var sapling := _specter("sapling", Vector2(300, 0))
	var warning := await _until_warning(effects)
	assert_not_null(warning)
	sapling.take_damage(_lethal())
	await wait_physics_frames(60)
	assert_true(_warnings(effects).is_empty(), "the warning went with it")
	assert_true(received.is_empty(), "no blast")


func test_an_unknown_specter_behavior_walks_in_and_hits_like_any_enemy() -> void:
	var data := _data("ghoul").duplicate() as EnemyData
	data.behavior = &"unwritten"
	var specter := Specter.new()
	specter.setup(data, 1, 1, lucian)
	specter.position = Vector2(300, 0)
	specter.projectile_parent = effects
	specter.warning_parent = effects
	add_child_autofree(specter)
	var hit: bool = await wait_until(func() -> bool: return not received.is_empty(), 4.0)
	assert_true(hit, "the default think")


func test_the_stage_makes_specters_of_the_act_5_and_6_moves() -> void:
	var stage: Stage = await _stage(2, 1)
	var at: Vector2 = stage.arena.spawn_points[0]
	assert_true(stage.spawn_enemy(&"sapling", at) is Specter)
	for id in [&"spiderling", &"ghoul", &"maiden_of_the_mist", &"broodmother"]:
		var unit := stage.spawn_enemy(id, at)
		assert_true(unit is Monster and not (unit is Specter), String(id))


func test_a_sapling_that_blasts_pays_nothing_and_still_finishes_the_wave() -> void:
	var stage: Stage = await _stage(2, 1)
	var sapling := _alone_in_wave(stage, &"sapling")
	stage.lucian.global_position = sapling.global_position + Vector2(-60, 0)
	var gold := stage.wallet.gold
	var kills := stage.stats.kills
	stage.lucian.progress.xp = 0
	var gone: bool = await wait_until(func() -> bool: return sapling.has_escaped, 6.0)
	assert_true(gone, "it blasted and vanished")
	await wait_physics_frames(2)
	assert_eq(stage.wallet.gold, gold, "no gold")
	assert_eq(stage.lucian.progress.xp, 0, "no XP")
	assert_eq(stage.stats.kills, kills, "no kill")
	assert_eq(stage.runner.alive(), 0, "the wave counts it done")


func test_a_sapling_killed_first_pays_its_rewards() -> void:
	var stage: Stage = await _stage(2, 1)
	var sapling := _alone_in_wave(stage, &"sapling")
	stage.lucian.global_position = sapling.global_position + Vector2(-60, 0)
	var warning := await _until_warning(stage.get_node("Warnings"))
	assert_not_null(warning)
	var gold := stage.wallet.gold
	var kills := stage.stats.kills
	stage.lucian.progress.xp = 0
	sapling.take_damage(_lethal())
	assert_gt(stage.wallet.gold, gold, "gold")
	assert_gt(stage.lucian.progress.xp, 0, "XP")
	assert_eq(stage.stats.kills, kills + 1)
	await wait_physics_frames(60)
	assert_true(_warnings(stage.get_node("Warnings")).is_empty(), "no warning left")


# --- the Maiden and the Broodmother ----------------------------------------

func test_the_maiden_calls_2_ghouls_every_7_seconds_and_never_more_than_6() -> void:
	var stage: Stage = await _stage(2, 1)
	var maiden := _alone_in_wave(stage, &"maiden_of_the_mist")
	maiden.move_speed = 0.0
	stage.lucian.global_position = maiden.global_position + Vector2(1500, 0)
	await wait_physics_frames(400)
	assert_eq(_units(&"ghoul").size(), 0, "not before 7 s")
	await wait_physics_frames(40)
	var ghouls := _units(&"ghoul")
	assert_eq(ghouls.size(), 2, "2 at 7 s")
	for ghoul: EnemyUnit in ghouls:
		assert_true(ghoul.summoned)
		assert_lt(ghoul.global_position.distance_to(maiden.global_position), 200.0, "beside her")
	for round in 5:
		maiden._summon_left = 0.0
		await wait_physics_frames(3)
	assert_eq(_units(&"ghoul").size(), 6, "the cap")
	assert_eq(maiden.summons, 6)


func test_the_web_spit_slows_lucian_30_percent() -> void:
	_monster("broodmother", Vector2(500, 0))
	var slowed: bool = await wait_until(func() -> bool: return lucian.slow_amount() > 0.0, 6.0)
	assert_true(slowed, "the bolt landed")
	assert_eq(lucian.slow_amount(), 0.3)
	assert_eq(received[0][0].type, DamageInfo.Type.MAGIC)
	assert_eq(received[0][0].amount, 30.0)


func test_the_broodmother_keeps_her_distance() -> void:
	var brood := _monster("broodmother", Vector2(150, 0))
	await wait_seconds(4.0)
	var gap := brood.distance_to_target()
	assert_gte(gap, 440.0, "backed off from 150")
	assert_lte(gap, 620.0)
	brood.global_position = Vector2(1200, 0)
	await wait_seconds(4.0)
	assert_lte(brood.distance_to_target(), 620.0, "and closes in from far")


func test_the_broodmother_calls_a_spiderling_every_3_5_seconds_up_to_5() -> void:
	var stage: Stage = await _stage(2, 1)
	var brood := _alone_in_wave(stage, &"broodmother")
	brood.move_speed = 0.0
	stage.lucian.global_position = brood.global_position + Vector2(1500, 0)
	await wait_physics_frames(200)
	assert_eq(_units(&"spiderling").size(), 0, "not before 3.5 s")
	await wait_physics_frames(20)
	assert_eq(_units(&"spiderling").size(), 1)
	for round in 8:
		brood._summon_left = 0.0
		await wait_physics_frames(3)
	assert_eq(_units(&"spiderling").size(), 5, "the cap")
	assert_eq(brood.summons, 5)
