extends GutTest
## Act 6's second mini boss, Hecarim (6-4): Devastating Charge (a fast chase,
## a hit and a knockback on contact, once per cast) and Onslaught of Shadows
## (a line warning, then a ride along it that fears whoever is in its band).
## Skills are driven directly.

var lucian: Lucian
var effects: Node2D
## [DamageInfo, amount] per hit Lucian took.
var received: Array[Array] = []


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_hecarim_save_slot_")
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


func _hecarim(at: Vector2) -> Hecarim:
	var boss := Hecarim.new()
	boss.setup(load("res://data/enemies/hecarim.tres") as EnemyData, 6, 4, lucian)
	boss.position = at
	boss.projectile_parent = effects
	boss.warning_parent = effects
	add_child_autofree(boss)
	boss._attack_left = 1000.0
	for id: StringName in boss._cooldowns:
		boss._cooldowns[id] = 1000.0
	return boss


func _effects(type: Variant) -> Array:
	return effects.get_children().filter(func(node: Node) -> bool: return is_instance_of(node, type) and not node.is_queued_for_deletion())


func _hits(source: StringName) -> Array:
	return received.filter(func(hit: Array) -> bool: return hit[0].source == source)


# --- data and wiring ------------------------------------------------------------


func test_hecarim_matches_the_table() -> void:
	var data := load("res://data/enemies/hecarim.tres") as EnemyData
	assert_not_null(data)
	if data == null:
		return
	assert_eq([data.id, data.kind, data.behavior, data.camp], [&"hecarim", &"mini_boss", &"hecarim", &"hecarim"])
	assert_eq([data.max_hp, data.armor, data.mr, data.damage, data.damage_type], [18000.0, 50.0, 40.0, 100.0, DamageInfo.Type.PHYSICAL])
	assert_eq([data.attack_interval, data.move_speed, data.radius, data.projectile_speed], [1.3, 360.0, 56.0, 0.0])
	assert_eq([data.purple_first, data.purple_repeat, data.gold], [5, 1, 300])
	assert_not_null(data.art)
	assert_has(SaveGame.BOSS_IDS, "hecarim")


func test_the_stage_builds_hecarim_unscaled() -> void:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 6, 4))
	add_child_autofree(stage)
	await wait_process_frames(2)
	var boss := stage.spawn_enemy(&"hecarim", Vector2(1000, 1000), 4)
	assert_is(boss, Hecarim)
	assert_eq(boss.max_hp, 18000.0, "no scaling")


func test_the_skill_table() -> void:
	var boss := _hecarim(Vector2.ZERO)
	var by_id := {}
	for skill in boss.skills:
		by_id[skill.id] = skill
	assert_eq(by_id.keys().size(), 2)
	assert_eq(by_id[&"devastating_charge"].cooldown, 13.0)
	assert_eq(by_id[&"onslaught_of_shadows"].cooldown, 18.0)


# --- Devastating Charge ----------------------------------------------------------


func test_the_charge_speeds_him_up_for_2_5_seconds() -> void:
	var boss := _hecarim(Vector2.ZERO)
	boss.move_speed = 360.0
	lucian.global_position = Vector2(5000, 0)
	boss.devastating_charge()
	assert_true(boss.is_charge_running())
	assert_almost_eq(boss.move_speed, 648.0, 0.01, "x1.8")
	await wait_seconds(2.4)
	assert_true(boss.is_charge_running())
	await wait_seconds(0.3)
	assert_false(boss.is_charge_running())
	assert_eq(boss.move_speed, 360.0, "back to normal")


func test_the_charge_chases_and_knocks_lucian_back_on_contact() -> void:
	var boss := _hecarim(Vector2.ZERO)
	boss.move_speed = 360.0
	lucian.global_position = Vector2(400, 0)
	boss.devastating_charge()
	await wait_seconds(0.3)
	assert_gt(boss.global_position.x, 100.0, "it chases")
	assert_eq(_hits(&"devastating_charge").size(), 0, "not yet in contact")
	await wait_seconds(0.9)
	var hits := _hits(&"devastating_charge")
	assert_eq(hits.size(), 1)
	if hits.size() == 1:
		assert_eq([hits[0][0].amount, hits[0][0].type, hits[0][0].from_skill], [170.0, DamageInfo.Type.PHYSICAL, true])
	assert_gt(lucian.global_position.x, 650.0, "knocked 300 straight away from him")
	assert_gt(lucian.global_position.x - boss.global_position.x, 50.0, "he is thrown ahead of Hecarim, not past him")


func test_the_charge_hits_once_per_cast() -> void:
	var boss := _hecarim(Vector2.ZERO)
	boss.move_speed = 360.0
	lucian.global_position = Vector2(300, 0)
	boss.devastating_charge()
	await wait_seconds(2.4)
	assert_eq(_hits(&"devastating_charge").size(), 1, "he caught up again, but the cast is spent")
	await wait_seconds(0.3)
	boss.devastating_charge()
	lucian.global_position = boss.global_position + Vector2(200, 0)
	await wait_seconds(0.8)
	assert_eq(_hits(&"devastating_charge").size(), 2, "a new cast hits again")


