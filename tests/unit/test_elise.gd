extends GutTest
## Act 5's second mini boss, Elise: Cocoon (a web bolt that stuns) and Rappel
## (she rises, untargetable; a circle follows Lucian, locks, and she drops).

var lucian: Lucian
var effects: Node2D
var received: Array[Array] = []


func before_each() -> void:
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_elise_save_slot_")
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


func _elise(at: Vector2) -> Elise:
	var boss := Elise.new()
	boss.setup(load("res://data/enemies/elise.tres") as EnemyData, 5, 1, lucian)
	boss.position = at
	boss.projectile_parent = effects
	boss.warning_parent = effects
	add_child_autofree(boss)
	boss._attack_left = 1000.0
	boss.move_speed = 0.0
	return boss


func _quiet(boss: Elise) -> void:
	for id: StringName in boss._cooldowns:
		boss._cooldowns[id] = 1000.0


func _effects(type: Variant) -> Array:
	return effects.get_children().filter(func(node: Node) -> bool: return is_instance_of(node, type) and not node.is_queued_for_deletion())


func _hits(source: StringName) -> Array:
	return received.filter(func(hit: Array) -> bool: return hit[0].source == source)


func test_elise_matches_the_table() -> void:
	var data := load("res://data/enemies/elise.tres") as EnemyData
	assert_eq([data.id, data.kind, data.behavior, data.camp], [&"elise", &"mini_boss", &"elise", &"elise"])
	assert_eq([data.max_hp, data.armor, data.mr, data.damage, data.damage_type], [13000.0, 30.0, 50.0, 70.0, DamageInfo.Type.MAGIC])
	assert_eq([data.attack_range, data.attack_interval, data.move_speed, data.radius, data.projectile_speed], [550.0, 1.4, 330.0, 44.0, 900.0])
	assert_eq([data.purple_first, data.purple_repeat, data.gold], [5, 1, 300])
	assert_not_null(data.art)
	assert_has(SaveGame.BOSS_IDS, "elise")


func test_the_stage_builds_elise_unscaled() -> void:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 5, 1))
	add_child_autofree(stage)
	await wait_process_frames(2)
	var boss := stage.spawn_enemy(&"elise", Vector2(1000, 1000), 4)
	assert_is(boss, Elise)
	assert_eq(boss.max_hp, 13000.0, "no scaling")


func test_cocoon_warns_then_a_web_bolt_stuns() -> void:
	var boss := _elise(Vector2.ZERO)
	_quiet(boss)
	lucian.global_position = Vector2(500, 0)
	await wait_physics_frames(1)
	boss.cocoon()
	var warning: GroundWarning = _effects(GroundWarning)[0]
	assert_eq([warning.shape, warning.reach, warning.width], [GroundWarning.Shape.LINE, 950.0, 60.0])
	assert_almost_eq(warning.warn_time, 0.7, 0.0001)
	await wait_seconds(0.75)
	var bolts := _effects(EnemyProjectile)
	assert_eq(bolts.size(), 1)
	if bolts.size() == 1:
		assert_eq(bolts[0].speed, 1300.0)
	await wait_seconds(0.5)
	var hits := _hits(&"cocoon")
	assert_eq(hits.size(), 1)
	if hits.size() == 1:
		assert_eq([hits[0][0].amount, hits[0][0].type, hits[0][0].from_skill], [100.0, DamageInfo.Type.MAGIC, true])
	assert_true(lucian.has_cc(CrowdControl.Kind.STUN))


func test_banshees_veil_blocks_the_stun_too() -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"banshees_veil"))
	var boss := _elise(Vector2.ZERO)
	_quiet(boss)
	lucian.global_position = Vector2(500, 0)
	await wait_physics_frames(1)
	boss.cocoon()
	await wait_seconds(1.5)
	assert_eq(_hits(&"cocoon").size(), 0, "blocked")
	assert_false(lucian.has_cc(CrowdControl.Kind.STUN))


func test_rappel_is_untargetable_follows_then_locks_and_drops_there() -> void:
	var boss := _elise(Vector2.ZERO)
	_quiet(boss)
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(1)
	var busy := boss.rappel()
	assert_gt(busy, 1.9)
	assert_true(boss.untargetable)
	assert_false(boss.is_in_group(&"enemies"), "nothing can hit her up there")
	var warning: GroundWarning = _effects(GroundWarning)[0]
	assert_eq([warning.shape, warning.reach], [GroundWarning.Shape.CIRCLE, 180.0])
	await wait_seconds(0.4)
	lucian.global_position = Vector2(400, 200)
	await wait_physics_frames(2)
	assert_almost_eq(warning.global_position, Vector2(400, 200), Vector2(1, 1), "it follows")
	await wait_seconds(0.8)
	var locked := warning.global_position
	lucian.global_position = locked + Vector2(0, 500)
	await wait_seconds(0.3)
	assert_eq(warning.global_position, locked, "locked")
	assert_true(boss.untargetable, "still up")
	await wait_seconds(0.6)
	assert_false(boss.untargetable)
	assert_true(boss.is_in_group(&"enemies"))
	assert_almost_eq(boss.global_position, locked, Vector2(1, 1), "she drops where it locked")
	assert_eq(_hits(&"rappel").size(), 0, "Lucian walked out")


func test_rappel_hits_160_magic_inside_the_locked_circle() -> void:
	var boss := _elise(Vector2.ZERO)
	_quiet(boss)
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(1)
	boss.rappel()
	await wait_seconds(2.1)
	var hits := _hits(&"rappel")
	assert_eq(hits.size(), 1)
	if hits.size() == 1:
		assert_eq([hits[0][0].amount, hits[0][0].type, hits[0][0].from_skill], [160.0, DamageInfo.Type.MAGIC, true])


func test_rappel_waits_for_85_percent_and_the_skills_have_cooldowns() -> void:
	var boss := _elise(Vector2.ZERO)
	boss._cooldowns[&"rappel"] = 0.0
	boss._cooldowns[&"cocoon"] = 1000.0
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(1)
	boss._think(0.1)
	assert_eq(_effects(GroundWarning).size(), 0, "full HP: no rappel")
	boss.hp = boss.max_hp * 0.85
	boss._think(0.1)
	assert_true(boss.untargetable)
	assert_gt(boss._cooldowns[&"rappel"], 15.8)
	assert_eq(Elise.COCOON_COOLDOWN, 11.0)
	assert_eq(Elise.RAPPEL_COOLDOWN, 16.0)
