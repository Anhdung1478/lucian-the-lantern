extends GutTest
## Act 5's boss, Karthus (5-5): Lay Waste, Wall of Pain and Requiem, plus the
## Act 5 wave plan. His skills are driven directly, as test_drakes does.

var lucian: Lucian
## Warnings, walls, shots and floating text go here, so they are freed with
## the test.
var effects: Node2D
## [DamageInfo, amount] per hit Lucian took.
var received: Array[Array] = []


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_karthus_save_slot_")
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


func _data(id := "karthus") -> EnemyData:
	return load("res://data/enemies/%s.tres" % id) as EnemyData


func _karthus(at: Vector2) -> Karthus:
	var boss := Karthus.new()
	boss.setup(_data(), 5, 5, lucian)
	boss.position = at
	boss.projectile_parent = effects
	boss.warning_parent = effects
	add_child_autofree(boss)
	_quiet(boss)
	return boss


## No basic attacks, no skills of its own and no walking: the test drives it.
func _quiet(boss: Boss) -> void:
	boss._attack_left = 1000.0
	for id: StringName in boss._cooldowns:
		boss._cooldowns[id] = 1000.0
	boss.move_speed = 0.0


func _effects(type: Variant) -> Array:
	return effects.get_children().filter(func(node: Node) -> bool: return is_instance_of(node, type) and not node.is_queued_for_deletion())


func _hits(source: StringName) -> Array:
	return received.filter(func(hit: Array) -> bool: return hit[0].source == source)


func _texts(parent: Node) -> Array:
	return parent.get_children().filter(func(node: Node) -> bool: return node is FloatingText).map(func(note: FloatingText) -> String: return note.text)


func _true_hit(amount: float) -> DamageInfo:
	return DamageInfo.create(amount, DamageInfo.Type.TRUE, &"test")


# --- data, waves and wiring ---------------------------------------------------


func test_his_data_file_matches_the_plan() -> void:
	var data := _data()
	assert_not_null(data)
	if data == null:
		return
	var fields := ["id", "kind", "behavior", "max_hp", "armor", "mr", "damage", "damage_type", "projectile_speed",
		"attack_range", "attack_interval", "move_speed", "radius", "purple_first", "purple_repeat", "gold"]
	var table := [&"karthus", &"boss", &"karthus", 20000.0, 30.0, 60.0, 80.0, DamageInfo.Type.MAGIC, 900.0,
		600.0, 1.5, 280.0, 46.0, 10, 2, 300]
	for i in fields.size():
		assert_eq(data.get(fields[i]), table[i], fields[i])
	assert_eq(data.display_name, "Karthus")
	assert_not_null(data.art)
	assert_has(SaveGame.BOSS_IDS, "karthus")


func test_act_5s_stages_follow_the_plan() -> void:
	var counts := {"5-1": 5, "5-2": 5, "5-3": 6, "5-4": 6, "5-5": 6}
	for id: String in counts:
		assert_true(WavePlan.has_stage(id), id)
		assert_eq(WavePlan.waves(id).size(), counts[id], id)
	var first := WavePlan.waves("5-1")[0] as Array
	assert_eq(first.size(), 12)
	assert_eq(first.count(WavePlan.SPIDERLING), 8)
	assert_eq(first.count(WavePlan.SAPLING), 4)
	var last := WavePlan.waves("5-5")[5] as Array
	assert_eq([last.count(WavePlan.SPIDERLING), last.count(WavePlan.SAPLING), last.count(WavePlan.MAIDEN), last.count(WavePlan.BROODMOTHER)], [14, 10, 1, 2])
	assert_eq(WavePlan.waves("5-2").back().back(), WavePlan.MAOKAI, "Maokai last in 5-2's last wave")
	assert_eq(WavePlan.waves("5-4").back().back(), WavePlan.ELISE, "Elise last in 5-4's last wave")
	assert_eq(WavePlan.boss("5-5"), &"karthus")
	for id in ["5-1", "5-2", "5-3", "5-4"]:
		assert_eq(WavePlan.boss(id), &"")
	assert_eq(StageSetup.for_stage(SaveGame.instance(), 5, 5).boss, &"karthus")


