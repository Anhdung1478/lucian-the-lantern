extends GutTest

## Enough frames for any wave: its groups, then splits and escapes.
const KILL_FRAMES := 120


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_stage_waves_save_slot_")


func after_each() -> void:
	get_tree().paused = false


func _stage(act: int, stage_number: int) -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, stage_number))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


func _lethal() -> DamageInfo:
	return DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test")


## Kills the wave until the runner has nobody left in it: groups still to
## come, splits waiting for their deferred spawn, an untargetable boss
## (through boss_unit) and a unit on its way out. Fails the test if some are
## still left after KILL_FRAMES.
func _kill_wave(stage: Stage) -> void:
	for frame in KILL_FRAMES:
		if stage.runner.alive() == 0:
			return
		stage.runner.tick(WaveRunner.GROUP_GAP)
		for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
			enemy.take_damage(_lethal())
		if is_instance_valid(stage.boss_unit) and stage.boss_unit.is_alive():
			stage.boss_unit.set_untargetable(false)
			stage.boss_unit.take_damage(_lethal())
		await wait_physics_frames(1)
	if stage.runner.alive() > 0:
		fail_test("%d still in the wave after %d frames" % [stage.runner.alive(), KILL_FRAMES])


func test_the_merchant_comes_only_for_the_break() -> void:
	var stage: Stage = await _stage(2, 1)
	assert_null(stage.merchant)
	stage.skip_break()
	await _kill_wave(stage)
	await wait_process_frames(1)
	assert_eq(stage.runner.state, WaveRunner.State.BREAK)
	assert_not_null(stage.merchant)
	stage.skip_break()
	await wait_process_frames(1)
	assert_null(stage.merchant)


func test_a_shot_that_ends_a_wave_brings_the_merchant_safely() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.skip_break()
	for i in 20:
		stage.runner.tick(WaveRunner.GROUP_GAP)
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	var last: Enemy = enemies.pop_back()
	for enemy: Enemy in enemies:
		enemy.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	_shoot(stage, last, 99999.0)
	await wait_physics_frames(3)
	assert_false(last.is_alive())
	assert_eq(stage.runner.state, WaveRunner.State.BREAK)
	assert_not_null(stage.merchant)
	assert_engine_error_count(0)


## A shot that hits `enemy` for `amount` from inside area_entered, as an R
## bullet or a Rocketbelt bolt does.
func _shoot(stage: Stage, enemy: Enemy, amount: float) -> void:
	var shot := LinearProjectile.new()
	shot.launch(enemy.global_position, Vector2.RIGHT, 0.0, 100.0, 30.0)
	shot.hit_enemy.connect(func(hit: Enemy, _prior: int) -> void: hit.take_damage(DamageInfo.create(amount, DamageInfo.Type.TRUE, &"test")))
	stage.get_node("Projectiles").add_child(shot)


func test_a_shot_that_ends_the_stage_shows_the_result_safely() -> void:
	var stage: Stage = await _stage(2, 1)
	for wave in 2:
		stage.skip_break()
		for i in 20:
			stage.runner.tick(WaveRunner.GROUP_GAP)
		var enemies := get_tree().get_nodes_in_group(&"enemies")
		var last: Enemy = enemies.pop_back()
		for enemy: Enemy in enemies:
			enemy.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
		_shoot(stage, last, 99999.0)
		await wait_physics_frames(3)
	assert_true(stage.result.visible)
	assert_engine_error_count(0)


func test_a_shot_that_halves_thresh_plays_the_cutscene_safely() -> void:
	var stage: Stage = await _stage(1, 1)
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	await wait_physics_frames(1)
	_shoot(stage, stage.boss_unit, 5000.0)
	await wait_physics_frames(3)
	assert_not_null(stage.cutscene)
	assert_engine_error_count(0)
	stage.cutscene.skip()


func test_skip_gives_the_regen_of_the_time_skipped() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.lucian.hp = 100.0
	stage.skip_break()
	assert_gt(stage.lucian.hp, 100.0 + stage.lucian.stats.hp_regen * 4.0)


