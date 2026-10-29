extends GutTest
## Act 6's final boss, Thresh (6-5). Phase 1: Death Sentence, Flay and The
## Box. At 0 HP he rises with full HP (Phase 2, darker): Death Sentence that
## comes again after a miss, Dark Passage and a harder Box. At 0 HP in Phase 2
## he falls (`fell`); he never dies. Skills are driven directly; a real 6-5
## Stage for the summons, the fall and the rewards. Also: the Act 6 wave plan,
## and Act 1's Thresh as he was.

var lucian: Lucian
## Warnings, walls, lanterns and shots go here, so they are freed with the test.
var effects: Node2D
## [DamageInfo, amount] per hit Lucian took.
var received: Array[Array] = []


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_thresh_final_save_slot_")
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


func _data() -> EnemyData:
	return load("res://data/enemies/thresh_final.tres") as EnemyData


func _thresh(at: Vector2) -> ThreshFinal:
	var boss := ThreshFinal.new()
	boss.setup(_data(), 6, 5, lucian)
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


## Floored in Phase 1, risen at once (the 2.5 s cut short), and quiet again:
## his Phase 2 table is new.
func _to_phase_2(boss: ThreshFinal) -> void:
	boss.take_damage(_lethal())
	await wait_physics_frames(2)
	assert_eq(boss.phase, 2, "risen")
	boss._rise_left = 0.0
	_quiet(boss)
	await wait_physics_frames(1)


func _lethal() -> DamageInfo:
	return DamageInfo.create(999999.0, DamageInfo.Type.TRUE, &"test")


func _hit(amount: float) -> DamageInfo:
	return DamageInfo.create(amount, DamageInfo.Type.TRUE, &"test")


func _effects(type: Variant) -> Array:
	return effects.get_children().filter(func(node: Node) -> bool: return is_instance_of(node, type) and not node.is_queued_for_deletion())


func _warnings(shape: GroundWarning.Shape) -> Array:
	return _effects(GroundWarning).filter(func(warning: GroundWarning) -> bool: return warning.shape == shape)


func _hits(source: StringName) -> Array:
	return received.filter(func(hit: Array) -> bool: return hit[0].source == source)


func _skill_ids(boss: Boss) -> Array:
	return boss.skills.map(func(skill: Dictionary) -> StringName: return skill.id)


func _skill(boss: Boss, id: StringName) -> Dictionary:
	for skill in boss.skills:
		if skill.id == id:
			return skill
	return {}


## Every node of `type` added under `effects` from now on, in order.
func _watch(type: Variant) -> Array:
	var seen := []
	effects.child_entered_tree.connect(func(node: Node) -> void:
		if is_instance_of(node, type):
			seen.append(node))
	return seen


# --- data and wiring --------------------------------------------------------


func test_his_data_file_matches_the_plan() -> void:
	var data := _data()
	assert_not_null(data)
	if data == null:
		return
	assert_eq([data.id, data.kind, data.behavior, data.display_name], [&"thresh_final", &"boss", &"thresh_final", "Thresh"])
	assert_eq([data.max_hp, data.armor, data.mr, data.damage, data.damage_type], [16000.0, 45.0, 45.0, 85.0, DamageInfo.Type.PHYSICAL])
	assert_eq([data.attack_range, data.attack_interval, data.move_speed, data.radius, data.projectile_speed], [450.0, 1.6, 320.0, 48.0, 900.0])
	assert_eq([data.purple_first, data.purple_repeat, data.gold], [20, 4, 300])
	assert_eq(data.summon_id, &"", "no periodic summons: Dark Passage brings his souls")
	assert_eq(data.art.resource_path, "res://assets/art/enemies/thresh.svg")
	assert_has(SaveGame.BOSS_IDS, "thresh_final")


func test_the_stage_builds_a_final_thresh_unscaled() -> void:
	var stage: Stage = await _stage()
	var boss := stage.spawn_enemy(&"thresh_final", Vector2(2800, 1500), 4)
	assert_is(boss, ThreshFinal)
	assert_eq(boss.max_hp, 16000.0, "no scaling")
	assert_eq((boss as ThreshFinal).stop_share, 0.0, "never stops at half")
	assert_false(stage.spawn_enemy(&"thresh_1", Vector2(2800, 1900)) is ThreshFinal, "Act 1's stays a plain Thresh")


## The plan's Act 6 table: w mist walker, l lantern soul, R spectral rider,
## C chain warden, groups in the order written; a mini boss is the last
## entry of its stage's last wave.
func test_act_6s_stages_follow_the_table() -> void:
	var letters := {"w": WavePlan.MIST_WALKER, "l": WavePlan.LANTERN_SOUL, "R": WavePlan.SPECTRAL_RIDER, "C": WavePlan.CHAIN_WARDEN}
	var table := {
		"6-1": "8w 4l · 8w 6l · 8w 6l 1R · 10w 6l 1C · 10w 8l 1R · 10w 8l 1R 1C",
		"6-2": "8w 6l · 10w 6l 1R · 10w 6l 1C · 10w 8l 1R · 12w 8l 1C · 12w 8l 1R 1C",
		"6-3": "10w 6l · 10w 8l 1R · 10w 8l 1C · 12w 8l 1R · 12w 8l 2C · 12w 10l 1R 1C · 14w 10l 2R 1C",
		"6-4": "10w 8l 1R · 10w 8l 1C · 12w 8l 1R 1C · 12w 10l 2R · 12w 10l 2C · 14w 10l 1R 1C · 14w 10l 2R 1C",
		"6-5": "10w 8l 1R · 12w 8l 1C · 12w 10l 1R 1C · 14w 10l 2R · 14w 10l 2C · 14w 12l 1R 1C · 16w 12l 2R 2C",
	}
	var mini_bosses := {"6-2": WavePlan.KARTHUS_REVIVED, "6-4": WavePlan.HECARIM}
	for id: String in table:
		var plan := []
		for written: String in (table[id] as String).split(" · "):
			var wave := []
			for group: String in written.split(" "):
				wave.append([letters[group.right(1)], group.left(-1).to_int()])
			plan.append(wave)
		if mini_bosses.has(id):
			plan.back().append([mini_bosses[id], 1])
		assert_true(WavePlan.has_stage(id), id)
		assert_eq(WavePlan.STAGES.get(id, []), plan, id)
		assert_eq(WavePlan.waves(id).size(), Journey.waves(6, id.right(1).to_int()), "%s: the Journey's wave count" % id)
		for wave: Array in WavePlan.waves(id):
			for enemy: StringName in wave:
				assert_true(ResourceLoader.exists(Stage.ENEMY_PATH % enemy), "%s %s" % [id, enemy])
	assert_eq(WavePlan.boss("6-5"), WavePlan.THRESH_FINAL)
	assert_eq(WavePlan.THRESH_FINAL, &"thresh_final")
	for id in ["6-1", "6-2", "6-3", "6-4"]:
		assert_eq(WavePlan.boss(id), &"", id)
	assert_eq(WavePlan.waves("6-2").back().back(), &"karthus_revived")
	assert_eq(WavePlan.waves("6-4").back().back(), &"hecarim")
	assert_eq(StageSetup.for_stage(SaveGame.instance(), 6, 5).boss, &"thresh_final")


