extends GutTest
## Act 5's first mini boss, Maokai: Twisted Advance (a leap onto a circle
## warning, a root inside it) and Nature's Grasp (a vine wave along a line
## warning, a root on a hit; trees stop it). Skills are driven directly.

var lucian: Lucian
var effects: Node2D
## [DamageInfo, amount] per hit Lucian took.
var received: Array[Array] = []


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_maokai_save_slot_")
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


func _maokai(at: Vector2) -> Maokai:
	var boss := Maokai.new()
	boss.setup(load("res://data/enemies/maokai.tres") as EnemyData, 5, 1, lucian)
	boss.position = at
	boss.projectile_parent = effects
	boss.warning_parent = effects
	add_child_autofree(boss)
	boss._attack_left = 1000.0
	boss.move_speed = 0.0
	return boss


func _quiet(boss: Maokai) -> void:
	for id: StringName in boss._cooldowns:
		boss._cooldowns[id] = 1000.0


func _effects(type: Variant) -> Array:
	return effects.get_children().filter(func(node: Node) -> bool: return is_instance_of(node, type) and not node.is_queued_for_deletion())


func _hits(source: StringName) -> Array:
	return received.filter(func(hit: Array) -> bool: return hit[0].source == source)


func _wall(at: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = Layers.WORLD
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 70.0
	shape.shape = circle
	wall.position = at
	wall.add_child(shape)
	add_child_autofree(wall)


func test_maokai_matches_the_table() -> void:
	var data := load("res://data/enemies/maokai.tres") as EnemyData
	assert_eq([data.id, data.kind, data.behavior, data.camp], [&"maokai", &"mini_boss", &"maokai", &"maokai"])
	assert_eq([data.max_hp, data.armor, data.mr, data.damage, data.damage_type], [12000.0, 60.0, 40.0, 90.0, DamageInfo.Type.PHYSICAL])
	assert_eq([data.attack_interval, data.move_speed, data.radius, data.projectile_speed], [1.6, 300.0, 54.0, 0.0])
	assert_eq([data.purple_first, data.purple_repeat, data.gold], [5, 1, 300])
	assert_not_null(data.art)
	assert_has(SaveGame.BOSS_IDS, "maokai")


func test_the_stage_builds_maokai_unscaled() -> void:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 5, 1))
	add_child_autofree(stage)
	await wait_process_frames(2)
	var boss := stage.spawn_enemy(&"maokai", Vector2(1000, 1000), 4)
	assert_is(boss, Maokai)
	assert_eq(boss.max_hp, 12000.0, "no scaling")


func test_twisted_advance_warns_leaps_and_roots_inside_the_circle() -> void:
	var boss := _maokai(Vector2.ZERO)
	_quiet(boss)
	lucian.global_position = Vector2(500, 0)
	await wait_physics_frames(1)
	var busy := boss.twisted_advance()
	assert_gt(busy, Maokai.ADVANCE_WARN + Maokai.ADVANCE_LEAP)
	var warnings := _effects(GroundWarning)
	assert_eq(warnings.size(), 1)
	var warning: GroundWarning = warnings[0]
	assert_eq([warning.shape, warning.reach], [GroundWarning.Shape.CIRCLE, 90.0])
	assert_almost_eq(warning.warn_time, 0.8, 0.0001)
	assert_almost_eq(warning.global_position, Vector2(500, 0), Vector2(1, 1), "on Lucian")
	assert_false(boss.is_leaping(), "it waits for the warning")
	await wait_seconds(0.9)
	assert_true(boss.is_leaping())
	assert_true(boss.untargetable, "untargetable in the air")
	assert_false(boss.is_in_group(&"enemies"), "nothing can hit it")
	await wait_seconds(0.5)
	assert_false(boss.is_leaping())
	assert_false(boss.untargetable)
	assert_almost_eq(boss.global_position, Vector2(500, 0), Vector2(1, 1), "lands on the circle")
	var hits := _hits(&"twisted_advance")
	assert_eq(hits.size(), 1)
	if hits.size() == 1:
		assert_eq([hits[0][0].amount, hits[0][0].type, hits[0][0].from_skill], [130.0, DamageInfo.Type.MAGIC, true])
	assert_true(lucian.has_cc(CrowdControl.Kind.ROOT))