func test_clearing_every_wave_shows_stage_cleared() -> void:
	var stage: Stage = await _stage(2, 1)
	for wave in 2:
		stage.skip_break()
		await _kill_wave(stage)
		await wait_process_frames(1)
	assert_true(stage.result.visible)
	assert_eq(stage.result.title.text, "STAGE CLEARED")
	assert_true(get_tree().paused)
	watch_signals(stage)
	stage.result.next_button.pressed.emit()
	assert_signal_emitted_with_parameters(stage, "finished", [&"cleared", &"next"])


func test_dying_shows_defeated() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.lucian.invulnerable = false
	stage.lucian.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	# Frames, not seconds: the result pauses the tree, and GUT's timer with it.
	var give_up := Time.get_ticks_msec() + int((Lucian.DEATH_FADE + 3.0) * 1000.0)
	while not stage.result.visible and Time.get_ticks_msec() < give_up:
		await wait_process_frames(1)
	assert_eq(stage.result.title.text, "DEFEATED")
	assert_eq(stage.result.main_button.text, "Main screen")
	assert_false(stage.result.next_button.visible)
	watch_signals(stage)
	stage.result.main_button.pressed.emit()
	assert_signal_emitted_with_parameters(stage, "finished", [&"failed", &"main"])


func test_losing_the_tutorial_is_game_over() -> void:
	var stage: Stage = await _stage(1, 1)
	assert_true(stage.run.tutorial)
	stage.show_result(false)
	assert_eq(stage.result.title.text, "GAME OVER")
	assert_eq(stage.result.main_button.text, "Back to title")
	assert_false(stage.result.retry_button.visible)
	watch_signals(stage)
	stage.result.main_button.pressed.emit()
	assert_signal_emitted_with_parameters(stage, "finished", [&"failed", &"title"])


func test_losing_act_1_after_its_first_clear_is_only_defeated() -> void:
	SaveGame.instance().reset()
	SaveGame.instance().set_cleared(["1-1"] as Array[String])
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 1, 1))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.show_result(false)
	assert_eq(stage.result.title.text, "DEFEATED")


func test_act_1_melee_and_ranged_minions_have_20_percent_less_hp() -> void:
	var stage: Stage = await _stage(1, 1)
	var at := stage.arena.spawn_points[0]
	var melee := stage.spawn_enemy(WavePlan.MELEE, at)
	assert_almost_eq(melee.max_hp, 240.0 * 0.8, 0.01)
	assert_almost_eq(melee.hp, melee.max_hp, 0.01)
	assert_almost_eq(stage.spawn_enemy(WavePlan.RANGED, at).max_hp, 160.0 * 0.8, 0.01)
	assert_almost_eq(stage.spawn_enemy(WavePlan.SIEGE, at).max_hp, 700.0, 0.01)


func test_act_2_minions_keep_their_hp() -> void:
	var stage: Stage = await _stage(2, 1)
	assert_almost_eq(stage.spawn_enemy(WavePlan.MELEE, stage.arena.spawn_points[0]).max_hp, 240.0 * 1.6, 0.01)


func test_esc_does_nothing_on_the_result() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.show_result(true)
	var esc := InputEventAction.new()
	esc.action = &"open_menu"
	esc.pressed = true
	stage.screens._input(esc)
	assert_false(stage.screens.menu.visible)


func test_the_result_shows_the_stage_time() -> void:
	var stage: Stage = await _stage(2, 1)
	await wait_seconds(0.5)
	stage.show_result(true)
	assert_gt(stage.elapsed, 0.4)
	var texts := stage.result.find_children("*", "Label", true, false).map(func(label: Label) -> String: return label.text)
	assert_true("Time" in texts and "0:01" in texts, str(texts))


func test_the_clock() -> void:
	assert_eq(StageResult.clock(17.2), "0:18")
	assert_eq(StageResult.clock(65.0), "1:05")


func _melee(stage: Stage) -> EnemyUnit:
	return stage.spawn_enemy(WavePlan.MELEE, stage.arena.spawn_points[0])


func test_the_stage_counts_kills_and_gold() -> void:
	var stage: Stage = await _stage(2, 1)
	for i in 3:
		_melee(stage).take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	assert_eq(stage.stats.kills, 3)
	assert_eq(stage.stats.gold_earned, stage.wallet.gold)