# --- Phase 1: Q, E, R -----------------------------------------------------------


func test_phase_1_is_death_sentence_flay_and_the_box_with_the_final_numbers() -> void:
	var boss := _thresh(Vector2.ZERO)
	assert_eq(boss.phase, 1)
	assert_eq(boss.phase_label(), "Phase 1")
	assert_eq(_skill_ids(boss), [&"death_sentence", &"flay", &"the_box"])
	assert_eq([_skill(boss, &"death_sentence").cooldown, _skill(boss, &"flay").cooldown, _skill(boss, &"the_box").cooldown], [8.0, 7.0, 22.0])
	assert_eq(_skill(boss, &"the_box").range, 450.0, "used when Lucian is within 450")
	assert_eq([boss.hook_damage, boss.hook_warn, boss.flay_damage, boss.flay_push], [160.0, 0.8, 120.0, 300.0])
	assert_eq(boss.stop_share, 0.0)


func test_the_hook_warns_0_8_seconds_hits_for_160_magic_and_pulls() -> void:
	lucian.global_position = Vector2(700, 0)
	var boss := _thresh(Vector2.ZERO)
	await wait_physics_frames(1)
	boss.death_sentence()
	var lines := _warnings(GroundWarning.Shape.LINE)
	assert_eq(lines.size(), 1)
	assert_eq((lines[0] as GroundWarning).warn_time, 0.8)
	await wait_seconds(0.8 + 0.9)
	var hits := _hits(&"death_sentence")
	assert_eq(hits.size(), 1)
	if hits.size() == 1:
		assert_eq([hits[0][0].amount, hits[0][0].type, hits[0][0].from_skill], [160.0, DamageInfo.Type.MAGIC, true])
	assert_lt(lucian.global_position.distance_to(boss.global_position), 260.0, "pulled in")


func test_flay_hits_for_120_magic_and_pushes_300() -> void:
	lucian.global_position = Vector2(200, 0)
	var boss := _thresh(Vector2.ZERO)
	await wait_physics_frames(1)
	boss.flay()
	await wait_seconds(Thresh.FLAY_WARN + 0.4)
	var hits := _hits(&"flay")
	assert_eq(hits.size(), 1)
	if hits.size() == 1:
		assert_eq([hits[0][0].amount, hits[0][0].type, hits[0][0].from_skill], [120.0, DamageInfo.Type.MAGIC, true])
	assert_gt(lucian.global_position.distance_to(boss.global_position), 460.0, "pushed 300 away")


# --- The Box ------------------------------------------------------------------------


## The Box cast, its warning run out: the wall that rose (null if none did).
func _raised_box(boss: ThreshFinal) -> SpectralWall:
	boss.the_box()
	await wait_seconds(ThreshFinal.BOX_WARN + 0.1)
	var walls := _effects(SpectralWall)
	assert_eq(walls.size(), 1, "the walls rose")
	return walls[0] if walls.size() == 1 else null


## Lucian goes from inside the ring to outside it across the piece at
## `degrees` (pieces are 30 degrees each, piece 0 from 0 to 30).
func _cross(degrees: float) -> void:
	lucian.global_position = Vector2.from_angle(deg_to_rad(degrees)) * 300.0
	await wait_physics_frames(2)
	lucian.global_position = Vector2.from_angle(deg_to_rad(degrees)) * 600.0
	await wait_physics_frames(2)


func test_the_box_warns_a_ring_of_450_for_a_second_then_raises_12_pieces_for_4_seconds() -> void:
	lucian.global_position = Vector2(200, 0)
	var boss := _thresh(Vector2.ZERO)
	await wait_physics_frames(1)
	boss.the_box()
	var rings := _warnings(GroundWarning.Shape.RING)
	assert_eq(rings.size(), 1)
	if rings.size() == 1:
		var ring: GroundWarning = rings[0]
		assert_eq([ring.global_position, ring.reach, ring.warn_time], [boss.global_position, 450.0, 1.0])
	await wait_seconds(0.8)
	assert_eq(_effects(SpectralWall).size(), 0, "not before the warning ends")
	await wait_seconds(0.3)
	var walls := _effects(SpectralWall)
	assert_eq(walls.size(), 1)
	if walls.size() == 1:
		var wall: SpectralWall = walls[0]
		assert_eq([wall.global_position, wall.piece_count(), wall.lifetime, wall.break_on_touch, wall.target], [boss.global_position, 12, 4.0, true, lucian])
		assert_almost_eq(wall.piece_ends(0)[0].distance_to(boss.global_position), 450.0, 0.01)
	assert_eq(received.size(), 0, "standing inside it hurts nobody")


func test_the_box_is_used_only_when_lucian_is_within_450() -> void:
	lucian.global_position = Vector2(600, 0)
	var boss := _thresh(Vector2.ZERO)
	boss._cooldowns[&"the_box"] = 0.0
	await wait_physics_frames(5)
	assert_eq(_warnings(GroundWarning.Shape.RING).size(), 0, "600 away: no Box")
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(3)
	assert_eq(_warnings(GroundWarning.Shape.RING).size(), 1, "400 away: the Box")


