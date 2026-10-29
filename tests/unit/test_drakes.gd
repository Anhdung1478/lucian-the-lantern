extends GutTest
## Act 3's mini bosses: the Infernal Drake (3-2) and the Ocean Drake (3-4).
## Their skills are driven directly, as test_akshan does.

var lucian: Lucian
## Warnings, burning ground, shots and floating text go here, so they are
## freed with the test.
var effects: Node2D
## [DamageInfo, amount] per hit Lucian took.
var received: Array[Array] = []


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_drakes_save_slot_")
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


func _infernal(at: Vector2) -> InfernalDrake:
	var drake := InfernalDrake.new()
	drake.setup(_data("infernal_drake"), 3, 1, lucian)
	return _place(drake, at) as InfernalDrake


func _ocean(at: Vector2) -> OceanDrake:
	var drake := OceanDrake.new()
	drake.setup(_data("ocean_drake"), 3, 1, lucian)
	return _place(drake, at) as OceanDrake


func _place(drake: Boss, at: Vector2) -> Boss:
	drake.position = at
	drake.projectile_parent = effects
	drake.warning_parent = effects
	add_child_autofree(drake)
	_quiet(drake)
	return drake


## No basic attacks, no skills of its own and no walking: the test drives it.
func _quiet(drake: Boss) -> void:
	drake._attack_left = 1000.0
	for id: StringName in drake._cooldowns:
		drake._cooldowns[id] = 1000.0
	drake.move_speed = 0.0


## The live nodes of `type` among the effects.
func _effects(type: Variant) -> Array:
	return effects.get_children().filter(func(node: Node) -> bool: return is_instance_of(node, type) and not node.is_queued_for_deletion())


## Lucian's hits from `source`.
func _hits(source: StringName) -> Array:
	return received.filter(func(hit: Array) -> bool: return hit[0].source == source)


func _texts(parent: Node) -> Array:
	return parent.get_children().filter(func(node: Node) -> bool: return node is FloatingText).map(func(note: FloatingText) -> String: return note.text)


# --- data and waves ---------------------------------------------------------


func test_the_drakes_match_the_table() -> void:
	var fields := ["kind", "behavior", "camp", "max_hp", "armor", "mr", "damage", "damage_type", "projectile_speed",
		"attack_range", "attack_interval", "move_speed", "radius", "purple_first", "purple_repeat"]
	var table := {
		"infernal_drake": [&"mini_boss", &"infernal_drake", &"drake", 9000.0, 40.0, 40.0, 50.0, DamageInfo.Type.MAGIC, 700.0,
			600.0, 1.6, 260.0, 70.0, 5, 1],
		"ocean_drake": [&"mini_boss", &"ocean_drake", &"drake", 10000.0, 40.0, 50.0, 55.0, DamageInfo.Type.MAGIC, 800.0,
			600.0, 1.5, 260.0, 70.0, 5, 1],
	}
	for id: String in table:
		var data := _data(id)
		assert_not_null(data, id)
		if data == null:
			continue
		assert_eq(data.id, StringName(id))
		for i in fields.size():
			assert_eq(data.get(fields[i]), table[id][i], "%s %s" % [id, fields[i]])
		assert_not_null(data.art, "%s art" % id)
		if data.art:
			assert_eq(data.art.get_size(), Vector2(150, 150), "%s art size" % id)
	var infernal := _data("infernal_drake")
	assert_eq([infernal.hit_burn, infernal.hit_burn_time, infernal.burn_type()], [10.0, 2.0, DamageInfo.Type.MAGIC])
	assert_eq(_data("ocean_drake").hit_burn, 0.0)


func test_each_drake_comes_last_in_the_last_wave_of_its_stage_and_nowhere_else() -> void:
	var waves := WavePlan.waves("3-2")
	assert_eq(waves.size(), 4)
	assert_eq(waves[3].back(), &"infernal_drake")
	waves = WavePlan.waves("3-4")
	assert_eq(waves.size(), 5)
	assert_eq(waves[4].back(), &"ocean_drake")
	var seen := {}
	for stage_id: String in WavePlan.STAGES:
		for wave: Array in WavePlan.waves(stage_id):
			for id: StringName in wave:
				if id in [&"infernal_drake", &"ocean_drake"]:
					seen[id] = seen.get(id, 0) + 1
	assert_eq(seen.get(&"infernal_drake", 0), 1, "one Infernal Drake in all")
	assert_eq(seen.get(&"ocean_drake", 0), 1, "one Ocean Drake in all")