func test_every_act_5_id_has_a_data_file() -> void:
	for id: String in WavePlan.STAGES:
		for wave: Array in WavePlan.waves(id):
			for enemy: StringName in wave:
				assert_true(FileAccess.file_exists("res://data/enemies/%s.tres" % enemy), "%s %s" % [id, enemy])


func test_his_skills_start_on_their_first_delays_and_requiem_waits_on_hp() -> void:
	var boss := Karthus.new()
	boss.setup(_data(), 5, 5, lucian)
	boss.position = Vector2(3000, 0)
	boss.projectile_parent = effects
	boss.warning_parent = effects
	add_child_autofree(boss)
	assert_false(boss.revived)
	assert_eq(boss._cooldowns[&"lay_waste"], Karthus.LAY_FIRST)
	assert_eq(boss._cooldowns[&"wall_of_pain"], Karthus.WALL_FIRST)
	assert_eq(boss._cooldowns[&"requiem"], 0.0)
	assert_eq([Karthus.LAY_COOLDOWN, Karthus.WALL_COOLDOWN], [6.0, 14.0])


# --- Lay Waste ------------------------------------------------------------------


func test_lay_waste_picks_one_spot_on_lucian_and_four_within_300() -> void:
	var boss := _karthus(Vector2(3000, 0))
	var center := Vector2(120, -40)
	for run in 10:
		var spots := boss.lay_spots(center)
		assert_eq(spots.size(), 5)
		assert_eq(spots[0], center, "the first is on Lucian")
		for spot in spots:
			assert_lte(spot.distance_to(center), 300.0 + 0.01)


func test_lay_waste_puts_5_circles_0_15_seconds_apart() -> void:
	var boss := _karthus(Vector2(3000, 0))
	var laid: Array[Node] = []
	effects.child_entered_tree.connect(func(node: Node) -> void:
		if node is GroundWarning:
			laid.append(node))
	var busy := boss.lay_waste()
	assert_almost_eq(busy, 4 * 0.15 + 0.7 + Karthus.RECOVER, 0.001)
	var warnings := _effects(GroundWarning)
	assert_eq(warnings.size(), 1, "the first is down at once, on Lucian")
	assert_eq(warnings[0].global_position, lucian.global_position)
	assert_eq(warnings[0].reach, 110.0)
	assert_eq(warnings[0].warn_time, 0.7)
	# 0.15 s is 9 physics frames; none has fired yet inside the first 0.6 s.
	await wait_physics_frames(12)
	assert_eq(_effects(GroundWarning).size(), 2)
	await wait_physics_frames(18)
	assert_eq(_effects(GroundWarning).size(), 4)
	await wait_physics_frames(12)
	assert_eq(laid.size(), 5, "all five were laid by 0.6 s")


func test_lay_waste_hurts_only_inside_its_circles() -> void:
	var boss := _karthus(Vector2(3000, 0))
	boss.lay_waste()
	# Gone before any circle fires: every circle is within 300 + 110 of where he stood.
	lucian.global_position = Vector2(3000, 3000)
	await wait_physics_frames(120)
	assert_eq(_hits(&"lay_waste").size(), 0, "outside every circle")


func test_lay_waste_hits_110_magic_per_circle_he_stands_in() -> void:
	var boss := _karthus(Vector2(3000, 0))
	boss.lay_waste()
	await wait_physics_frames(130)
	var hits := _hits(&"lay_waste")
	assert_gte(hits.size(), 1, "at least the circle on him")
	assert_lte(hits.size(), 5)
	assert_eq(hits[0][0].amount, 110.0)
	assert_eq(hits[0][0].type, DamageInfo.Type.MAGIC)
	assert_true(hits[0][0].from_skill)


func test_lay_waste_is_used_on_its_own_within_900() -> void:
	var boss := _karthus(Vector2(800, 0))
	boss._cooldowns[&"lay_waste"] = 0.0
	await wait_physics_frames(2)
	assert_almost_eq(boss._cooldowns[&"lay_waste"], 6.0, 0.1)
	assert_gt(boss.busy_left, 0.0)
	assert_gte(_effects(GroundWarning).size(), 1)


# --- Wall of Pain -----------------------------------------------------------------