func test_crossing_the_box_hurts_150_and_slows_80_percent_for_2_seconds_once_per_piece_and_breaks_it() -> void:
	lucian.global_position = Vector2(200, 0)
	var boss := _thresh(Vector2.ZERO)
	var wall := await _raised_box(boss)
	if wall == null:
		return
	await _cross(15.0)
	var hits := _hits(&"the_box")
	assert_eq(hits.size(), 1, "across piece 0")
	if hits.size() == 1:
		assert_eq([hits[0][0].amount, hits[0][0].type, hits[0][0].from_skill], [150.0, DamageInfo.Type.MAGIC, true])
	assert_eq(lucian.slow_amount(), 0.8)
	assert_eq(lucian._slows[ThreshFinal.BOX_SLOW_ID].duration, 2.0)
	assert_true(wall.is_broken(0), "the piece he crossed breaks")
	assert_false(wall.is_broken(1))
	# Past BOX_TOUCH_GAP (one crossing, one hit): back in across the broken piece, nothing.
	await wait_seconds(ThreshFinal.BOX_TOUCH_GAP)
	lucian.global_position = Vector2.from_angle(deg_to_rad(15.0)) * 300.0
	await wait_physics_frames(2)
	assert_eq(_hits(&"the_box").size(), 1, "once per piece")
	await _cross(105.0)
	assert_eq(_hits(&"the_box").size(), 2, "another piece hurts again")
	assert_true(wall.is_broken(3))


## The final review: one crossing, one hit. A crossing exactly at a joint
## comes within his hit radius of both pieces; it hits once, and both break.
func test_a_crossing_at_a_joint_hits_once_and_breaks_both_pieces() -> void:
	assert_eq(ThreshFinal.BOX_TOUCH_GAP, 0.3)
	lucian.global_position = Vector2(200, 0)
	var boss := _thresh(Vector2.ZERO)
	var wall := await _raised_box(boss)
	if wall == null:
		return
	# 30 degrees: the joint between pieces 0 and 1.
	await _cross(30.0)
	assert_eq(_hits(&"the_box").size(), 1, "one hit")
	assert_true(wall.is_broken(0), "both pieces break")
	assert_true(wall.is_broken(1), "both pieces break")
	assert_false(wall.is_broken(2))
	await wait_seconds(ThreshFinal.BOX_TOUCH_GAP)
	await _cross(195.0)
	assert_eq(_hits(&"the_box").size(), 2, "a new crossing hits again")


func test_standing_on_a_joint_as_the_box_rises_hits_once() -> void:
	lucian.global_position = Vector2.from_angle(deg_to_rad(60.0)) * ThreshFinal.BOX_RADIUS
	var boss := _thresh(Vector2.ZERO)
	var wall := await _raised_box(boss)
	if wall == null:
		return
	await wait_physics_frames(2)
	assert_eq(_hits(&"the_box").size(), 1)
	assert_true(wall.is_broken(1) and wall.is_broken(2), "the pieces on either side of the joint break")


func test_a_box_touch_banshees_veil_blocks_does_not_slow() -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"banshees_veil"))
	lucian.global_position = Vector2(200, 0)
	var boss := _thresh(Vector2.ZERO)
	var wall := await _raised_box(boss)
	if wall == null:
		return
	await _cross(15.0)
	assert_eq(_hits(&"the_box").size(), 0, "blocked")
	assert_eq(lucian.slow_amount(), 0.0, "no slow without the hit")
	assert_true(wall.is_broken(0), "the piece still breaks")


## Fix round 1: a touch on the frame he is floored (before the rise clears
## the Box) or after his fall hurts nobody.
func test_a_box_touch_once_he_is_down_hurts_nobody() -> void:
	lucian.global_position = Vector2(200, 0)
	var boss := _thresh(Vector2.ZERO)
	var wall := await _raised_box(boss)
	if wall == null:
		return
	boss.take_damage(_lethal())
	boss._box_touched(0)
	assert_eq(_hits(&"the_box").size(), 0, "floored")
	assert_eq(lucian.slow_amount(), 0.0)
	await wait_physics_frames(2)
	boss._rise_left = 0.0
	await wait_physics_frames(2)
	assert_false(boss.stopped, "up again")
	boss.take_damage(_lethal())
	await wait_physics_frames(2)
	boss._box_touched(1)
	assert_eq(_hits(&"the_box").size(), 0, "fallen")
	assert_eq(lucian.slow_amount(), 0.0)


func test_the_phase_2_box_hits_for_220_every_18_seconds() -> void:
	lucian.global_position = Vector2(200, 0)
	var boss := _thresh(Vector2.ZERO)
	await _to_phase_2(boss)
	assert_eq(_skill(boss, &"the_box").cooldown, 18.0)
	assert_eq(_skill(boss, &"the_box").range, 450.0)
	var wall := await _raised_box(boss)
	if wall == null:
		return
	await _cross(15.0)
	var hits := _hits(&"the_box")
	assert_eq(hits.size(), 1)
	if hits.size() == 1:
		assert_eq(hits[0][0].amount, 220.0)
	assert_eq(lucian.slow_amount(), 0.8)


# --- the rise: Phase 1 at 0 HP --------------------------------------------------------