func _stage(act: int, stage_number: int) -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, stage_number))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


func test_the_stage_builds_each_drake_unscaled_in_the_pit() -> void:
	var stage: Stage = await _stage(3, 2)
	var pit: Vector2 = stage.arena.camps[&"drake"]
	assert_lt(stage._spawn_point(_data("infernal_drake")).distance_to(pit), 200.0, "it comes out of the pit")
	var infernal := stage.spawn_enemy(&"infernal_drake", pit, 4)
	assert_is(infernal, InfernalDrake)
	assert_eq(infernal.max_hp, 9000.0, "no scaling")
	assert_eq(infernal.damage, 50.0)
	assert_eq((infernal as Boss).arena, stage.arena, "it knows the map, for walkable ground")
	assert_eq(infernal.warning_parent, stage.get_node("Warnings"))
	var ocean := stage.spawn_enemy(&"ocean_drake", pit + Vector2(200, 0), 5)
	assert_is(ocean, OceanDrake)
	assert_eq(ocean.max_hp, 10000.0, "no scaling")
	assert_eq(ocean.health_bar.size, EnemyUnit.BOSS_BAR)


# --- Infernal Drake ---------------------------------------------------------


func test_the_fireball_burns_10_magic_a_second_for_2_seconds() -> void:
	var drake := _infernal(Vector2.ZERO)
	lucian.global_position = Vector2(300, 0)
	await wait_physics_frames(1)
	drake._attack()
	var bolts := _effects(EnemyProjectile)
	assert_eq(bolts.size(), 1)
	assert_eq(bolts[0].speed, 700.0)
	assert_eq(bolts[0].color, InfernalDrake.FIRE)
	var hit: bool = await wait_until(func() -> bool: return not received.is_empty(), 2.0)
	assert_true(hit)
	assert_eq(received[0][0].source, &"basic")
	assert_eq(received[0][0].type, DamageInfo.Type.MAGIC)
	assert_eq(received[0][0].amount, 50.0)
	assert_true(lucian._burns.has(&"infernal_drake"))
	assert_almost_eq(lucian._burns.time_left(&"infernal_drake"), 2.0, 0.05)
	await wait_seconds(0.6)
	var ticks := received.filter(func(info: Array) -> bool: return info[0].over_time)
	assert_gt(ticks.size(), 0)
	assert_eq(ticks[0][0].type, DamageInfo.Type.MAGIC, "a magic burn")


func test_fire_breath_hits_in_its_cone_and_leaves_it_burning_for_3_seconds() -> void:
	var drake := _infernal(Vector2.ZERO)
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(1)
	var busy := drake.fire_breath()
	assert_gt(busy, InfernalDrake.BREATH_WARN, "it stands while it breathes")
	var warnings := _effects(GroundWarning)
	assert_eq(warnings.size(), 1)
	var warning: GroundWarning = warnings[0]
	assert_eq(warning.shape, GroundWarning.Shape.CONE)
	assert_almost_eq(warning.spread, deg_to_rad(60.0), 0.0001)
	assert_eq(warning.reach, 550.0)
	assert_almost_eq(warning.warn_time, 0.8, 0.0001)
	assert_almost_eq(warning.direction, Vector2.RIGHT, Vector2(0.001, 0.001), "at Lucian")
	await wait_seconds(0.9)
	var breath := _hits(&"fire_breath")
	assert_eq(breath.size(), 1, "it hits")
	if breath.size() == 1:
		assert_eq(breath[0][0].amount, 100.0)
		assert_eq(breath[0][0].type, DamageInfo.Type.MAGIC)
		assert_true(breath[0][0].from_skill)
	var zones := _effects(HazardZone)
	assert_eq(zones.size(), 1, "the cone burns")
	if zones.is_empty():
		return
	var zone: HazardZone = zones[0]
	assert_eq([zone.effect, zone.dps, zone.damage_type, zone.lifetime], [HazardZone.Effect.BURN, 30.0, DamageInfo.Type.MAGIC, 3.0])
	assert_eq(zone.lucian, lucian)
	for point: Vector2 in [Vector2(60, 0), Vector2(400, 0), Vector2(520, 0), Vector2(450, 200)]:
		assert_true(zone.contains(point), "%s burns" % point)
	for point: Vector2 in [Vector2(-60, 0), Vector2(0, 300), Vector2(620, 0), Vector2(300, 250)]:
		assert_false(zone.contains(point), "%s is outside the cone" % point)
	assert_true(lucian._burns.has(HazardZone.BURN_ID), "he stands in it")
	await wait_seconds(1.9)
	assert_eq(_effects(HazardZone).size(), 1, "still burning")
	await wait_seconds(1.3)
	assert_eq(_effects(HazardZone).size(), 0, "gone after 3 s")