func test_wall_of_pain_warns_along_the_way_between_them_then_raises_a_wall() -> void:
	var boss := _karthus(Vector2(600, 0))
	var busy := boss.wall_of_pain()
	assert_almost_eq(busy, 0.6 + Karthus.RECOVER, 0.001)
	var warnings := _effects(GroundWarning)
	assert_eq(warnings.size(), 1)
	var line: GroundWarning = warnings[0]
	assert_eq(line.shape, GroundWarning.Shape.LINE)
	assert_eq(line.reach, 900.0)
	assert_eq(line.warn_time, 0.6)
	# Centered between them (300, 0), across the way.
	var middle := line.global_position + line.direction * 450.0
	assert_almost_eq(middle.x, 300.0, 0.01)
	assert_almost_eq(middle.y, 0.0, 0.01)
	assert_almost_eq(absf(line.direction.dot(Vector2.RIGHT)), 0.0, 0.001, "perpendicular to Karthus-Lucian")
	assert_eq(_effects(SpectralWall).size(), 0, "no wall under its warning")
	await wait_physics_frames(40)
	var walls := _effects(SpectralWall)
	assert_eq(walls.size(), 1)
	assert_eq(walls[0].lifetime, 5.0)
	assert_eq(walls[0].piece_count(), 1)
	var ends: PackedVector2Array = walls[0].piece_ends(0)
	assert_almost_eq(ends[0].distance_to(ends[1]), 900.0, 0.1)
	assert_almost_eq(((ends[0] + ends[1]) * 0.5).x, 300.0, 0.1)


func test_crossing_the_wall_slows_70_percent_once_per_cast_and_deals_no_damage() -> void:
	var boss := _karthus(Vector2(600, 0))
	lucian.global_position = Vector2(100, 0)
	boss.wall_of_pain()
	await wait_physics_frames(40)
	var wall := _effects(SpectralWall)[0] as SpectralWall
	var touches: Array[int] = []
	wall.touched.connect(func(piece: int) -> void: touches.append(piece))
	await wait_physics_frames(2)
	assert_eq(lucian.slow_amount(), 0.0, "not across yet")
	lucian.global_position = Vector2(500, 0)
	await wait_physics_frames(2)
	assert_eq(touches.size(), 1)
	assert_almost_eq(lucian.slow_amount(), 0.7, 0.001)
	lucian.global_position = Vector2(100, 0)
	await wait_physics_frames(2)
	assert_eq(touches.size(), 1, "once per cast")
	assert_eq(received.size(), 0, "a slow, no damage")


func test_a_wall_nobody_crosses_slows_nobody() -> void:
	var boss := _karthus(Vector2(600, 0))
	lucian.global_position = Vector2(100, 0)
	boss.wall_of_pain()
	await wait_physics_frames(60)
	assert_eq(lucian.slow_amount(), 0.0)


# --- Requiem -----------------------------------------------------------------------


func test_requiem_waits_for_75_then_45_then_15_percent() -> void:
	var boss := _karthus(Vector2(3000, 0))
	boss.hp = boss.max_hp * 0.76
	assert_false(boss._can_use(&"requiem"))
	boss.hp = boss.max_hp * 0.75
	assert_true(boss._can_use(&"requiem"))
	boss.requiem()
	boss.hp = boss.max_hp * 0.74
	assert_false(boss._can_use(&"requiem"), "not again until 45%")
	boss.hp = boss.max_hp * 0.46
	assert_false(boss._can_use(&"requiem"))
	boss.hp = boss.max_hp * 0.45
	assert_true(boss._can_use(&"requiem"))
	boss.requiem()
	boss.hp = boss.max_hp * 0.16
	assert_false(boss._can_use(&"requiem"))
	boss.hp = boss.max_hp * 0.15
	assert_true(boss._can_use(&"requiem"))
	boss.requiem()
	boss.hp = 1.0
	assert_false(boss._can_use(&"requiem"), "three times in all")