func test_at_0_hp_in_phase_1_he_rises_with_full_hp_and_takes_no_damage_for_2_5_seconds() -> void:
	var boss := _thresh(Vector2(800, 0))
	watch_signals(boss)
	watch_signals(lucian)
	boss.take_damage(DamageInfo.create(999999.0, DamageInfo.Type.TRUE, &"test", lucian))
	assert_eq(boss.hp, 0.0)
	assert_true(boss.is_alive(), "he never dies")
	assert_true(boss.is_in_group(&"enemies"))
	assert_signal_not_emitted(boss, "died")
	assert_signal_not_emitted(lucian, "enemy_killed", "no kill for Lucian")
	await wait_physics_frames(2)
	assert_eq(boss.phase, 2)
	assert_eq(boss.hp, boss.max_hp, "full HP")
	assert_eq(boss.health_bar._ratio, 1.0, "the bar shows it")
	assert_eq(boss.phase_label(), "Phase 2")
	assert_true(boss.is_rising())
	assert_eq(boss.take_damage(_hit(1000.0)), 0.0, "no damage while he rises")
	assert_eq(boss.hp, boss.max_hp)
	await wait_seconds(ThreshFinal.RISE_TIME - 0.4)
	assert_true(boss.is_rising())
	boss.take_damage(_hit(1000.0))
	assert_eq(boss.hp, boss.max_hp, "still none")
	await wait_seconds(0.6)
	assert_false(boss.is_rising(), "up after 2.5 s")
	boss.take_damage(_hit(1000.0))
	assert_eq(boss.hp, boss.max_hp - 1000.0, "he takes damage again")
	assert_signal_not_emitted(boss, "fell")
	assert_signal_not_emitted(boss, "died")
	assert_signal_not_emitted(lucian, "enemy_killed")


func test_two_floors_on_one_frame_bring_one_rise() -> void:
	var boss := _thresh(Vector2(800, 0))
	watch_signals(boss)
	boss.take_damage(_lethal())
	boss.take_damage(_lethal())
	await wait_physics_frames(3)
	assert_eq(boss.phase, 2)
	assert_eq(boss.hp, boss.max_hp)
	assert_signal_not_emitted(boss, "fell")


func test_the_rise_clears_his_warnings_and_walls() -> void:
	lucian.global_position = Vector2(300, 0)
	var boss := _thresh(Vector2.ZERO)
	var wall := await _raised_box(boss)
	assert_not_null(wall)
	boss.death_sentence()
	boss.the_box()
	assert_eq(_effects(GroundWarning).size(), 2, "a hook's line and a Box's ring")
	boss.take_damage(_lethal())
	await wait_physics_frames(2)
	assert_eq(_effects(GroundWarning).size(), 0, "the warnings go")
	assert_eq(_effects(SpectralWall).size(), 0, "the Box goes")
	await wait_seconds(1.2)
	assert_eq(_effects(SpectralWall).size(), 0, "no Box rises")
	assert_eq(_effects(EnemyProjectile).size(), 0, "no hook is thrown")
	assert_eq(received.size(), 0)


func test_phase_2_is_darker_with_a_green_aura() -> void:
	var boss := _thresh(Vector2(800, 0))
	assert_eq(boss.sprite.modulate, Color.WHITE)
	assert_false(boss.has_aura())
	await _to_phase_2(boss)
	var shade := boss.sprite.modulate
	assert_lt(maxf(shade.r, maxf(shade.g, shade.b)), 0.8, "darker")
	assert_true(boss.has_aura())


func test_phase_2_swaps_e_for_w_and_its_skills_wait_for_the_rise() -> void:
	var boss := _thresh(Vector2(800, 0))
	assert_eq(_skill_ids(boss), [&"death_sentence", &"flay", &"the_box"])
	boss.take_damage(_lethal())
	await wait_physics_frames(2)
	assert_eq(_skill_ids(boss), [&"death_sentence", &"dark_passage", &"the_box"], "Q, W, R")
	assert_eq([_skill(boss, &"death_sentence").cooldown, _skill(boss, &"dark_passage").cooldown, _skill(boss, &"the_box").cooldown], [8.0, 16.0, 18.0])
	for id: StringName in boss._cooldowns:
		assert_gt(boss._cooldowns[id], ThreshFinal.RISE_TIME - 0.1, "%s waits for the rise" % id)


func test_the_boss_bar_reads_phase_1_then_phase_2() -> void:
	var bar := BossBar.new()
	add_child_autofree(bar)
	var boss := _thresh(Vector2(800, 0))
	bar._process(0.0)
	assert_eq(bar.boss, boss)
	assert_eq(bar.phase_text, "Phase 1")
	await _to_phase_2(boss)
	bar._process(0.0)
	assert_eq(bar.phase_text, "Phase 2")


func test_other_bosses_have_no_phase_text() -> void:
	var bar := BossBar.new()
	add_child_autofree(bar)
	var karthus := Karthus.new()
	karthus.setup(load("res://data/enemies/karthus.tres") as EnemyData, 5, 5, lucian)
	karthus.position = Vector2(800, 0)
	karthus.projectile_parent = effects
	karthus.warning_parent = effects
	add_child_autofree(karthus)
	_quiet(karthus)
	assert_eq(karthus.phase_label(), "")
	bar._process(0.0)
	assert_eq(bar.boss, karthus)
	assert_eq(bar.phase_text, "")


# --- Phase 2: Death Sentence again ----------------------------------------------------


func test_a_dodged_hook_in_phase_2_comes_again_at_once_with_a_0_45_second_warning_then_never_again() -> void:
	lucian.global_position = Vector2(700, 0)
	var boss := _thresh(Vector2.ZERO)
	await _to_phase_2(boss)
	var lines := _watch(GroundWarning)
	var hooks := _watch(EnemyProjectile)
	var missed_at: Array[int] = []
	var line_at: Array[int] = []
	effects.child_entered_tree.connect(func(node: Node) -> void:
		if node is EnemyProjectile:
			(node as EnemyProjectile).missed.connect(func() -> void: missed_at.append(Engine.get_physics_frames()))
		if node is GroundWarning:
			line_at.append(Engine.get_physics_frames()))
	boss.death_sentence()
	# Off the line before the chain flies.
	lucian.global_position = Vector2(700, 300)
	assert_true(await wait_until(func() -> bool: return lines.size() == 2, 3.0), "thrown again")
	var again: GroundWarning = lines[1]
	assert_eq(again.warn_time, ThreshFinal.REHOOK_WARN)
	assert_eq(ThreshFinal.REHOOK_WARN, 0.45)
	assert_almost_eq(again.direction, Vector2(700, 300).normalized(), Vector2(0.01, 0.01), "at where Lucian is now")
	assert_eq(missed_at.size(), 1)
	if missed_at.size() == 1 and line_at.size() == 2:
		assert_eq(line_at[1], missed_at[0], "at once: on the frame it missed")
	# Off this one too: it misses, and no third comes.
	lucian.global_position = Vector2(-700, 300)
	await wait_seconds(ThreshFinal.REHOOK_WARN + 1.0)
	assert_eq(hooks.size(), 2, "two chains thrown")
	assert_eq(missed_at.size(), 2, "both missed")
	await wait_seconds(0.6)
	assert_eq(lines.size(), 2, "once only")
	assert_eq(_hits(&"death_sentence").size(), 0)


