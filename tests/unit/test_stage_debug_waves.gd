extends GutTest


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_stage_debug_waves_save_slot_")


func after_each() -> void:
	get_tree().paused = false


func _stage(act: int, stage_number: int) -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, stage_number))
	add_child_autofree(stage)
	await wait_physics_frames(2)
	return stage


func _press(stage: Stage, text: String) -> void:
	var found: Array[Button] = []
	_collect(stage.debug_table, text, found)
	assert_eq(found.size(), 1, "button %s" % text)
	if found.size() == 1:
		found[0].pressed.emit()


func _collect(node: Node, text: String, into: Array[Button]) -> void:
	var button := node as Button
	if button and button.text == text and not button is OptionButton:
		into.append(button)
	for child in node.get_children():
		_collect(child, text, into)


func _enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group(&"enemies")


func test_kill_all_empties_the_group_and_pays() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.skip_break()
	for i in 20:
		stage.runner.tick(WaveRunner.GROUP_GAP)
	assert_gt(_enemies().size(), 0)
	_press(stage, "Kill all enemies")
	assert_eq(_enemies().size(), 0)
	assert_gt(stage.wallet.gold, 0)


func test_spawn_melee_adds_one_that_counts_toward_the_wave() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.skip_break()
	var before := _enemies().size()
	var alive := stage.runner.alive()
	_press(stage, "Spawn melee")
	assert_eq(_enemies().size(), before + 1)
	assert_eq(stage.runner.alive(), alive + 1)


func test_god_mode_makes_lucian_invulnerable() -> void:
	var stage: Stage = await _stage(2, 1)
	assert_false(stage.lucian.invulnerable)
	var found: Array[CheckBox] = []
	_find_check(stage.debug_table, "God mode (no damage)", found)
	assert_eq(found.size(), 1)
	found[0].button_pressed = true
	assert_true(stage.lucian.invulnerable)
	found[0].button_pressed = false
	assert_false(stage.lucian.invulnerable)


func _find_check(node: Node, text: String, into: Array[CheckBox]) -> void:
	var check := node as CheckBox
	if check and check.text == text:
		into.append(check)
	for child in node.get_children():
		_find_check(child, text, into)


func test_jump_to_boss_wave_then_ticks_spawn_akshan() -> void:
	var stage: Stage = await _stage(2, 3)
	_press(stage, "Jump to boss wave")
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	var boss: EnemyUnit
	for enemy: Enemy in _enemies():
		var unit := enemy as EnemyUnit
		if unit and unit.data.kind == &"boss":
			boss = unit
	assert_not_null(boss)


func test_boss_hp_51_sets_the_boss() -> void:
	var stage: Stage = await _stage(2, 3)
	_press(stage, "Jump to boss wave")
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	_press(stage, "Boss HP 51%")
	for enemy: Enemy in _enemies():
		var unit := enemy as EnemyUnit
		if unit and unit.data.kind == &"boss":
			assert_almost_eq(unit.hp, unit.max_hp * 0.51, 0.01)
			return
	fail_test("no boss")


func test_skip_break_starts_the_wave() -> void:
	var stage: Stage = await _stage(2, 1)
	assert_ne(stage.runner.state, WaveRunner.State.FIGHT)
	_press(stage, "Skip break")
	assert_eq(stage.runner.state, WaveRunner.State.FIGHT)


func test_freeze_keeps_god_mode() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.lucian.invulnerable = true
	stage.freeze(true)
	assert_true(stage.lucian.invulnerable)
	stage.freeze(false)
	assert_true(stage.lucian.invulnerable)


func test_freeze_without_god_mode_ends_vulnerable() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.lucian.invulnerable = false
	stage.freeze(true)
	assert_true(stage.lucian.invulnerable)
	stage.freeze(false)
	assert_false(stage.lucian.invulnerable)
