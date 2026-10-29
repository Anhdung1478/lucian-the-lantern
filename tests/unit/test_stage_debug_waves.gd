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
	_pick(stage, &"melee_minion")
	_press(stage, "Spawn")
	assert_eq(_enemies().size(), before + 1)
	assert_eq(stage.runner.alive(), alive + 1)


func _picker(stage: Stage) -> OptionButton:
	var found: Array[OptionButton] = []
	_collect_pickers(stage.debug_table, found)
	for picker in found:
		for i in picker.item_count:
			if picker.get_item_text(i) == "melee_minion":
				return picker
	fail_test("no enemy picker")
	return null


func _collect_pickers(node: Node, into: Array[OptionButton]) -> void:
	if node is OptionButton:
		into.append(node)
	for child in node.get_children():
		_collect_pickers(child, into)


func _pick(stage: Stage, id: StringName) -> void:
	var picker := _picker(stage)
	for i in picker.item_count:
		if picker.get_item_text(i) == String(id):
			picker.select(i)
			return
	fail_test("%s not in the list" % id)


func test_the_list_holds_every_enemy_id() -> void:
	var stage: Stage = await _stage(2, 1)
	var picker := _picker(stage)
	var ids: Array[String] = []
	for i in picker.item_count:
		ids.append(picker.get_item_text(i))
	var expected: Array[String] = []
	for file in DirAccess.get_files_at("res://data/enemies"):
		if file.ends_with(".tres"):
			expected.append(file.get_basename())
	expected.sort()
	assert_eq(ids, expected)
	for id in ["elder_dragon", "dark_lucian", "raptor", "shadow_melee_minion"]:
		assert_has(ids, id)


func test_spawn_makes_the_selected_enemy() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.skip_break()
	for id in [&"raptor", &"shadow_melee_minion"]:
		_pick(stage, id)
		var before := _enemies().size()
		_press(stage, "Spawn")
		assert_eq(_enemies().size(), before + 1, String(id))
		var last := _enemies().back() as EnemyUnit
		assert_eq(last.data.id, id)


func test_boss_hp_51_on_the_elder_dragon_mid_dive() -> void:
	var stage: Stage = await _stage(3, 5)
	var boss := stage.spawn_enemy(&"elder_dragon", stage.lucian.global_position + Vector2(200, 0))
	stage.boss_unit = boss
	boss.remove_from_group(&"enemies")  # untargetable mid-dive
	_press(stage, "Boss HP 51%")
	assert_almost_eq(boss.hp, boss.max_hp * 0.51, 0.01)


func test_boss_hp_51_on_dark_lucian() -> void:
	var stage: Stage = await _stage(4, 3)
	var boss := stage.spawn_enemy(&"dark_lucian", stage.lucian.global_position + Vector2(200, 0))
	_press(stage, "Boss HP 51%")
	assert_almost_eq(boss.hp, boss.max_hp * 0.51, 0.01)


func test_boss_hp_51_leaves_mini_bosses_alone() -> void:
	var stage: Stage = await _stage(3, 2)
	var drake := stage.spawn_enemy(&"infernal_drake", stage.lucian.global_position + Vector2(200, 0))
	_press(stage, "Boss HP 51%")
	assert_almost_eq(drake.hp, drake.max_hp, 0.01)


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


func test_boss_hp_5_sets_a_boss_and_leaves_a_mini_boss_alone() -> void:
	var stage: Stage = await _stage(2, 3)
	_press(stage, "Jump to boss wave")
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	var drake := stage.spawn_enemy(&"infernal_drake", stage.lucian.global_position + Vector2(200, 0))
	_press(stage, "Boss HP 5%")
	assert_almost_eq(drake.hp, drake.max_hp, 0.01)
	var found := false
	for enemy: Enemy in _enemies():
		var unit := enemy as EnemyUnit
		if unit and unit.data.kind == &"boss":
			found = true
			assert_almost_eq(unit.hp, unit.max_hp * 0.05, 0.01)
	assert_true(found, "a boss")


func test_boss_hp_5_finds_a_boss_out_of_the_group() -> void:
	var stage: Stage = await _stage(3, 5)
	var boss := stage.spawn_enemy(&"elder_dragon", stage.lucian.global_position + Vector2(200, 0))
	stage.boss_unit = boss
	boss.remove_from_group(&"enemies")
	_press(stage, "Boss HP 5%")
	assert_almost_eq(boss.hp, boss.max_hp * 0.05, 0.01)


func test_jump_to_the_last_wave_brings_the_mini_boss_without_rewards() -> void:
	var stage: Stage = await _stage(5, 2)
	stage.skip_break()
	for i in 6:
		stage.runner.tick(WaveRunner.GROUP_GAP)
	assert_gt(_enemies().size(), 0)
	var gold := stage.wallet.gold
	_press(stage, "Jump to the last wave")
	assert_eq(stage.wallet.gold, gold, "no rewards")
	assert_eq(stage.runner.wave, stage.runner.total_waves() - 1)
	for i in 30:
		stage.runner.tick(WaveRunner.GROUP_GAP)
	assert_eq(stage.runner.wave, stage.runner.total_waves())
	var maokai := false
	for enemy: Enemy in _enemies():
		var unit := enemy as EnemyUnit
		if unit and unit.data.id == &"maokai":
			maokai = true
	assert_true(maokai, "Maokai in the last wave")
	assert_eq(stage.wallet.gold, gold, "still no rewards")


## The final review: a summon called just before a jump (counted in the old
## wave, still on its way) never comes. The jump reset the count, so its
## death would have ended the last wave one enemy early.
func test_a_summon_pending_at_a_jump_never_comes() -> void:
	var stage: Stage = await _stage(5, 2)
	stage.skip_break()
	var maiden := stage.spawn_enemy(&"maiden_of_the_mist", stage.lucian.global_position + Vector2(600, 0))
	stage._on_summon_requested(maiden, &"ghoul", maiden.global_position + Vector2(80, 0))
	_press(stage, "Jump to the last wave")
	await wait_physics_frames(3)
	var summoned := _enemies().filter(func(node: Node) -> bool: return (node as EnemyUnit).summoned)
	assert_eq(summoned.size(), 0, "the ghoul never comes")
	for i in 30:
		stage.runner.tick(WaveRunner.GROUP_GAP)
	assert_eq(stage.runner.alive(), _enemies().size(), "the last wave counts what is there")


func test_jump_to_the_last_wave_does_nothing_in_training() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.runner = null
	stage.jump_to_last_wave()
	pass_test("no runner, no crash")