## Fix round 1: a dodged Phase 2 hook keeps him busy until it comes again.
## Dark Passage and The Box, both ready and Lucian in reach, wait until the
## second line is down, then come.
func test_no_other_skill_starts_between_a_dodged_hook_and_its_second_throw() -> void:
	lucian.global_position = Vector2(300, 0)
	var boss := _thresh(Vector2.ZERO)
	await _to_phase_2(boss)
	# As in a stage, the chain flies under a node processed after him
	# ($Projectiles after $World): its miss comes after his thinking that frame.
	var shots := Node2D.new()
	add_child_autofree(shots)
	boss.projectile_parent = shots
	var warnings := _watch(GroundWarning)
	# As his thinking casts it: busy for what it returns.
	boss.busy_left = boss.death_sentence()
	boss._cooldowns[&"dark_passage"] = 0.0
	boss._cooldowns[&"the_box"] = 0.0
	# Off the line, still within 450 of him.
	lucian.global_position = Vector2(300, 200)
	assert_true(await wait_until(func() -> bool: return warnings.size() >= 2, 3.0))
	assert_eq((warnings[1] as GroundWarning).shape, GroundWarning.Shape.LINE, "the second throw comes first")
	assert_true(await wait_until(func() -> bool: return warnings.size() >= 3, 3.0), "then his next skill")
	assert_ne((warnings[2] as GroundWarning).shape, GroundWarning.Shape.LINE)


func test_a_hook_banshees_veil_blocks_is_no_miss() -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"banshees_veil"))
	lucian.global_position = Vector2(700, 0)
	var boss := _thresh(Vector2.ZERO)
	await _to_phase_2(boss)
	var lines := _watch(GroundWarning)
	boss.death_sentence()
	await wait_seconds(0.8 + 1.2)
	assert_eq(lines.size(), 1, "not thrown again")
	assert_gt(lucian.global_position.x, 650.0, "no pull")
	assert_eq(_hits(&"death_sentence").size(), 0)


func test_a_hook_that_lands_is_not_thrown_again() -> void:
	lucian.global_position = Vector2(700, 0)
	var boss := _thresh(Vector2.ZERO)
	await _to_phase_2(boss)
	var lines := _watch(GroundWarning)
	boss.death_sentence()
	await wait_seconds(0.8 + 1.2)
	assert_eq(lines.size(), 1)
	assert_eq(_hits(&"death_sentence").size(), 1)
	assert_lt(lucian.global_position.distance_to(boss.global_position), 260.0, "pulled in")


func test_a_hook_a_wall_stops_is_a_miss_and_comes_again() -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = Layers.WORLD
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 600)
	shape.shape = rect
	wall.add_child(shape)
	wall.position = Vector2(400, 0)
	add_child_autofree(wall)
	lucian.global_position = Vector2(700, 0)
	var boss := _thresh(Vector2.ZERO)
	await _to_phase_2(boss)
	var lines := _watch(GroundWarning)
	var hooks := _watch(EnemyProjectile)
	boss.death_sentence()
	await wait_seconds(0.8 + 0.6)
	assert_eq(hooks.size(), 1)
	assert_eq(lines.size(), 2, "the wall's stop brought it again")
	await wait_seconds(ThreshFinal.REHOOK_WARN + 0.8)
	assert_eq(hooks.size(), 2)
	assert_eq(lines.size(), 2, "once only")
	assert_eq(_hits(&"death_sentence").size(), 0)


func test_a_dodged_hook_in_phase_1_is_not_thrown_again() -> void:
	lucian.global_position = Vector2(700, 0)
	var boss := _thresh(Vector2.ZERO)
	await wait_physics_frames(1)
	var lines := _watch(GroundWarning)
	boss.death_sentence()
	lucian.global_position = Vector2(700, 300)
	await wait_seconds(0.8 + 1.4)
	assert_eq(lines.size(), 1)


# --- Phase 2: Dark Passage ------------------------------------------------------------


func test_dark_passage_marks_a_circle_of_100_within_250_of_lucian_for_0_6_seconds() -> void:
	lucian.global_position = Vector2(300, 0)
	var boss := _thresh(Vector2(-400, 0))
	await _to_phase_2(boss)
	for i in 30:
		assert_lte(boss.passage_spot(lucian.global_position).distance_to(lucian.global_position), 250.0)
	boss.dark_passage()
	var circles := _warnings(GroundWarning.Shape.CIRCLE)
	assert_eq(circles.size(), 1)
	if circles.size() == 1:
		var circle: GroundWarning = circles[0]
		assert_eq([circle.reach, circle.warn_time], [100.0, 0.6])
		assert_lte(circle.global_position.distance_to(lucian.global_position), 250.0)


func test_the_lantern_lands_on_ground_its_souls_can_stand_on() -> void:
	var map := StageMaps.create(6, 5)
	autofree(map)
	var boss := _thresh(Vector2.ZERO)
	boss.arena = map
	# By the platform's north-east rim (no stub there): the abyss is within 250.
	var by_the_rim := ThreshDomainMap.PLATFORM_CENTER + Vector2.from_angle(-PI / 4.0) * (ThreshDomainMap.PLATFORM_RADIUS - 60.0)
	assert_false(map.is_walkable(by_the_rim + Vector2.from_angle(-PI / 4.0) * 200.0), "the abyss is there")
	for i in 30:
		var spot := boss.passage_spot(by_the_rim)
		assert_lte(spot.distance_to(by_the_rim), 250.0)
		assert_true(map.is_walkable(spot, ThreshFinal.SOUL_GAP + Stage.SUMMON_MARGIN), "%s: room for its souls on the platform" % spot)