func test_a_burst_past_several_thresholds_brings_one_requiem_then_none_until_15_percent() -> void:
	var boss := _karthus(Vector2(3000, 0))
	boss._cooldowns[&"requiem"] = 0.0
	boss.hp = boss.max_hp * 0.4
	await wait_physics_frames(2)
	assert_true(boss.is_channeling(), "one Requiem")
	boss.take_damage(_true_hit(boss.max_hp * 0.09))
	await wait_physics_frames(2)
	assert_false(boss.is_channeling(), "broken")
	assert_false(boss._can_use(&"requiem"), "the 75% and 45% thresholds are spent")
	await wait_physics_frames(20)
	assert_false(boss.is_channeling(), "no second Requiem right behind")
	boss.hp = boss.max_hp * 0.16
	assert_false(boss._can_use(&"requiem"))
	boss.hp = boss.max_hp * 0.15
	assert_true(boss._can_use(&"requiem"), "the next is 15%")


func test_a_burst_that_breaks_the_channel_and_passes_a_threshold_spends_it() -> void:
	var boss := _karthus(Vector2(3000, 0))
	boss._cooldowns[&"requiem"] = 0.0
	boss.hp = boss.max_hp * 0.74
	await wait_physics_frames(2)
	assert_true(boss.is_channeling())
	boss.take_damage(_true_hit(boss.max_hp * 0.44))
	await wait_physics_frames(2)
	assert_false(boss.is_channeling(), "broken")
	await wait_physics_frames(25)
	assert_false(boss.is_channeling(), "no Requiem right behind the broken one")
	assert_false(boss._can_use(&"requiem"), "the 45% threshold is spent")
	boss.hp = boss.max_hp * 0.15
	assert_true(boss._can_use(&"requiem"), "the next is 15%")


func test_walking_down_the_thresholds_gives_three_requiems() -> void:
	var boss := _karthus(Vector2(3000, 0))
	var channels := 0
	for share in [0.75, 0.45, 0.15]:
		await wait_physics_frames(25)
		boss._cooldowns[&"requiem"] = 0.0
		boss.hp = boss.max_hp * share
		await wait_physics_frames(2)
		if boss.is_channeling():
			channels += 1
		boss.take_damage(_true_hit(boss.max_hp * 0.01))
		boss.hp = boss.max_hp * share
		boss._channel_damage = boss.max_hp * 0.08
		await wait_physics_frames(2)
		assert_false(boss.is_channeling())
	assert_eq(channels, 3)
	boss._cooldowns[&"requiem"] = 0.0
	boss.hp = 100.0
	await wait_physics_frames(2)
	assert_false(boss.is_channeling(), "no fourth")


func test_he_channels_requiem_on_his_own_at_75_percent_and_stands_for_3_seconds() -> void:
	var boss := _karthus(Vector2(3000, 0))
	boss._cooldowns[&"requiem"] = 0.0
	await wait_physics_frames(2)
	assert_false(boss.is_channeling(), "not at full HP")
	boss.hp = boss.max_hp * 0.74
	await wait_physics_frames(2)
	assert_true(boss.is_channeling())
	assert_almost_eq(boss.busy_left, 3.0, 0.1)


func test_8_percent_damage_in_the_channel_breaks_it_and_nothing_hits_lucian() -> void:
	var boss := _karthus(Vector2(3000, 0))
	boss.hp = boss.max_hp * 0.7
	await wait_physics_frames(1)
	boss.requiem()
	boss.take_damage(_true_hit(boss.max_hp * 0.05))
	await wait_physics_frames(2)
	assert_true(boss.is_channeling(), "5% is not enough")
	boss.take_damage(_true_hit(boss.max_hp * 0.031))
	assert_true(boss.is_channeling(), "recorded in _lose_hp: nothing happens inside the damage path")
	await wait_physics_frames(1)
	assert_false(boss.is_channeling(), "broken")
	assert_has(_texts(effects), "Broken!")
	await wait_physics_frames(200)
	assert_eq(_hits(&"requiem").size(), 0)


