extends GutTest


func after_each() -> void:
	get_tree().paused = false


func _stage(act: int, stage_number: int) -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, stage_number))
	add_child_autofree(stage)
	await wait_frames(2)
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
	await wait_frames(1)
	assert_eq(stage.runner.state, WaveRunner.State.BREAK)
	assert_not_null(stage.merchant)
	stage.skip_break()
	await wait_frames(1)
	assert_null(stage.merchant)


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
		await wait_frames(1)
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
	# The result pauses the tree, which would freeze GUT's own wait timer.
	await get_tree().create_timer(Lucian.DEATH_FADE + 0.2).timeout
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