func test_damage_dealt_is_lucians_hits_capped_at_the_hp_lost() -> void:
	var stage: Stage = await _stage(2, 1)
	var enemy := _melee(stage)
	var hp := enemy.hp
	enemy.take_damage(stage.lucian.make_damage(100.0, DamageInfo.Type.TRUE, &"attack"))
	assert_almost_eq(stage.stats.damage_dealt, 100.0, 0.01)
	enemy.take_damage(stage.lucian.make_damage(99999.0, DamageInfo.Type.TRUE, &"attack"))
	assert_almost_eq(stage.stats.damage_dealt, hp, 0.01)
	assert_eq(stage.stats.kills, 1)


func test_other_attackers_and_debug_damage_add_nothing_to_damage_dealt() -> void:
	var stage: Stage = await _stage(2, 1)
	var enemy := _melee(stage)
	enemy.take_damage(DamageInfo.create(100.0, DamageInfo.Type.TRUE, &"test"))
	assert_eq(stage.stats.damage_dealt, 0.0)
	enemy.take_damage(stage.lucian.make_damage(99999.0, DamageInfo.Type.TRUE, &"debug"))
	assert_eq(stage.stats.damage_dealt, 0.0)
	assert_eq(stage.stats.kills, 1)


func test_damage_taken_counts_after_armor() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.lucian.invulnerable = false
	stage.lucian.take_damage(DamageInfo.create(50.0, DamageInfo.Type.TRUE, &"test"))
	assert_almost_eq(stage.stats.damage_taken, 50.0, 0.01)


func test_the_hud_hides_on_the_result() -> void:
	var stage: Stage = await _stage(2, 1)
	assert_true(stage.hud.visible)
	stage.show_result(true)
	assert_false(stage.hud.visible)


func test_the_result_lists_the_stats() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.stats.kills = 87
	stage.stats.damage_dealt = 41234.0
	stage.show_result(true)
	var texts := stage.result.find_children("*", "Label", true, false).map(func(label: Label) -> String: return label.text)
	for text in ["Kills", "87", "Damage dealt", "41.2k", "Gold earned", "Level reached", "Waves", "0 / 2"]:
		assert_true(text in texts, "%s in %s" % [text, texts])


func test_stage_is_open_shows_on_a_first_clear_only() -> void:
	var stage: Stage = await _stage(2, 1)
	for wave in 2:
		stage.skip_break()
		await _kill_wave(stage)
		await wait_process_frames(1)
	assert_true("Stage 2-2 is open" in stage.reward_lines, str(stage.reward_lines))
	SaveGame.instance().set_cleared(["2-1"] as Array[String])
	var again: Stage = load("res://src/stage/stage.tscn").instantiate()
	again.setup(StageSetup.for_stage(SaveGame.instance(), 2, 1))
	add_child_autofree(again)
	await wait_process_frames(2)
	again.lucian.invulnerable = true
	for wave in 2:
		again.skip_break()
		await _kill_wave(again)
		await wait_process_frames(1)
	assert_true(again.result.visible)
	assert_false("Stage 2-2 is open" in again.reward_lines, str(again.reward_lines))


func test_next_stage_shows_only_when_it_can_be_played() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.show_result(true)
	assert_true(stage.result.next_button.visible, "2-2 has waves")
	var act_end: Stage = await _stage(2, 3)
	act_end.show_result(true)
	assert_true(act_end.result.next_button.visible, "3-1 has waves")
	var last: Stage = await _stage(3, 5)
	last.show_result(true)
	assert_true(last.result.next_button.visible, "4-1 has waves")
	var act_4_end: Stage = await _stage(4, 3)
	act_4_end.show_result(true)
	assert_false(act_4_end.result.next_button.visible, "5-1 has no waves yet")


## Phase 7: camps, splits, escapes, buffs on kill and mini bosses, with
## enemy data built in code (the Act 3 files come later).
func _data(id: StringName, kind := &"normal") -> EnemyData:
	var data := EnemyData.new()
	data.id = id
	data.display_name = String(id).capitalize()
	data.kind = kind
	data.max_hp = 500.0
	data.gold = 40
	data.xp = 20
	return data


## A big Krug: its death brings 2 melee minions.
func _krug(kind := &"normal") -> EnemyData:
	var data := _data(&"test_krug_big", kind)
	data.split_into = WavePlan.MELEE
	data.split_count = 2
	return data