func test_an_unbroken_channel_does_900_magic_from_skill_after_3_seconds() -> void:
	var boss := _karthus(Vector2(3000, 0))
	boss.hp = boss.max_hp * 0.7
	await wait_physics_frames(1)
	boss.requiem()
	await wait_physics_frames(150)
	assert_eq(_hits(&"requiem").size(), 0, "not yet: 2.5 s in")
	await wait_physics_frames(40)
	var hits := _hits(&"requiem")
	assert_eq(hits.size(), 1)
	assert_eq(hits[0][0].amount, 900.0)
	assert_eq(hits[0][0].type, DamageInfo.Type.MAGIC)
	assert_true(hits[0][0].from_skill, "Banshee's Veil blocks it")
	assert_false(boss.is_channeling())
	assert_does_not_have(_texts(effects), "Broken!")


func test_damage_before_the_channel_does_not_count() -> void:
	var boss := _karthus(Vector2(3000, 0))
	boss.hp = boss.max_hp * 0.7
	boss.take_damage(_true_hit(boss.max_hp * 0.2))
	await wait_physics_frames(1)
	boss.requiem()
	await wait_physics_frames(2)
	assert_true(boss.is_channeling())


func test_channel_reports_the_damage_so_far_and_what_breaks_it() -> void:
	var boss := _karthus(Vector2(3000, 0))
	assert_eq(boss.channel(), {})
	boss.hp = boss.max_hp * 0.7
	boss.requiem()
	var info := boss.channel()
	assert_eq(info.need, 20000.0 * 0.08)
	assert_eq(info.done, 0.0)
	boss.take_damage(_true_hit(500.0))
	assert_eq(boss.channel().done, 500.0)
	await wait_physics_frames(200)
	assert_eq(boss.channel(), {}, "over")


# --- the boss bar ----------------------------------------------------------------


func test_the_boss_bar_shows_the_break_bar_while_he_channels() -> void:
	var bar := BossBar.new()
	add_child_autofree(bar)
	var boss := _karthus(Vector2(3000, 0))
	boss.hp = boss.max_hp * 0.7
	await wait_physics_frames(1)
	bar._process(0.0)
	assert_eq(bar.boss, boss)
	assert_eq(bar.channel, {}, "no break bar before it")
	boss.requiem()
	boss.take_damage(_true_hit(800.0))
	bar._process(0.0)
	assert_eq(bar.channel.done, 800.0)
	assert_eq(bar.channel.need, 1600.0)
	assert_gte(bar.custom_minimum_size.y, BossBar.SIZE.y + 30.0 + BossBar.BREAK_HEIGHT)


func test_the_boss_bar_shows_the_break_bar_for_the_ocean_drakes_mist_too() -> void:
	var bar := BossBar.new()
	add_child_autofree(bar)
	var drake := OceanDrake.new()
	drake.setup(_data("ocean_drake"), 3, 4, lucian)
	drake.position = Vector2(3000, 0)
	drake.projectile_parent = effects
	drake.warning_parent = effects
	add_child_autofree(drake)
	_quiet(drake)
	drake.hp = drake.max_hp * 0.5
	await wait_physics_frames(1)
	assert_eq(drake.channel(), {})
	bar._process(0.0)
	assert_eq(bar.channel, {})
	drake.soothing_mist()
	drake.take_damage(_true_hit(300.0))
	bar._process(0.0)
	assert_eq(bar.channel.done, 300.0)
	assert_eq(bar.channel.need, drake.max_hp * 0.08)


# --- in a stage -------------------------------------------------------------------


func _stage() -> Stage:
	SaveGame.instance().reset()
	return await _stage_keep_save()


func _stage_keep_save() -> Stage:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 5, 5))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


func _shoot(stage: Stage, enemy: Enemy, amount: float) -> void:
	var shot := LinearProjectile.new()
	shot.launch(enemy.global_position, Vector2.RIGHT, 0.0, 100.0, 30.0)
	shot.hit_enemy.connect(func(hit: Enemy, _prior: int) -> void: hit.take_damage(_true_hit(amount)))
	stage.get_node("Projectiles").add_child(shot)


func _kill_karthus(stage: Stage) -> Karthus:
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	var boss := stage.boss_unit as Karthus
	assert_not_null(boss, "a Karthus")
	if boss == null:
		return null
	assert_eq(boss.global_position, stage.arena.boss_point)
	assert_eq(boss.max_hp, 20000.0, "no scaling")
	assert_eq(boss.arena, stage.arena)
	_quiet(boss)
	await wait_physics_frames(1)
	_shoot(stage, boss, 99999.0)
	await wait_physics_frames(3)
	return boss


