extends GutTest
## Endless mode in the stage: an EndlessRunner on the chosen map, enemies
## scaled by EndlessPlan, bosses at the boss point, repeat purple on boss
## kills, the merchant in breaks, the stage info, the best recorded as each
## wave is won, and the debug jumps.

## Enough frames for any wave: its groups, then splits and escapes.
const KILL_FRAMES := 120
## Journey.ENDLESS_MAPS choices.
const TRAINING_GROUND := 2
const JUNGLE := 3


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_endless_stage_save_slot_")


func after_each() -> void:
	get_tree().paused = false


## An Endless run on map `choice`, from a fresh save; Lucian takes no damage.
func _endless(choice := JUNGLE) -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_endless(SaveGame.instance(), choice, RandomNumberGenerator.new()))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


func _story(act: int, stage_number: int) -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, stage_number))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


func _lethal() -> DamageInfo:
	return DamageInfo.create(999999.0, DamageInfo.Type.TRUE, &"test")


## Kills the wave until the runner has nobody left in it (groups still to
## come, splits, a unit on its way out). Fails the test if some are still
## left after KILL_FRAMES.
func _kill_wave(stage: Stage) -> void:
	for frame in KILL_FRAMES:
		if stage.runner.alive() == 0:
			return
		stage.runner.tick(WaveRunner.GROUP_GAP)
		for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
			enemy.take_damage(_lethal())
		await wait_physics_frames(1)
	if stage.runner.alive() > 0:
		fail_test("%d still in the wave after %d frames" % [stage.runner.alive(), KILL_FRAMES])


## _kill_wave sparing `keep`: until it is the only one left in the wave.
func _kill_all_but(stage: Stage, keep: Enemy) -> void:
	for frame in KILL_FRAMES:
		if stage.runner.alive() == 1:
			return
		stage.runner.tick(WaveRunner.GROUP_GAP)
		for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
			if enemy != keep:
				enemy.take_damage(_lethal())
		await wait_physics_frames(1)


## The unit of `id` on the map (the first one found), or null.
func _unit(id: StringName) -> EnemyUnit:
	for enemy: Node in get_tree().get_nodes_in_group(&"enemies"):
		if (enemy as EnemyUnit).data.id == id:
			return enemy
	return null


func _buttons(node: Node, text: String, into: Array[Button]) -> void:
	var button := node as Button
	if button and button.text == text and not button is OptionButton:
		into.append(button)
	for child in node.get_children():
		_buttons(child, text, into)


## The debug table's button with `text`.
func _debug_button(stage: Stage, text: String) -> Button:
	var found: Array[Button] = []
	_buttons(stage.debug_table, text, found)
	assert_eq(found.size(), 1, "button %s" % text)
	return found[0] if found.size() == 1 else null


func test_the_stage_runs_an_endless_runner_on_the_chosen_map() -> void:
	var stage: Stage = await _endless(JUNGLE)
	assert_is(stage.runner, EndlessRunner)
	assert_is(stage.arena, JungleMap)
	assert_not_null(stage.endless)
	assert_eq(stage.runner.wave, 0)
	assert_null(stage.merchant, "no merchant before wave 1")
	stage.skip_break()
	assert_eq(stage.runner.wave, 1)
	# Two whole packs can leave a wave up to 2 short (EndlessPlan).
	assert_between(stage.runner.alive(), EndlessPlan.normal_count(1) - 2, EndlessPlan.normal_count(1), "wave 1 is made up by EndlessPlan")
	assert_engine_error_count(0)


func test_a_story_stage_has_no_endless_director() -> void:
	var stage: Stage = await _story(2, 1)
	assert_null(stage.endless)
	assert_false(stage.runner is EndlessRunner)


func test_a_wave_1_melee_minion_has_its_base_hp_and_wave_20_follows_the_table() -> void:
	# Training ground is act 2's map: the story would give its minions ×1.6.
	var stage: Stage = await _endless(TRAINING_GROUND)
	var at := stage.arena.spawn_points[0]
	var first := stage.spawn_enemy(WavePlan.MELEE, at, 1)
	assert_almost_eq(first.max_hp, 240.0, 0.01)
	assert_almost_eq(first.hp, first.max_hp, 0.01)
	assert_almost_eq(first.damage, 12.0, 0.01)
	var twentieth := stage.spawn_enemy(WavePlan.MELEE, at, 20)
	assert_almost_eq(twentieth.max_hp, 240.0 * (1.0 + 0.06 * 19) * (1.0 + 0.05 * 19), 0.01)
	assert_almost_eq(twentieth.hp, twentieth.max_hp, 0.01)
	assert_almost_eq(twentieth.damage, 12.0 * (1.0 + 0.025 * 19) * (1.0 + 0.05 * 19), 0.01)
	assert_almost_eq(twentieth.skill_scale, 1.0, 0.0001)


