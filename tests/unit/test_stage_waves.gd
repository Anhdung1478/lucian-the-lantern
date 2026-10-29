extends GutTest


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


func _kill_wave(stage: Stage) -> void:
	for i in 20:
		stage.runner.tick(WaveRunner.GROUP_GAP)
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		enemy.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))


func test_the_merchant_comes_only_for_the_break() -> void:
	var stage: Stage = await _stage(2, 1)
	assert_null(stage.merchant)
	stage.skip_break()
	_kill_wave(stage)
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
		_kill_wave(stage)
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
		_kill_wave(stage)
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
		_kill_wave(again)
		await wait_process_frames(1)
	assert_true(again.result.visible)
	assert_false("Stage 2-2 is open" in again.reward_lines, str(again.reward_lines))


func test_next_stage_shows_only_when_it_can_be_played() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.show_result(true)
	assert_true(stage.result.next_button.visible, "2-2 has waves")
	var last: Stage = await _stage(2, 3)
	last.show_result(true)
	assert_false(last.result.next_button.visible, "3-1 has no waves yet")