func test_5_5_clears_and_pays_10_purple_then_2() -> void:
	var stage: Stage = await _stage()
	assert_eq(stage.run.boss, &"karthus")
	var boss := await _kill_karthus(stage)
	assert_true(boss.dead)
	assert_true(stage.result.visible, "the stage is cleared")
	assert_has(stage.reward_lines, "+10 purple essence (first clear)")
	assert_eq(stage.collected[Essences.PURPLE], 10)
	get_tree().paused = false
	var again: Stage = await _stage_keep_save()
	await _kill_karthus(again)
	assert_has(again.reward_lines, "+2 purple essence (repeat)")
	assert_eq(again.collected[Essences.PURPLE], 2)
	assert_engine_error_count(0)


# --- the revived Karthus (Act 6, 6-2) ------------------------------------------


func _revived(at: Vector2) -> Karthus:
	var boss := Karthus.new()
	boss.revived = true
	boss.setup(_data("karthus_revived"), 6, 2, lucian)
	boss.position = at
	boss.projectile_parent = effects
	boss.warning_parent = effects
	add_child_autofree(boss)
	_quiet(boss)
	return boss


func _zones() -> Array:
	return _effects(HazardZone)


func test_the_revived_data_file_matches_the_plan() -> void:
	var data := _data("karthus_revived")
	assert_not_null(data)
	if data == null:
		return
	assert_eq([data.id, data.kind, data.behavior, data.camp], [&"karthus_revived", &"mini_boss", &"karthus_revived", &"karthus_revived"])
	assert_eq([data.max_hp, data.armor, data.mr, data.damage, data.damage_type], [16000.0, 30.0, 60.0, 85.0, DamageInfo.Type.MAGIC])
	assert_eq([data.attack_range, data.attack_interval, data.move_speed, data.projectile_speed], [600.0, 1.5, 250.0, 900.0])
	assert_eq([data.purple_first, data.purple_repeat, data.gold], [5, 1, 300])
	assert_ne(data.tint, Color.WHITE, "a pale teal tint")
	assert_eq(data.art.resource_path, "res://assets/art/enemies/karthus.svg")
	assert_has(SaveGame.BOSS_IDS, "karthus_revived")


func test_the_stage_builds_a_revived_karthus_unscaled() -> void:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 6, 2))
	add_child_autofree(stage)
	await wait_process_frames(2)
	var boss := stage.spawn_enemy(&"karthus_revived", Vector2(1000, 1000), 4)
	assert_is(boss, Karthus)
	assert_true((boss as Karthus).revived)
	assert_eq(boss.max_hp, 16000.0, "no scaling")
	assert_false((stage.spawn_enemy(&"karthus", Vector2(1200, 1000), 4) as Karthus).revived)


func test_the_revived_mode_has_lay_waste_only() -> void:
	var boss := _revived(Vector2.ZERO)
	var ids := boss.skills.map(func(skill: Dictionary) -> StringName: return skill.id)
	assert_eq(ids, [&"lay_waste"], "no Wall of Pain, no Requiem")
	boss.hp = boss.max_hp * 0.1
	assert_false(boss.is_channeling())
	var full := _karthus(Vector2(3000, 0))
	assert_eq(full.skills.size(), 3, "the Act 5 Karthus keeps all three")


func test_the_revived_lay_waste_is_four_circles_of_120() -> void:
	var boss := _revived(Vector2(500, 0))
	lucian.global_position = Vector2.ZERO
	assert_eq(boss.lay_spots(Vector2.ZERO).size(), 4)
	boss.lay_waste()
	await wait_seconds(0.5)
	assert_eq(_effects(GroundWarning).size(), 4, "all four are laid")
	await wait_seconds(0.9)
	var hits := _hits(&"lay_waste")
	assert_gt(hits.size(), 0, "the first circle is on Lucian")
	for hit: Array in hits:
		assert_eq([hit[0].amount, hit[0].type, hit[0].from_skill], [120.0, DamageInfo.Type.MAGIC, true])