func test_kills_pay_like_the_act_of_their_wave() -> void:
	var stage: Stage = await _endless(TRAINING_GROUND)
	var data: EnemyData = load(Stage.ENEMY_PATH % WavePlan.MELEE)
	var at := stage.arena.spawn_points[0]
	stage.spawn_enemy(WavePlan.MELEE, at, 1).take_damage(_lethal())
	assert_eq(stage.collected[Essences.BLUE], 1 + data.extra_blue, "wave 1 pays like act 1, not the map's act 2")
	var gold := roundi(data.gold * data.reward_scale(1))
	assert_eq(stage.wallet.gold, gold)
	stage.spawn_enemy(WavePlan.MELEE, at, 21).take_damage(_lethal())
	assert_eq(stage.collected[Essences.BLUE], 1 + 3 + 2 * data.extra_blue, "wave 21 pays like act 3")
	assert_eq(stage.wallet.gold, gold + roundi(data.gold * data.reward_scale(3)))


func test_a_boss_comes_at_the_boss_point_with_its_waves_hp_and_scaled_skill_hits() -> void:
	var stage: Stage = await _endless()
	stage.runner.spawn_requested.emit(&"akshan", 20)
	var boss := _unit(&"akshan") as Boss
	assert_not_null(boss)
	assert_eq(boss.global_position, stage.arena.boss_point)
	assert_almost_eq(boss.max_hp, 15000.0 * 1.3, 0.01)
	assert_almost_eq(boss.hp, boss.max_hp, 0.01)
	assert_almost_eq(boss.skill_scale, 1.15, 0.0001)
	assert_almost_eq(boss.damage, 28.0 * 1.15, 0.01)
	assert_almost_eq(boss.skill_hit(100.0, DamageInfo.Type.PHYSICAL, &"test").amount, 115.0, 0.01)
	assert_almost_eq(boss.make_hit().amount, 28.0 * 1.15, 0.01)
	assert_null(stage.boss_unit, "never the stage's boss")


func test_a_mini_boss_has_its_tiers_hp_and_power_and_keeps_its_spawn_point() -> void:
	var stage: Stage = await _endless()
	stage.runner.spawn_requested.emit(&"maokai", 15)
	var maokai := _unit(&"maokai") as Boss
	assert_not_null(maokai)
	assert_ne(maokai.global_position, stage.arena.boss_point)
	assert_almost_eq(maokai.max_hp, 9000.0 * 1.3, 0.01)
	assert_almost_eq(maokai.damage, 90.0 * 1.15, 0.01)
	assert_almost_eq(maokai.skill_hit(100.0, DamageInfo.Type.MAGIC, &"test").amount, 115.0, 0.01)


func test_a_story_boss_keeps_its_hp_and_skill_hits() -> void:
	var stage: Stage = await _story(2, 1)
	var akshan := stage.spawn_enemy(&"akshan", stage.arena.boss_point) as Boss
	assert_almost_eq(akshan.max_hp, 5000.0, 0.01)
	assert_almost_eq(akshan.skill_hit(100.0, DamageInfo.Type.PHYSICAL, &"test").amount, 100.0, 0.01)


func test_a_boss_kill_pays_repeat_purple_and_leaves_the_saves_bosses_alone() -> void:
	var stage: Stage = await _endless()
	var save := SaveGame.instance()
	stage.runner.spawn_requested.emit(&"akshan", 10)
	_unit(&"akshan").take_damage(_lethal())
	assert_eq(stage.collected[Essences.PURPLE], 2, "Akshan's repeat purple, on the kill")
	assert_eq(save.essences.amount(Essences.PURPLE), 2)
	assert_true(save.bosses.is_empty())
	stage.runner.spawn_requested.emit(&"maokai", 5)
	_unit(&"maokai").take_damage(_lethal())
	assert_eq(stage.collected[Essences.PURPLE], 3, "Maokai's repeat purple, never the first-time 5")
	assert_true(save.bosses.is_empty())
	stage.run.purple_mult = 1.5
	stage.runner.spawn_requested.emit(&"akshan", 20)
	_unit(&"akshan").take_damage(_lethal())
	assert_eq(stage.collected[Essences.PURPLE], 6, "× the modifier's purple")
	assert_true(stage.reward_lines.is_empty())