func test_the_charge_waits_for_a_gap() -> void:
	var boss := _hecarim(Vector2.ZERO)
	lucian.global_position = Vector2(Hecarim.CHARGE_MIN - 50.0, 0)
	assert_false(boss._can_use(&"devastating_charge"), "too close to charge")
	lucian.global_position = Vector2(Hecarim.CHARGE_MIN + 50.0, 0)
	assert_true(boss._can_use(&"devastating_charge"))


# --- Onslaught of Shadows ---------------------------------------------------------


func test_onslaught_waits_for_80_percent_hp() -> void:
	var boss := _hecarim(Vector2.ZERO)
	boss.hp = boss.max_hp * 0.85
	assert_false(boss._can_use(&"onslaught_of_shadows"))
	boss.hp = boss.max_hp * 0.8
	assert_true(boss._can_use(&"onslaught_of_shadows"))
	boss._rush_left = 1.0
	assert_false(boss._can_use(&"onslaught_of_shadows"), "not in the middle of a charge")


func test_onslaught_is_chosen_by_his_thinking_only_below_80() -> void:
	var boss := _hecarim(Vector2.ZERO)
	boss._cooldowns[&"onslaught_of_shadows"] = 0.0
	lucian.global_position = Vector2(500, 0)
	boss._think(0.016)
	assert_eq(_effects(GroundWarning).size(), 0, "full health: no Onslaught")
	boss.hp = boss.max_hp * 0.7
	boss._think(0.016)
	assert_eq(_effects(GroundWarning).size(), 1)


func test_onslaught_warns_a_line_for_a_second_before_he_moves() -> void:
	var boss := _hecarim(Vector2.ZERO)
	lucian.global_position = Vector2(600, 0)
	var busy := boss.onslaught_of_shadows()
	boss.busy_left = busy
	assert_gt(busy, 1.0)
	var warning: GroundWarning = _effects(GroundWarning)[0]
	assert_eq([warning.shape, warning.reach, warning.width], [GroundWarning.Shape.LINE, 1100.0, 300.0])
	assert_almost_eq(warning.warn_time, 1.0, 0.0001)
	await wait_seconds(0.9)
	assert_almost_eq(boss.global_position.x, 0.0, 0.5, "he waits")
	assert_false(boss.is_riding())
	await wait_seconds(0.2)
	assert_true(boss.is_riding(), "then he rides")
	assert_gt(boss.global_position.x, 0.0)


func test_onslaught_hits_and_fears_for_a_second() -> void:
	var boss := _hecarim(Vector2.ZERO)
	lucian.global_position = Vector2(600, 0)
	boss.busy_left = boss.onslaught_of_shadows()
	await wait_seconds(1.9)
	var hits := _hits(&"onslaught_of_shadows")
	assert_eq(hits.size(), 1)
	if hits.size() == 1:
		assert_eq([hits[0][0].amount, hits[0][0].type, hits[0][0].from_skill], [150.0, DamageInfo.Type.MAGIC, true])
	assert_true(lucian.has_cc(CrowdControl.Kind.FEAR))
	assert_almost_eq(lucian._cc.duration(CrowdControl.Kind.FEAR), 1.0, 0.001)
	await wait_seconds(1.0)
	assert_false(lucian.has_cc(CrowdControl.Kind.FEAR), "a second, no more")
	assert_eq(_hits(&"onslaught_of_shadows").size(), 1, "once per ride")


func test_the_band_decides_not_his_body() -> void:
	# 140 off the line: well outside his 56 body, still inside the 300 band.
	var boss := _hecarim(Vector2.ZERO)
	lucian.global_position = Vector2(600, 0)
	boss.busy_left = boss.onslaught_of_shadows()
	lucian.global_position = Vector2(600, 140)
	await wait_seconds(1.9)
	assert_eq(_hits(&"onslaught_of_shadows").size(), 1)
	assert_true(lucian.has_cc(CrowdControl.Kind.FEAR))


func test_a_step_out_of_the_band_dodges_it() -> void:
	var boss := _hecarim(Vector2.ZERO)
	lucian.global_position = Vector2(600, 0)
	boss.busy_left = boss.onslaught_of_shadows()
	await wait_seconds(0.5)
	lucian.global_position = Vector2(600, 250)
	await wait_seconds(1.8)
	assert_eq(_hits(&"onslaught_of_shadows").size(), 0)
	assert_false(lucian.has_cc(CrowdControl.Kind.FEAR))
	assert_gt(boss.global_position.x, 900.0, "he rode the whole line")


func test_the_ride_stops_at_a_wall() -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = Layers.WORLD
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 600)
	shape.shape = rect
	wall.position = Vector2(500, 0)
	wall.add_child(shape)
	add_child_autofree(wall)
	var boss := _hecarim(Vector2.ZERO)
	lucian.global_position = Vector2(800, 0)
	await wait_physics_frames(1)
	boss.busy_left = boss.onslaught_of_shadows()
	await wait_seconds(2.0)
	assert_lt(boss.global_position.x, 500.0)
	assert_eq(_hits(&"onslaught_of_shadows").size(), 0, "he never passed Lucian")
	assert_false(boss.is_riding())