func _drops(stage: Stage) -> Array[Node]:
	return stage.get_node("World").get_children().filter(func(node: Node) -> bool: return node is LootDrop)


func _melees() -> Array[Node]:
	return get_tree().get_nodes_in_group(&"enemies").filter(func(enemy: Node) -> bool: return (enemy as EnemyUnit).data.id == WavePlan.MELEE)


## The current wave all spawned, plus `data` counted in it; every other
## enemy is killed, so `data`'s unit is the only one left.
func _alone_in_wave(stage: Stage, data: EnemyData) -> EnemyUnit:
	for i in 20:
		stage.runner.tick(WaveRunner.GROUP_GAP)
	var unit := stage.spawn_unit(data, stage.arena.spawn_points[0], stage.runner.wave)
	stage.runner.enemy_spawned()
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy != unit:
			enemy.take_damage(_lethal())
	assert_eq(stage.runner.alive(), 1)
	return unit


func test_a_split_brings_2_units_where_it_died_and_the_wave_waits_for_them() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.skip_break()
	var krug := _alone_in_wave(stage, _krug())
	var kills := stage.stats.kills
	_shoot(stage, krug, 99999.0)
	await wait_physics_frames(3)
	assert_false(krug.is_alive())
	var splits := _melees()
	assert_eq(splits.size(), 2)
	for split: EnemyUnit in splits:
		assert_lt(split.global_position.distance_to(krug.global_position), 100.0)
	assert_eq(stage.runner.state, WaveRunner.State.FIGHT, "the wave waits for the splits")
	assert_eq(stage.runner.alive(), 2)
	for split: EnemyUnit in splits:
		split.take_damage(_lethal())
	assert_eq(stage.runner.state, WaveRunner.State.BREAK)
	assert_eq(stage.stats.kills, kills + 3, "the Krug and its 2 splits")
	assert_engine_error_count(0)


func test_a_split_on_the_last_wave_never_ends_the_stage() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.skip_break()
	await _kill_wave(stage)
	stage.skip_break()
	# A boss's kind, so its loot is sure.
	var krug := _alone_in_wave(stage, _krug(&"boss"))
	assert_true(stage.runner.is_last_enemy())
	krug.take_damage(_lethal())
	assert_false(stage.result.visible)
	assert_eq(stage.runner.alive(), 2)
	assert_gt(_drops(stage).size(), 0, "not the stage-ending kill: it drops its loot")
	await wait_physics_frames(1)
	assert_eq(_melees().size(), 2)
	await _kill_wave(stage)
	assert_true(stage.result.visible)
	assert_engine_error_count(0)


func test_an_escape_is_done_for_the_wave_with_no_reward_and_no_kill() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.skip_break()
	var data := _data(&"test_scuttler", &"elite")
	data.escape_after = 0.3
	data.extra_blue = 45
	var scuttler := _alone_in_wave(stage, data)
	var gold := stage.wallet.gold
	var xp := stage.lucian.progress.xp
	var blue: int = stage.collected[Essences.BLUE]
	var kills := stage.stats.kills
	watch_signals(stage)
	for frame in 60:
		if scuttler.has_escaped:
			break
		await wait_physics_frames(1)
	assert_true(scuttler.has_escaped)
	assert_false(scuttler.is_alive())
	assert_false(scuttler.is_in_group(&"enemies"))
	assert_eq(stage.runner.state, WaveRunner.State.BREAK, "done for the wave")
	assert_eq(stage.runner.waves_done(), 1)
	# A shot in flight, and a direct hit, can't kill it now.
	_shoot(stage, scuttler, 99999.0)
	assert_eq(scuttler.take_damage(_lethal()), 0.0)
	await wait_physics_frames(3)
	assert_false(scuttler.dead)
	assert_eq(stage.stats.kills, kills)
	assert_eq(stage.wallet.gold, gold)
	assert_eq(stage.lucian.progress.xp, xp)
	assert_eq(stage.collected[Essences.BLUE], blue)
	assert_eq(stage.runner.waves_done(), 1)
	assert_signal_not_emitted(stage, "enemy_died")
	var texts := stage.damage_numbers.get_children().filter(func(node: Node) -> bool: return node is FloatingText).map(func(note: FloatingText) -> String: return note.text)
	assert_has(texts, "Escaped!")
	assert_engine_error_count(0)