func test_final_thresh_falls_with_repeat_purple_and_no_cutscene_and_the_run_goes_on() -> void:
	var stage: Stage = await _endless()
	stage.skip_break()
	for i in 20:
		stage.runner.tick(WaveRunner.GROUP_GAP)
	stage.runner.spawn_requested.emit(&"thresh_final", 1)
	stage.runner.enemy_spawned()
	var thresh := _unit(&"thresh_final") as ThreshFinal
	assert_eq(thresh.global_position, stage.arena.boss_point)
	assert_almost_eq(thresh.max_hp, 15000.0, 0.01)
	thresh._attack_left = 1000.0
	thresh.move_speed = 0.0
	await _kill_all_but(stage, thresh)
	assert_eq(stage.runner.alive(), 1)
	await wait_physics_frames(1)
	thresh.take_damage(_lethal())
	await wait_physics_frames(2)
	assert_eq(thresh.phase, 2)
	assert_almost_eq(thresh.hp, 15000.0, 0.01, "Phase 2 has the wave's boss HP too")
	thresh._rise_left = 0.0
	await wait_physics_frames(1)
	var blue: int = stage.collected[Essences.BLUE]
	thresh.take_damage(_lethal())
	await wait_physics_frames(3)
	assert_null(stage.cutscene)
	assert_false(is_instance_valid(thresh))
	assert_eq(stage.collected[Essences.PURPLE], 4, "his repeat purple")
	assert_eq(stage.collected[Essences.BLUE], blue + KillRewards.BOSS_BLUE)
	assert_true(SaveGame.instance().bosses.is_empty())
	assert_false(stage.result.visible)
	assert_eq(stage.runner.state, WaveRunner.State.BREAK, "the run goes on")
	assert_eq(stage.runner.waves_done(), 1)
	assert_engine_error_count(0)


func test_the_merchant_comes_in_breaks() -> void:
	var stage: Stage = await _endless()
	stage.skip_break()
	await _kill_wave(stage)
	await wait_process_frames(1)
	assert_eq(stage.runner.state, WaveRunner.State.BREAK)
	assert_not_null(stage.merchant)
	stage.skip_break()
	await wait_process_frames(1)
	assert_null(stage.merchant)
	assert_eq(stage.runner.wave, 2)
	assert_engine_error_count(0)


func test_clearing_a_wave_records_the_best_in_memory() -> void:
	var stage: Stage = await _endless()
	var save := SaveGame.instance()
	assert_eq(save.endless_best, 0)
	stage.skip_break()
	await _kill_wave(stage)
	assert_eq(save.endless_best, 1)
	stage.skip_break()
	await _kill_wave(stage)
	assert_eq(save.endless_best, 2)
	assert_eq(stage.runner.waves_cleared, 2)


func test_clearing_a_wave_never_lowers_the_best() -> void:
	var stage: Stage = await _endless()
	SaveGame.instance().record_endless(5)
	stage.skip_break()
	await _kill_wave(stage)
	assert_eq(SaveGame.instance().endless_best, 5)


func test_the_break_after_a_boss_wave_counts_down_for_now() -> void:
	var stage: Stage = await _endless()
	var runner := stage.runner as EndlessRunner
	runner.held = true
	runner.boss_cleared.emit(10)
	assert_false(runner.held, "released at once until the modifier pick comes")