func test_the_lantern_lies_6_seconds_and_3_lantern_souls_come_out() -> void:
	lucian.global_position = Vector2(300, 0)
	var boss := _thresh(Vector2(-400, 0))
	await _to_phase_2(boss)
	var calls := []
	boss.summon_requested.connect(func(unit: EnemyUnit, id: StringName, at: Vector2) -> void: calls.append([unit, id, at]))
	boss.dark_passage()
	var spot: Vector2 = _warnings(GroundWarning.Shape.CIRCLE)[0].global_position
	await wait_seconds(0.5)
	assert_eq(calls.size(), 0, "not before it lands")
	await wait_seconds(0.2)
	assert_eq(calls.size(), 3, "3 souls")
	for call: Array in calls:
		assert_eq(call[0], boss)
		assert_eq(call[1], &"lantern_soul")
		assert_lte((call[2] as Vector2).distance_to(spot), 100.0, "out of the lantern")
	assert_eq(boss.summons, 3, "his own summons, counted")
	var lanterns := _effects(Sprite2D)
	assert_eq(lanterns.size(), 1, "the lantern lies there")
	if lanterns.size() == 1:
		assert_eq((lanterns[0] as Sprite2D).global_position, spot)
	await wait_seconds(5.3)
	assert_eq(_effects(Sprite2D).size(), 1, "still there")
	await wait_seconds(0.8)
	assert_eq(_effects(Sprite2D).size(), 0, "gone after 6 s")


## Fix round 1 (ruling): his summoned souls alive or on their way stay at
## or under 6. At 4, a Dark Passage brings 2; at 6, none (the lantern still
## lands); one gone, one more.
func test_dark_passage_stops_at_6_souls_alive_or_on_their_way() -> void:
	assert_eq(ThreshFinal.PASSAGE_CAP, 6)
	lucian.global_position = Vector2(300, 0)
	var boss := _thresh(Vector2(-400, 0))
	await _to_phase_2(boss)
	var calls := []
	boss.summon_requested.connect(func(_unit: EnemyUnit, _id: StringName, _at: Vector2) -> void: calls.append(true))
	boss.summons = 4
	boss.dark_passage()
	await wait_seconds(ThreshFinal.PASSAGE_WARN + 0.1)
	assert_eq(calls.size(), 2, "4 out: 2 more")
	assert_eq(boss.summons, 6)
	boss.dark_passage()
	await wait_seconds(ThreshFinal.PASSAGE_WARN + 0.1)
	assert_eq(calls.size(), 2, "6 out: none")
	assert_eq(_effects(Sprite2D).size(), 2, "the lantern still lands")
	boss.summon_gone()
	boss.dark_passage()
	await wait_seconds(ThreshFinal.PASSAGE_WARN + 0.1)
	assert_eq(calls.size(), 3, "one gone: one more")
	assert_eq(boss.summons, 6)


# --- the fall: Phase 2 at 0 HP ----------------------------------------------------------


func test_at_0_hp_in_phase_2_he_falls_once_and_never_dies() -> void:
	var boss := _thresh(Vector2(-400, 0))
	await _to_phase_2(boss)
	watch_signals(boss)
	watch_signals(lucian)
	boss.take_damage(DamageInfo.create(999999.0, DamageInfo.Type.TRUE, &"test", lucian))
	boss.take_damage(_lethal())
	await wait_physics_frames(3)
	boss.take_damage(_lethal())
	await wait_physics_frames(2)
	assert_signal_emit_count(boss, "fell", 1)
	assert_signal_not_emitted(boss, "died")
	assert_signal_not_emitted(lucian, "enemy_killed")
	assert_true(boss.is_alive(), "never dead")
	assert_eq(boss.phase, 2, "no third phase")
	assert_eq(boss.hp, 0.0)
	# Fallen, he does nothing more: not even The Box, Lucian 400 away.
	boss._cooldowns[&"the_box"] = 0.0
	await wait_physics_frames(5)
	assert_eq(_warnings(GroundWarning.Shape.RING).size(), 0)


# --- in a stage (6-5) ---------------------------------------------------------------------


func _stage() -> Stage:
	SaveGame.instance().reset()
	return await _stage_keep_save()


func _stage_keep_save(act := 6, number := 5) -> Stage:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, number))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


func _shoot(stage: Stage, enemy: Enemy, amount: float) -> void:
	var shot := LinearProjectile.new()
	shot.launch(enemy.global_position, Vector2.RIGHT, 0.0, 100.0, 30.0)
	shot.hit_enemy.connect(func(hit: Enemy, _prior: int) -> void: hit.take_damage(_hit(amount)))
	stage.get_node("Projectiles").add_child(shot)


## The boss wave, Thresh out and quiet.
func _boss_wave(stage: Stage) -> ThreshFinal:
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	var boss := stage.boss_unit as ThreshFinal
	assert_not_null(boss, "a final Thresh")
	if boss == null:
		return null
	assert_eq(boss.global_position, stage.arena.boss_point)
	_quiet(boss)
	await wait_physics_frames(1)
	return boss


## Dark Passage in the stage: the 3 souls it brings, spawned.
func _souls(stage: Stage, boss: ThreshFinal) -> Array:
	boss.dark_passage()
	await wait_seconds(ThreshFinal.PASSAGE_WARN + 0.1)
	await wait_physics_frames(1)
	return get_tree().get_nodes_in_group(&"enemies").filter(func(enemy: Node) -> bool:
		return enemy is EnemyUnit and (enemy as EnemyUnit).data.id == &"lantern_soul")


func test_a_shot_that_floors_him_in_phase_1_raises_him_safely_and_plays_no_cutscene() -> void:
	var stage: Stage = await _stage()
	var boss := await _boss_wave(stage)
	_shoot(stage, boss, 999999.0)
	await wait_physics_frames(3)
	assert_eq(boss.phase, 2)
	assert_eq(boss.hp, boss.max_hp)
	assert_null(stage.cutscene)
	assert_false(stage.result.visible)
	assert_eq(stage.runner.alive(), 1, "the fight goes on")
	assert_engine_error_count(0)