func test_a_mini_boss_pays_its_purple_on_the_kill_then_the_repeat() -> void:
	var stage: Stage = await _stage(2, 1)
	var data := _data(&"infernal_drake", &"mini_boss")
	data.display_name = "Infernal Drake"
	data.purple_first = 5
	data.purple_repeat = 1
	var at := stage.arena.spawn_points[0]
	stage.spawn_unit(data, at).take_damage(_lethal())
	assert_eq(stage.collected[Essences.PURPLE], 5)
	assert_eq(SaveGame.instance().essences.amount(Essences.PURPLE), 5)
	assert_has(stage.reward_lines, "+5 purple essence (Infernal Drake, first kill)")
	stage.spawn_unit(data, at).take_damage(_lethal())
	assert_eq(stage.collected[Essences.PURPLE], 6)
	assert_has(stage.reward_lines, "+1 purple essence (Infernal Drake, repeat)")


func test_buff_on_kill_gives_lucian_the_buff() -> void:
	var stage: Stage = await _stage(2, 1)
	var data := _data(&"test_blue_sentinel", &"elite")
	data.buff_on_kill = JungleBuffs.BLUE
	assert_false(stage.lucian.has_stat_buff(JungleBuffs.BLUE))
	stage.spawn_unit(data, stage.arena.spawn_points[0]).take_damage(_lethal())
	assert_true(stage.lucian.has_stat_buff(JungleBuffs.BLUE))


func test_units_with_a_camp_spawn_at_it() -> void:
	var stage: Stage = await _stage(2, 1)
	var camp := Vector2(2400, 900)
	stage.arena.camps = {&"krugs": camp}
	var data := _data(&"test_camp_krug")
	data.camp = &"krugs"
	# Registered under its id, so the stage loads it like a file.
	data.take_over_path(Stage.ENEMY_PATH % data.id)
	for i in 6:
		stage.runner.spawn_requested.emit(data.id, 1)
	stage.runner.spawn_requested.emit(WavePlan.MELEE, 1)
	var found := 0
	for enemy: EnemyUnit in get_tree().get_nodes_in_group(&"enemies"):
		if enemy.data == data:
			found += 1
			assert_lte(absf(enemy.global_position.x - camp.x), 90.0)
			assert_lte(absf(enemy.global_position.y - camp.y), 90.0)
		else:
			var near_a_spawn_point := stage.arena.spawn_points.any(func(point: Vector2) -> bool: return enemy.global_position.distance_to(point) <= 70.0 * sqrt(2.0) + 0.1)
			assert_true(near_a_spawn_point, "no camp: the spawn points")
	assert_eq(found, 6)


func test_the_jungle_behaviors_come_as_monsters_and_minions_stay_minions() -> void:
	var stage: Stage = await _stage(2, 1)
	var at := stage.arena.spawn_points[0]
	for id in [&"raptor", &"raptor_big", &"murkwolf", &"murkwolf_big", &"krug", &"krug_big", &"gromp", &"blue_sentinel", &"red_brambleback", &"rift_scuttler"]:
		assert_true(stage.spawn_enemy(id, at) is Monster, String(id))
	for id in [WavePlan.MELEE, WavePlan.RANGED, WavePlan.SIEGE, WavePlan.SUPER]:
		var unit := stage.spawn_enemy(id, at)
		assert_true(unit is Minion and not (unit is Monster), String(id))


## Phase 8: summons and vanish. The summon's data is registered under its id,
## so the stage loads it like a file, and kept here so the path stays cached.
## It has a boss's kind: paid like a kill, it would drop loot for sure and
## 100 blue.
var _summon: EnemyData


func _summon_data() -> EnemyData:
	_summon = _data(&"test_summon", &"boss")
	_summon.take_over_path(Stage.ENEMY_PATH % _summon.id)
	return _summon


func _summoner_data(every: float, count: int, cap: int) -> EnemyData:
	var data := _data(&"test_summoner", &"elite")
	data.summon_id = &"test_summon"
	data.summon_every = every
	data.summon_count = count
	data.summon_cap = cap
	return data