func test_the_act_5_lay_waste_is_unchanged() -> void:
	var boss := _karthus(Vector2(500, 0))
	assert_eq(boss.lay_spots(Vector2.ZERO).size(), 5)
	boss.lay_waste()
	await wait_seconds(1.5)
	for hit: Array in _hits(&"lay_waste"):
		assert_eq(hit[0].amount, 110.0)


func test_defile_is_a_purple_ring_aura_burning_inside_350() -> void:
	var boss := _revived(Vector2.ZERO)
	await wait_physics_frames(2)
	assert_eq(_zones().size(), 1)
	var zone: HazardZone = _zones()[0]
	assert_eq([zone.radius, zone.dps, zone.damage_type, zone.effect], [350.0, 80.0, DamageInfo.Type.MAGIC, HazardZone.Effect.BURN])
	assert_ne(zone.id, HazardZone.BURN_ID, "its own id, apart from lava")
	assert_false(zone.visible, "the ring is drawn by Karthus, not the lava look")
	assert_gt(boss.defile_ring_radius(), 0.0)
	assert_eq(boss.defile_ring_radius(), 350.0)


func test_defile_hurts_only_inside_350_every_half_second() -> void:
	var boss := _revived(Vector2.ZERO)
	lucian.global_position = Vector2(340, 0)
	await wait_seconds(1.3)
	var burns := received.filter(func(hit: Array) -> bool: return hit[0].amount == 40.0 and hit[0].type == DamageInfo.Type.MAGIC)
	assert_between(burns.size(), 2, 3, "40 a tick, a tick every 0.5 s")
	received.clear()
	lucian.global_position = Vector2(380, 0)
	await wait_seconds(1.3)
	var more := received.filter(func(hit: Array) -> bool: return hit[0].amount == 40.0)
	assert_lte(more.size(), 1, "only the burn's last tick after he steps out")
	assert_not_null(boss)


func test_defile_moves_with_him_and_goes_when_he_dies() -> void:
	var boss := _revived(Vector2.ZERO)
	await wait_physics_frames(2)
	var zone: HazardZone = _zones()[0]
	boss.global_position = Vector2(1000, 500)
	await wait_physics_frames(2)
	assert_almost_eq(zone.position, Vector2(1000, 500), Vector2(0.5, 0.5), "kept on him each frame")
	lucian.global_position = Vector2(1200, 500)
	await wait_seconds(0.7)
	assert_gt(received.size(), 0, "burning where he stands")
	boss.take_damage(_true_hit(1.0e9))
	await wait_physics_frames(2)
	assert_eq(_zones().size(), 0, "gone with him")


func test_defile_goes_when_he_leaves_the_tree() -> void:
	var boss := _revived(Vector2.ZERO)
	await wait_physics_frames(2)
	assert_eq(_zones().size(), 1)
	boss.free()
	await wait_physics_frames(2)
	assert_eq(_zones().size(), 0)


func test_the_revived_karthus_walks_in_past_his_bolt_range() -> void:
	var boss := _revived(Vector2(900, 0))
	boss.move_speed = 250.0
	lucian.global_position = Vector2.ZERO
	await wait_seconds(1.0)
	assert_lt(boss.global_position.x, 700.0, "past 600 and still walking")
	await wait_seconds(2.5)
	assert_almost_eq(boss.global_position.distance_to(lucian.global_position), Karthus.REVIVED_STOP, 30.0)
	assert_lt(Karthus.REVIVED_STOP, 350.0, "inside Defile")


func test_the_act_5_karthus_stops_at_his_bolt_range() -> void:
	var boss := _karthus(Vector2(900, 0))
	boss.move_speed = 280.0
	await wait_seconds(2.5)
	assert_gt(boss.global_position.distance_to(lucian.global_position), 580.0)


func test_the_revived_karthus_fires_while_he_walks() -> void:
	var boss := _revived(Vector2(500, 0))
	boss.move_speed = 250.0
	boss._attack_left = 0.0
	await wait_physics_frames(3)
	assert_gt(_effects(EnemyProjectile).size(), 0, "a bolt from 500, still far from his stop")
	assert_gt(boss.distance_to_target(), Karthus.REVIVED_STOP)