func test_dark_passage_brings_3_summoned_souls_counted_in_the_wave() -> void:
	var stage: Stage = await _stage()
	var boss := await _boss_wave(stage)
	await _to_phase_2(boss)
	assert_eq(stage.runner.alive(), 1)
	var counted: Array[int] = []
	boss.summon_requested.connect(func(_unit: EnemyUnit, _id: StringName, _at: Vector2) -> void: counted.append(stage.runner.alive()))
	var souls := await _souls(stage, boss)
	assert_eq(counted, [2, 3, 4] as Array[int], "counted at each request")
	assert_eq(souls.size(), 3)
	for soul: EnemyUnit in souls:
		assert_true(soul.summoned)
		assert_eq(soul.summoner, boss)
		assert_eq(soul.wave, boss.wave)
	assert_eq(stage.runner.alive(), 4)
	assert_eq(boss.summons, 3)
	(souls[0] as EnemyUnit).take_damage(_lethal())
	assert_eq(stage.runner.alive(), 3)
	assert_eq(boss.summons, 2, "a soul gone: he is told")
	assert_engine_error_count(0)


func test_his_fall_frees_every_summoned_soul_and_6_5_pays_20_purple_then_4() -> void:
	var stage: Stage = await _stage()
	assert_eq(stage.run.boss, &"thresh_final")
	var boss := await _boss_wave(stage)
	await _to_phase_2(boss)
	var souls := await _souls(stage, boss)
	assert_eq(souls.size(), 3)
	# A soul nobody summoned (debug) is no Thresh soul: it stays.
	var stray := stage.spawn_enemy(&"lantern_soul", boss.global_position + Vector2(0, 400))
	boss.the_box()
	var gold := stage.wallet.gold
	var kills := stage.stats.kills
	# Counted here: he is freed before the asserts.
	var fell := []
	boss.fell.connect(func(thresh: ThreshFinal) -> void: fell.append(thresh))
	_shoot(stage, boss, 999999.0)
	await wait_physics_frames(4)
	assert_is(stage.cutscene, SennaFreed, "the ending plays on his fall")
	stage.cutscene.skip()
	await wait_physics_frames(2)
	assert_eq(fell.size(), 1, "fell, once")
	assert_eq(fell[0], boss, "and says who fell")
	for soul: EnemyUnit in souls:
		assert_true(soul.has_escaped, "freed")
		assert_eq(soul.escape_note, "", "quietly")
	assert_true(stray.is_alive())
	assert_eq(stage.wallet.gold, gold, "freed souls pay nothing")
	assert_eq(stage.stats.kills, kills)
	var left := stage.get_node("Warnings").get_children().filter(func(node: Node) -> bool: return node is GroundWarning and not node.is_queued_for_deletion())
	assert_eq(left.size(), 0, "the warnings are cleared")
	assert_false(is_instance_valid(boss), "he leaves the map")
	assert_null(stage.boss_unit)
	assert_true(stage.result.visible, "the stage is cleared")
	assert_eq(stage.result.title.text, "STAGE CLEARED")
	assert_eq(stage.collected[Essences.BLUE], KillRewards.BOSS_BLUE)
	assert_eq(stage.collected[Essences.ORANGE], KillRewards.BOSS_ORANGE)
	assert_eq(stage.collected[Essences.PURPLE], 20)
	assert_has(stage.reward_lines, "+20 purple essence (first clear)")
	assert_true("thresh_final" in SaveGame.instance().bosses)
	assert_engine_error_count(0)
	get_tree().paused = false
	var again: Stage = await _stage_keep_save()
	var second := await _boss_wave(again)
	await _to_phase_2(second)
	_shoot(again, second, 999999.0)
	await wait_physics_frames(4)
	again.cutscene.skip()
	await wait_physics_frames(2)
	assert_true(again.result.visible)
	assert_has(again.reward_lines, "+4 purple essence (repeat)")
	assert_eq(again.collected[Essences.PURPLE], 4)
	assert_engine_error_count(0)


## Fix round 1 (ruling): in 6-5, the stage's own bookkeeping (a soul's
## death tells him) keeps the cap: 3, then 6, then still 6; one killed, one
## more. The wave counts each one.
func test_in_6_5_his_souls_stop_at_6_and_a_place_freed_is_filled_again() -> void:
	var stage: Stage = await _stage()
	var boss := await _boss_wave(stage)
	await _to_phase_2(boss)
	assert_eq((await _souls(stage, boss)).size(), 3)
	var souls := await _souls(stage, boss)
	assert_eq(souls.size(), 6)
	assert_eq(stage.runner.alive(), 7)
	souls = await _souls(stage, boss)
	assert_eq(souls.size(), 6, "the cap holds")
	assert_eq(stage.runner.alive(), 7)
	(souls[0] as EnemyUnit).take_damage(_lethal())
	assert_eq(boss.summons, 5, "he is told")
	souls = await _souls(stage, boss)
	assert_eq(souls.size(), 6, "one more fills the place")
	assert_eq(stage.runner.alive(), 7)
	assert_eq(boss.summons, 6)
	assert_engine_error_count(0)


## A final Thresh from the debug list: spawned and counted in the wave (as
## DebugTable._spawn does), quiet.
func _debug_thresh(stage: Stage) -> ThreshFinal:
	var thresh := stage.spawn_enemy(&"thresh_final", Vector2(2800, 1500)) as ThreshFinal
	stage.runner.enemy_spawned()
	_quiet(thresh)
	await wait_physics_frames(1)
	return thresh


func _summoned_by(thresh: ThreshFinal) -> Array:
	return get_tree().get_nodes_in_group(&"enemies").filter(func(enemy: Node) -> bool:
		return enemy is EnemyUnit and (enemy as EnemyUnit).summoner == thresh)


## 6-1, wave 1 all out (8 walkers, 4 souls).
func _6_1_wave_1() -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = await _stage_keep_save(6, 1)
	stage.skip_break()
	for i in 20:
		stage.runner.tick(WaveRunner.GROUP_GAP)
	return stage