func _units(id: StringName) -> Array[Node]:
	return get_tree().get_nodes_in_group(&"enemies").filter(func(enemy: Node) -> bool:
		return enemy is EnemyUnit and (enemy as EnemyUnit).data.id == id)


func _notes(stage: Stage) -> Array[Node]:
	return stage.damage_numbers.get_children().filter(func(node: Node) -> bool: return node is FloatingText)


func test_a_summon_joins_the_wave_and_pays_a_quarter_with_no_essence_or_loot() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.skip_break()
	_summon_data()
	var summoner := _alone_in_wave(stage, _summoner_data(0.1, 1, 1))
	var counted: Array[int] = []
	summoner.summon_requested.connect(func(_unit: EnemyUnit, _id: StringName, _at: Vector2) -> void: counted.append(stage.runner.alive()))
	# Summoners call only while Lucian can be fought.
	stage.lucian.invulnerable = false
	for frame in 30:
		if not counted.is_empty():
			break
		await wait_physics_frames(1)
	stage.lucian.invulnerable = true
	assert_eq(counted, [2] as Array[int], "counted in the wave at the request")
	await wait_physics_frames(1)
	var summons := _units(&"test_summon")
	assert_eq(summons.size(), 1, "spawned (deferred)")
	var summon: EnemyUnit = summons[0]
	assert_true(summon.summoned)
	assert_false(summoner.summoned)
	assert_eq(summon.summoner, summoner)
	assert_eq(summon.wave, summoner.wave)
	assert_lt(summon.global_position.distance_to(summoner.global_position), 150.0, "beside it")
	var gold := stage.wallet.gold
	var blue: int = stage.collected[Essences.BLUE]
	var orange: int = stage.collected[Essences.ORANGE]
	var drops := _drops(stage).size()
	var kills := stage.stats.kills
	stage.lucian.progress.xp = 0
	summon.take_damage(_lethal())
	assert_eq(stage.wallet.gold - gold, 10, "a quarter of 40")
	assert_eq(stage.lucian.progress.xp, 5, "a quarter of 20")
	assert_eq(stage.collected[Essences.BLUE], blue, "no essence")
	assert_eq(stage.collected[Essences.ORANGE], orange)
	assert_eq(_drops(stage).size(), drops, "no loot, though its kind always drops some")
	assert_eq(stage.stats.kills, kills + 1, "still a kill")
	assert_eq(summoner.summons, 0, "its summoner was told")
	assert_eq(stage.runner.state, WaveRunner.State.FIGHT, "the summoner is left")
	summoner.take_damage(_lethal())
	assert_eq(stage.runner.state, WaveRunner.State.BREAK)
	assert_engine_error_count(0)


func test_the_cap_holds_and_a_summon_gone_makes_room() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.skip_break()
	_summon_data()
	var summoner := _alone_in_wave(stage, _summoner_data(0.1, 2, 3))
	stage.lucian.invulnerable = false
	await wait_physics_frames(45)
	var summons := _units(&"test_summon")
	assert_eq(summons.size(), 3, "2, then 1: the cap")
	assert_eq(stage.runner.alive(), 4)
	(summons[0] as EnemyUnit).take_damage(_lethal())
	(summons[1] as EnemyUnit).vanish()
	assert_eq(summoner.summons, 1, "told of a kill and of a vanish")
	await wait_physics_frames(15)
	stage.lucian.invulnerable = true
	assert_eq(_units(&"test_summon").size(), 3, "two more, up to the cap again")
	assert_eq(stage.runner.alive(), 4)
	await _kill_wave(stage)
	assert_eq(stage.runner.state, WaveRunner.State.BREAK)
	assert_engine_error_count(0)


func test_a_summoners_death_leaves_its_summons_in_the_wave() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.skip_break()
	_summon_data()
	var summoner := _alone_in_wave(stage, _summoner_data(0.1, 2, 2))
	stage.lucian.invulnerable = false
	await wait_physics_frames(12)
	stage.lucian.invulnerable = true
	var summons := _units(&"test_summon")
	assert_eq(summons.size(), 2)
	summoner.take_damage(_lethal())
	assert_eq(stage.runner.state, WaveRunner.State.FIGHT, "the wave waits for them")
	assert_eq(stage.runner.alive(), 2)
	# They outlive it, even once it has left the tree.
	await wait_seconds(Enemy.DEATH_FADE + 0.2)
	assert_false(is_instance_valid(summoner))
	for summon: EnemyUnit in summons:
		assert_true(summon.is_alive())
		summon.take_damage(_lethal())
	assert_eq(stage.runner.state, WaveRunner.State.BREAK)
	assert_engine_error_count(0)