func test_twisted_advance_misses_and_does_not_root_a_lucian_who_left() -> void:
	var boss := _maokai(Vector2.ZERO)
	_quiet(boss)
	lucian.global_position = Vector2(500, 0)
	await wait_physics_frames(1)
	boss.twisted_advance()
	await wait_seconds(0.7)
	lucian.global_position = Vector2(500, 300)
	await wait_seconds(0.9)
	assert_false(boss.is_leaping())
	assert_eq(_hits(&"twisted_advance").size(), 0)
	assert_false(lucian.has_cc(CrowdControl.Kind.ROOT))


func test_the_vine_wave_roots_on_a_hit() -> void:
	var boss := _maokai(Vector2.ZERO)
	_quiet(boss)
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(1)
	boss.nature_grasp()
	var warning: GroundWarning = _effects(GroundWarning)[0]
	assert_eq([warning.shape, warning.reach, warning.width], [GroundWarning.Shape.LINE, 900.0, 140.0])
	assert_almost_eq(warning.warn_time, 0.8, 0.0001)
	await wait_seconds(0.85)
	var waves := _effects(EnemyProjectile)
	assert_eq(waves.size(), 1)
	if waves.size() == 1:
		assert_eq([waves[0].speed, waves[0].front_width], [700.0, 140.0])
	await wait_seconds(0.8)
	var hits := _hits(&"nature_grasp")
	assert_eq(hits.size(), 1)
	if hits.size() == 1:
		assert_eq([hits[0][0].amount, hits[0][0].type, hits[0][0].from_skill], [110.0, DamageInfo.Type.MAGIC, true])
	assert_true(lucian.has_cc(CrowdControl.Kind.ROOT))


func test_a_tree_stops_the_vine_wave() -> void:
	var boss := _maokai(Vector2.ZERO)
	_quiet(boss)
	_wall(Vector2(300, 0))
	lucian.global_position = Vector2(600, 0)
	await wait_physics_frames(1)
	boss.nature_grasp()
	await wait_seconds(2.4)
	assert_eq(_hits(&"nature_grasp").size(), 0)
	assert_false(lucian.has_cc(CrowdControl.Kind.ROOT))


func test_banshees_veil_blocks_the_vine_root_too() -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"banshees_veil"))
	var boss := _maokai(Vector2.ZERO)
	_quiet(boss)
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(1)
	boss.nature_grasp()
	await wait_seconds(1.7)
	assert_eq(_hits(&"nature_grasp").size(), 0, "blocked")
	assert_false(lucian.has_cc(CrowdControl.Kind.ROOT))


func test_the_skills_wait_for_their_range_and_their_cooldowns() -> void:
	var boss := _maokai(Vector2.ZERO)
	boss._cooldowns[&"twisted_advance"] = 0.0
	boss._cooldowns[&"nature_grasp"] = 1000.0
	lucian.global_position = Vector2(800, 0)
	await wait_physics_frames(1)
	boss._think(0.1)
	assert_eq(_effects(GroundWarning).size(), 0, "out of range 700")
	lucian.global_position = Vector2(650, 0)
	boss._think(0.1)
	assert_eq(_effects(GroundWarning).size(), 1)
	assert_gt(boss._cooldowns[&"twisted_advance"], 9.8)
	assert_gt(boss.busy_left, 1.0)
	assert_eq(Maokai.ADVANCE_COOLDOWN, 10.0)
	assert_eq(Maokai.GRASP_COOLDOWN, 12.0)
	boss.busy_left = 0.0
	boss._cooldowns[&"nature_grasp"] = 0.0
	lucian.global_position = Vector2(850, 0)
	boss._think(0.1)
	assert_eq(_effects(GroundWarning).size(), 2, "the grasp reaches 900")