## Fix round 1 (ruling): a debug Thresh's fall is wired too. Mid-wave in 6-1
## his souls go free, he pays and leaves, and he and they are counted out;
## the wave's own souls stay and the stage goes on.
func test_a_debug_thresh_falls_too_and_the_wave_goes_on() -> void:
	var stage: Stage = await _6_1_wave_1()
	var thresh := await _debug_thresh(stage)
	await _to_phase_2(thresh)
	await _souls(stage, thresh)
	var his := _summoned_by(thresh)
	assert_eq(his.size(), 3)
	var alive := stage.runner.alive()
	_shoot(stage, thresh, 999999.0)
	await wait_physics_frames(4)
	assert_false(is_instance_valid(thresh), "he leaves the map")
	for soul: EnemyUnit in his:
		assert_true(soul.has_escaped, "his souls go free")
	var wave_souls := get_tree().get_nodes_in_group(&"enemies").filter(func(enemy: Node) -> bool:
		return enemy is EnemyUnit and (enemy as EnemyUnit).data.id == &"lantern_soul")
	assert_eq(wave_souls.size(), 4, "the wave's own souls stay")
	assert_eq(stage.runner.alive(), alive - 4, "he and his 3 souls are counted out")
	assert_eq(stage.runner.state, WaveRunner.State.FIGHT)
	assert_false(stage.result.visible)
	assert_eq(stage.collected[Essences.BLUE], KillRewards.BOSS_BLUE)
	assert_eq(stage.collected[Essences.PURPLE], 0, "no boss purple: 6-1 has no boss")
	assert_engine_error_count(0)


## Fix round 1 (ruling): the last one in his wave, his fall ends the wave
## (as a death would), not the stage.
func test_a_debug_thresh_last_in_his_wave_ends_the_wave_not_the_stage() -> void:
	var stage: Stage = await _6_1_wave_1()
	var thresh := await _debug_thresh(stage)
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy != thresh:
			enemy.take_damage(_lethal())
	assert_eq(stage.runner.alive(), 1, "only he is left")
	await _to_phase_2(thresh)
	_shoot(stage, thresh, 999999.0)
	await wait_physics_frames(4)
	assert_false(is_instance_valid(thresh))
	assert_eq(stage.runner.state, WaveRunner.State.BREAK, "his wave is done")
	assert_eq(stage.runner.waves_done(), 1)
	assert_false(stage.result.visible, "6-1 goes on")
	assert_engine_error_count(0)


## Fix round 1 (ruling): in the sandbox (no waves) he falls and goes too.
func test_a_final_thresh_falls_in_the_sandbox_too() -> void:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	add_child_autofree(stage)
	await wait_process_frames(2)
	assert_null(stage.runner)
	stage.lucian.invulnerable = true
	var thresh := stage.spawn_enemy(&"thresh_final", stage.lucian.global_position + Vector2(700, 0)) as ThreshFinal
	_quiet(thresh)
	await wait_physics_frames(1)
	await _to_phase_2(thresh)
	thresh.take_damage(_lethal())
	await wait_physics_frames(3)
	assert_false(is_instance_valid(thresh), "he goes")
	assert_eq(stage.collected[Essences.BLUE], KillRewards.BOSS_BLUE)
	assert_engine_error_count(0)


func test_no_payout_when_lucian_is_dead_as_he_falls() -> void:
	var stage: Stage = await _stage()
	var boss := await _boss_wave(stage)
	await _to_phase_2(boss)
	stage.lucian.invulnerable = false
	stage.lucian.take_damage(_lethal())
	assert_true(stage.lucian.dead)
	boss.take_damage(_lethal())
	await wait_physics_frames(3)
	assert_true(is_instance_valid(boss), "he stays")
	assert_eq(stage.collected[Essences.BLUE], 0)
	assert_false("thresh_final" in SaveGame.instance().bosses)


# --- Act 1's Thresh, as he was ----------------------------------------------------------


func test_act_1s_thresh_keeps_his_numbers_and_stops_at_half() -> void:
	var act_1 := Thresh.new()
	act_1.setup(load("res://data/enemies/thresh_1.tres") as EnemyData, 1, 1, lucian)
	act_1.position = Vector2(2000, 0)
	act_1.projectile_parent = effects
	act_1.warning_parent = effects
	add_child_autofree(act_1)
	assert_eq([act_1.hook_damage, act_1.hook_warn, act_1.hook_cooldown, act_1.flay_damage, act_1.flay_push, act_1.flay_cooldown, act_1.stop_share],
		[80.0, 0.9, 9.0, 60.0, 250.0, 7.0, 0.5])
	assert_eq(_skill_ids(act_1), [&"death_sentence", &"flay"])
	assert_eq([_skill(act_1, &"death_sentence").cooldown, _skill(act_1, &"flay").cooldown], [9.0, 7.0])
	assert_eq(act_1.phase_label(), "")
	watch_signals(act_1)
	act_1.take_damage(_hit(2000.0))
	act_1.take_damage(_hit(500.0))
	assert_signal_emit_count(act_1, "phase_ended", 1)
	assert_almost_eq(act_1.hp, act_1.max_hp * 0.5, 0.01)


func test_a_final_thresh_never_stops_at_half() -> void:
	var boss := _thresh(Vector2(800, 0))
	watch_signals(boss)
	boss.take_damage(_hit(12000.0))
	assert_eq(boss.hp, boss.max_hp - 12000.0)
	assert_signal_not_emitted(boss, "phase_ended")


func test_act_1s_half_hp_still_plays_its_cutscene() -> void:
	SaveGame.instance().reset()
	var stage: Stage = await _stage_keep_save(1, 1)
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	await wait_physics_frames(1)
	assert_true(stage.boss_unit is Thresh and not (stage.boss_unit is ThreshFinal))
	stage.boss_unit.take_damage(_hit(5000.0))
	await wait_physics_frames(2)
	assert_is(stage.cutscene, ThreshTakesSenna)
	stage.cutscene.skip()
	assert_true(stage.result.visible)
	assert_eq(stage.collected[Essences.PURPLE], 10)
	assert_eq(stage.collected[Essences.BLUE], KillRewards.BOSS_BLUE)