func test_fire_breath_misses_lucian_once_he_leaves_the_cone() -> void:
	var drake := _infernal(Vector2.ZERO)
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(1)
	drake.fire_breath()
	lucian.global_position = Vector2(0, 400)
	await wait_seconds(0.9)
	assert_eq(_hits(&"fire_breath").size(), 0)
	assert_eq(_effects(HazardZone).size(), 1, "the cone burns anyway")


func test_meteor_fall_marks_4_circles_one_on_lucian_each_burning_after() -> void:
	var drake := _infernal(Vector2(-500, 0))
	lucian.global_position = Vector2(200, 100)
	await wait_physics_frames(1)
	var busy := drake.meteor_fall()
	assert_gt(busy, InfernalDrake.METEOR_WARN)
	var warnings := _effects(GroundWarning)
	assert_eq(warnings.size(), 4)
	var spots: Array[Vector2] = []
	for warning: GroundWarning in warnings:
		spots.append(warning.position)
		assert_eq(warning.shape, GroundWarning.Shape.CIRCLE)
		assert_eq(warning.reach, 120.0)
		assert_almost_eq(warning.warn_time, 1.2, 0.0001)
		assert_lte(warning.position.distance_to(lucian.global_position), 280.0, "within 280 of him")
	assert_has(spots, lucian.global_position, "one on Lucian")
	await wait_seconds(1.3)
	var meteors := _hits(&"meteor_fall")
	assert_gte(meteors.size(), 1, "the one on him hits")
	for meteor: Array in meteors:
		assert_eq(meteor[0].amount, 80.0)
		assert_eq(meteor[0].type, DamageInfo.Type.MAGIC)
		assert_true(meteor[0].from_skill)
	var zones := _effects(HazardZone)
	assert_eq(zones.size(), 4, "each leaves a burn")
	for zone: HazardZone in zones:
		assert_has(spots, zone.position)
		assert_eq([zone.radius, zone.dps, zone.damage_type, zone.lifetime], [120.0, 25.0, DamageInfo.Type.MAGIC, 3.0])
		assert_eq(zone.lucian, lucian)
	assert_true(lucian._burns.has(HazardZone.BURN_ID), "he stands in one")


func test_the_meteors_fall_on_walkable_ground() -> void:
	var map := StageMap.new()
	map.size = Vector2(3000, 2000)
	# Jungle from x 1100 to the right edge: about half of the circle round him.
	map.wall_polygons.append(PackedVector2Array([Vector2(1100, 0), Vector2(3000, 0), Vector2(3000, 2000), Vector2(1100, 2000)]))
	autofree(map)
	var drake := _infernal(Vector2(500, 1000))
	drake.arena = map
	var center := Vector2(1000, 1000)
	var off_center := 0
	for attempt in 20:
		var spots := drake.meteor_spots(center)
		assert_eq(spots.size(), 4)
		assert_eq(spots[0], center, "one on Lucian")
		for spot in spots:
			assert_true(map.is_walkable(spot), "%s is walkable" % spot)
			assert_lte(spot.distance_to(center), 280.0)
			if spot != center:
				off_center += 1
	assert_gt(off_center, 40, "the others spread round him")


func test_the_drake_uses_its_skills_on_its_own() -> void:
	var drake := _infernal(Vector2.ZERO)
	lucian.global_position = Vector2(400, 0)
	drake._cooldowns[&"fire_breath"] = 0.0
	await wait_physics_frames(2)
	assert_gt(drake.busy_left, 0.0)
	assert_eq(_effects(GroundWarning).size(), 1, "Fire Breath, Lucian in reach")
	assert_almost_eq(drake._cooldowns[&"fire_breath"], 9.0, 0.1)


# --- Ocean Drake ------------------------------------------------------------


