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
	stage.result.continue_button.pressed.emit()
	assert_signal_emitted_with_parameters(stage, "finished", [&"cleared"])


func test_dying_shows_defeated() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.lucian.invulnerable = false
	stage.lucian.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	# Frames, not seconds: the result pauses the tree, and GUT's timer with it.
	var give_up := Time.get_ticks_msec() + int((Lucian.DEATH_FADE + 3.0) * 1000.0)
	while not stage.result.visible and Time.get_ticks_msec() < give_up:
		await wait_process_frames(1)
	assert_eq(stage.result.title.text, "DEFEATED")
	watch_signals(stage)
	stage.result.continue_button.pressed.emit()
	assert_signal_emitted_with_parameters(stage, "finished", [&"failed"])


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
	assert_true(texts.any(func(text: String) -> bool: return text.contains("Time 0:01")), str(texts))


func test_the_clock() -> void:
	assert_eq(StageResult.clock(17.2), "0:18")
	assert_eq(StageResult.clock(65.0), "1:05")