func test_the_stage_info_reads_endless_waves_and_the_best() -> void:
	SaveGame.instance().reset()
	SaveGame.instance().record_endless(3)
	var runner := EndlessRunner.new(1)
	var info := StageInfo.new()
	add_child_autofree(info)
	info.setup("Endless · Jungle", runner)
	assert_true(info.best_label.visible)
	assert_eq(info.best_label.text, "Best 3")
	assert_eq(info.timer_label.text, "Wave 1 in 0:05")
	runner.state = WaveRunner.State.FIGHT
	runner.wave = 7
	info.refresh()
	assert_eq(info.wave_label.text, "Wave 7")
	runner.wave = 5
	info.refresh()
	assert_eq(info.wave_label.text, "Mini boss wave")
	runner.wave = 10
	info.refresh()
	assert_eq(info.wave_label.text, "Boss wave")
	runner.state = WaveRunner.State.BREAK
	runner.wave = 23
	info.refresh()
	assert_eq(info.timer_label.text, "Wave 24 in 0:05")
	runner.wave = 19
	info.refresh()
	assert_eq(info.timer_label.text, "Boss wave in 0:05")
	SaveGame.instance().record_endless(4)
	info.refresh()
	assert_eq(info.best_label.text, "Best 4")


func test_the_story_stage_info_has_no_best_line() -> void:
	var info := StageInfo.new()
	add_child_autofree(info)
	info.setup("Stage 2-2 · The Sentinels", WaveRunner.new(WavePlan.waves("2-2")))
	assert_false(info.best_label.visible)


## The boss bar shows while a boss lives: in a wave, under the stage info
## and its "Best" line.
func test_the_boss_bar_sits_under_the_endless_stage_info() -> void:
	var stage: Stage = await _endless()
	stage.skip_break()
	await wait_process_frames(2)
	var info := stage.hud.stage_info
	assert_true(info.best_label.visible)
	assert_gte(stage.hud.boss_bar.get_global_rect().position.y, info.get_global_rect().end.y)


func test_jump_to_boss_wave_reaches_the_next_tenth_wave() -> void:
	var stage: Stage = await _endless()
	stage.skip_break()
	_debug_button(stage, "Jump to boss wave").pressed.emit()
	stage.runner.tick(0.1)
	assert_eq(stage.runner.wave, 10)
	assert_true(stage.runner.is_boss_wave())
	stage.runner.tick(0.1)
	var bosses := get_tree().get_nodes_in_group(&"enemies").filter(func(enemy: EnemyUnit) -> bool: return enemy.data.kind == &"boss")
	assert_eq(bosses.size(), 1)
	assert_eq((bosses[0] as EnemyUnit).global_position, stage.arena.boss_point)
	_debug_button(stage, "Jump to boss wave").pressed.emit()
	stage.runner.tick(0.1)
	assert_eq(stage.runner.wave, 20)
	assert_engine_error_count(0)


func test_jump_to_boss_wave_lets_a_held_break_go() -> void:
	var stage: Stage = await _endless()
	var runner := stage.runner as EndlessRunner
	stage.jump_to_boss_wave()
	runner.tick(0.1)
	runner.held = true
	stage.jump_to_boss_wave()
	runner.tick(0.1)
	assert_false(runner.held)
	assert_eq(runner.wave, 20)


func test_the_last_wave_jump_is_hidden_and_does_nothing_in_endless() -> void:
	var stage: Stage = await _endless()
	assert_false(_debug_button(stage, "Jump to the last wave").visible)
	stage.skip_break()
	stage.runner.tick(WaveRunner.GROUP_GAP)
	var enemies := get_tree().get_nodes_in_group(&"enemies").size()
	assert_gt(enemies, 0)
	stage.jump_to_last_wave()
	assert_eq(get_tree().get_nodes_in_group(&"enemies").size(), enemies, "nothing removed")
	assert_eq(stage.runner.wave, 1)


func test_the_last_wave_jump_shows_in_the_story() -> void:
	var stage: Stage = await _story(2, 1)
	assert_true(_debug_button(stage, "Jump to the last wave").visible)


func test_the_debug_wave_line_has_no_last_wave_in_endless() -> void:
	var stage: Stage = await _endless()
	stage.skip_break()
	stage.debug_table.visible = true
	await wait_process_frames(1)
	var texts: Array[String] = []
	_label_texts(stage.debug_table, texts)
	assert_true(texts.any(func(text: String) -> bool: return text.begins_with("Wave 1 (Endless)")), str(texts))


func _label_texts(node: Node, into: Array[String]) -> void:
	if node is Label:
		into.append((node as Label).text)
	for child in node.get_children():
		_label_texts(child, into)