func test_the_water_shot_is_a_plain_magic_bolt() -> void:
	var drake := _ocean(Vector2.ZERO)
	lucian.global_position = Vector2(300, 0)
	await wait_physics_frames(1)
	drake._attack()
	var bolts := _effects(EnemyProjectile)
	assert_eq(bolts.size(), 1)
	assert_eq(bolts[0].speed, 800.0)
	assert_eq(bolts[0].color, OceanDrake.WATER)
	var hit: bool = await wait_until(func() -> bool: return not received.is_empty(), 2.0)
	assert_true(hit)
	assert_eq([received[0][0].amount, received[0][0].type], [55.0, DamageInfo.Type.MAGIC])
	assert_false(lucian._burns.has(&"ocean_drake"))


func test_tidal_wave_hits_pushes_300_along_the_line_and_slows() -> void:
	var drake := _ocean(Vector2.ZERO)
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(1)
	var busy := drake.tidal_wave()
	assert_gt(busy, OceanDrake.WAVE_WARN)
	var warnings := _effects(GroundWarning)
	assert_eq(warnings.size(), 1)
	var warning: GroundWarning = warnings[0]
	assert_eq(warning.shape, GroundWarning.Shape.LINE)
	assert_eq([warning.reach, warning.width], [1100.0, 180.0])
	assert_almost_eq(warning.warn_time, 0.8, 0.0001)
	assert_almost_eq(warning.direction, Vector2.RIGHT, Vector2(0.001, 0.001))
	var hit: bool = await wait_until(func() -> bool: return not _hits(&"tidal_wave").is_empty(), 2.0)
	assert_true(hit, "the wave reaches him")
	var wave: Array = _hits(&"tidal_wave")[0]
	assert_eq([wave[0].amount, wave[0].type, wave[0].from_skill], [90.0, DamageInfo.Type.MAGIC, true])
	assert_almost_eq(lucian.slow_amount(), 0.3, 0.001)
	assert_almost_eq(lucian._slows[OceanDrake.SLOW_ID].left, 2.0, 0.05)
	await wait_seconds(0.5)
	assert_almost_eq(lucian.global_position, Vector2(700, 0), Vector2(5, 5), "pushed 300 along the line")


func test_the_wave_is_wide() -> void:
	var drake := _ocean(Vector2.ZERO)
	lucian.global_position = Vector2(500, 0)
	await wait_physics_frames(1)
	drake.tidal_wave()
	# Off the line's middle, still inside its 180 width.
	lucian.global_position = Vector2(500, 100)
	var hit: bool = await wait_until(func() -> bool: return not _hits(&"tidal_wave").is_empty(), 2.0)
	assert_true(hit)


func test_soothing_mist_waits_for_70_percent_hp() -> void:
	var drake := _ocean(Vector2(3000, 0))
	assert_false(drake._can_use(&"soothing_mist"), "full HP")
	drake.hp = drake.max_hp * 0.71
	assert_false(drake._can_use(&"soothing_mist"))
	drake.hp = drake.max_hp * 0.7
	assert_true(drake._can_use(&"soothing_mist"))
	assert_true(drake._can_use(&"tidal_wave"), "the wave doesn't wait")


func test_the_drake_channels_soothing_mist_on_its_own_at_70_percent() -> void:
	var drake := _ocean(Vector2(3000, 0))
	drake._cooldowns[&"soothing_mist"] = 0.0
	await wait_physics_frames(2)
	assert_false(drake.is_channeling(), "not at full HP")
	drake.hp = drake.max_hp * 0.69
	await wait_physics_frames(2)
	assert_true(drake.is_channeling())
	assert_almost_eq(drake._cooldowns[&"soothing_mist"], 18.0, 0.1)


func test_soothing_mist_heals_30_percent_over_4_seconds_standing_still() -> void:
	var drake := _ocean(Vector2(800, 0))
	drake.move_speed = 260.0
	drake.hp = drake.max_hp * 0.5
	await wait_physics_frames(1)
	# Busy as Boss._think makes it.
	drake.busy_left = drake.soothing_mist()
	assert_eq(drake.busy_left, 4.0, "busy for the channel")
	assert_true(drake.is_channeling())
	var at := drake.global_position
	await wait_seconds(2.0)
	assert_almost_eq(drake.hp / drake.max_hp, 0.65, 0.02, "half the heal at 2 s")
	assert_almost_eq(drake.health_bar._ratio, drake.hp / drake.max_hp, 0.001, "the bar follows")
	assert_true(drake.is_channeling())
	assert_eq(drake.global_position, at, "it stands still")
	await wait_seconds(2.3)
	assert_false(drake.is_channeling())
	assert_almost_eq(drake.hp / drake.max_hp, 0.8, 0.001, "30% in all")