## Ruling RV1: a summon asked for on the very frame its summoner dies still
## comes (it is counted already), and the wave ends only with it.
func test_a_summon_asked_for_as_its_summoner_dies_still_comes_and_the_wave_waits() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.skip_break()
	_summon_data()
	var summoner := _alone_in_wave(stage, _summoner_data(0.1, 1, 1))
	var at_death := {}
	# Killed the moment it asks: after the stage counted the summon, before
	# the summon's deferred spawn.
	summoner.summon_requested.connect(func(_unit: EnemyUnit, _id: StringName, _at: Vector2) -> void:
		summoner.take_damage(_lethal())
		at_death.state = stage.runner.state
		at_death.alive = stage.runner.alive()
		at_death.here = _units(&"test_summon").size())
	stage.lucian.invulnerable = false
	for frame in 30:
		if summoner.dead:
			break
		await wait_physics_frames(1)
	stage.lucian.invulnerable = true
	assert_true(summoner.dead)
	assert_eq(at_death, {"state": WaveRunner.State.FIGHT, "alive": 1, "here": 0}, "dead, its summon counted and on its way")
	await wait_physics_frames(1)
	var summons := _units(&"test_summon")
	assert_eq(summons.size(), 1, "it still comes")
	assert_eq(stage.runner.state, WaveRunner.State.FIGHT)
	(summons[0] as EnemyUnit).take_damage(_lethal())
	assert_eq(stage.runner.state, WaveRunner.State.BREAK, "and the wave ends with it")
	assert_engine_error_count(0)


func test_summons_come_in_the_sandbox_and_never_in_a_wall() -> void:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	add_child_autofree(stage)
	await wait_process_frames(2)
	assert_null(stage.runner)
	_summon_data()
	var summoner := stage.spawn_unit(_summoner_data(0.1, 1, 1), stage.lucian.global_position + Vector2(700, 0))
	await wait_physics_frames(12)
	var summons := _units(&"test_summon")
	assert_eq(summons.size(), 1)
	(summons[0] as EnemyUnit).take_damage(_lethal())
	assert_eq(summoner.summons, 0)
	# A spot off the map: it comes out on its summoner instead.
	stage.lucian.invulnerable = true
	summoner.summon_requested.emit(summoner, &"test_summon", Vector2(-500, -500))
	await wait_physics_frames(1)
	summons = _units(&"test_summon")
	assert_eq(summons.size(), 1)
	assert_lt((summons[0] as EnemyUnit).global_position.distance_to(summoner.global_position), 60.0)
	assert_engine_error_count(0)


func test_a_vanish_pays_nothing_shows_no_note_and_the_wave_still_ends() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.skip_break()
	var data := _data(&"test_sapling", &"elite")
	data.extra_blue = 45
	var sapling := _alone_in_wave(stage, data)
	var gold := stage.wallet.gold
	var xp := stage.lucian.progress.xp
	var blue: int = stage.collected[Essences.BLUE]
	var kills := stage.stats.kills
	var drops := _drops(stage).size()
	var notes := _notes(stage).size()
	watch_signals(stage)
	sapling.vanish()
	assert_false(sapling.is_alive())
	assert_eq(stage.runner.state, WaveRunner.State.BREAK, "done for the wave")
	assert_eq(stage.runner.waves_done(), 1)
	assert_eq(stage.wallet.gold, gold)
	assert_eq(stage.lucian.progress.xp, xp)
	assert_eq(stage.collected[Essences.BLUE], blue)
	assert_eq(stage.stats.kills, kills)
	assert_eq(_drops(stage).size(), drops)
	assert_eq(_notes(stage).size(), notes, "no note")
	assert_signal_not_emitted(stage, "enemy_died")
	assert_engine_error_count(0)