func test_8_percent_damage_in_the_channel_interrupts_it_and_dazes_it_for_1_5_seconds() -> void:
	var drake := _ocean(Vector2(3000, 0))
	drake.hp = drake.max_hp * 0.5
	await wait_physics_frames(1)
	drake.soothing_mist()
	drake.take_damage(DamageInfo.create(drake.max_hp * 0.05, DamageInfo.Type.TRUE, &"test"))
	await wait_physics_frames(2)
	assert_true(drake.is_channeling(), "5% is not enough")
	drake.take_damage(DamageInfo.create(drake.max_hp * 0.031, DamageInfo.Type.TRUE, &"test"))
	assert_true(drake.is_channeling(), "recorded in _lose_hp: nothing happens inside the damage path")
	await wait_physics_frames(1)
	assert_false(drake.is_channeling(), "interrupted")
	assert_true(drake.is_dazed())
	assert_almost_eq(drake.busy_left, 1.5, 0.05, "dazed: no skills, no attacks")
	assert_has(_texts(effects), "Interrupted!")
	var hp := drake.hp
	await wait_seconds(0.5)
	assert_eq(drake.hp, hp, "no more healing")
	await wait_seconds(1.1)
	assert_false(drake.is_dazed())
	assert_eq(drake.busy_left, 0.0)


func test_damage_before_the_channel_does_not_count() -> void:
	var drake := _ocean(Vector2(3000, 0))
	drake.hp = drake.max_hp * 0.6
	drake.take_damage(DamageInfo.create(drake.max_hp * 0.2, DamageInfo.Type.TRUE, &"test"))
	await wait_physics_frames(1)
	drake.soothing_mist()
	await wait_physics_frames(2)
	assert_true(drake.is_channeling())
	assert_false(drake.is_dazed())


## A shot that hits `enemy` for `amount` from inside area_entered, as an R
## bullet or a Rocketbelt bolt does.
func _shoot(stage: Stage, enemy: Enemy, amount: float) -> void:
	var shot := LinearProjectile.new()
	shot.launch(enemy.global_position, Vector2.RIGHT, 0.0, 100.0, 30.0)
	shot.hit_enemy.connect(func(hit: Enemy, _prior: int) -> void: hit.take_damage(DamageInfo.create(amount, DamageInfo.Type.TRUE, &"test")))
	stage.get_node("Projectiles").add_child(shot)


func test_shots_that_interrupt_and_kill_the_ocean_drake_cause_no_engine_errors() -> void:
	var stage: Stage = await _stage(3, 4)
	var drake := stage.spawn_enemy(&"ocean_drake", stage.arena.camps[&"drake"]) as OceanDrake
	assert_not_null(drake)
	_quiet(drake)
	drake.hp = drake.max_hp * 0.6
	await wait_physics_frames(1)
	drake.soothing_mist()
	_shoot(stage, drake, drake.max_hp * 0.09)
	await wait_physics_frames(3)
	assert_true(drake.is_dazed(), "the shot interrupts it")
	assert_has(_texts(stage.get_node("Warnings")), "Interrupted!")
	drake.busy_left = 0.0
	drake.soothing_mist()
	_shoot(stage, drake, 99999.0)
	await wait_physics_frames(3)
	assert_true(drake.dead, "killed mid-channel")
	assert_has(stage.reward_lines, "+5 purple essence (Ocean Drake, first kill)")
	assert_engine_error_count(0)


func test_a_shot_that_kills_the_infernal_drake_mid_skill_causes_no_engine_errors() -> void:
	var stage: Stage = await _stage(3, 2)
	var drake := stage.spawn_enemy(&"infernal_drake", stage.arena.camps[&"drake"]) as InfernalDrake
	assert_not_null(drake)
	_quiet(drake)
	stage.lucian.global_position = drake.global_position + Vector2(300, 0)
	await wait_physics_frames(1)
	drake.meteor_fall()
	drake.fire_breath()
	_shoot(stage, drake, 99999.0)
	await wait_physics_frames(3)
	assert_true(drake.dead)
	await wait_seconds(1.4)
	var zones := stage.get_node("Warnings").get_children().filter(func(node: Node) -> bool: return node is HazardZone)
	assert_eq(zones.size(), 0, "a dead drake's fire never lands")
	assert_engine_error_count(0)
