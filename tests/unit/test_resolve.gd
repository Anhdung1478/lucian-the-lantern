extends GutTest
## R1: Resolve. Each defeat on a story stage not yet cleared gives a stack
## there, up to 5: more damage dealt and less taken, 10% a stack on Easy and
## Normal, 5% on Hard, none on Extreme, until the stage is cleared.

const STAGE_SCENE := "res://src/stage/stage.tscn"


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_resolve_save_slot_")
	SaveGame.instance().reset()


func after_each() -> void:
	get_tree().paused = false
	SaveGame.instance().reset()
	if not Resolve.enabled():
		GameSettings.instance().set_value(Resolve.SETTING, true)


# --- The rule ------------------------------------------------------------------


func test_a_stack_is_worth_10_percent_5_on_hard_and_nothing_on_extreme() -> void:
	assert_eq(Difficulty.LEVELS.map(func(level: int) -> float: return Difficulty.resolve_step(level)), [0.1, 0.1, 0.05, 0.0])
	assert_eq(Difficulty.resolve_step(7), 0.1, "an unknown level is Normal")


func test_each_defeat_is_a_stack_up_to_5() -> void:
	assert_eq(Resolve.MAX_STACKS, 5)
	for level in [Difficulty.EASY, Difficulty.NORMAL, Difficulty.HARD]:
		assert_eq(range(8).map(func(defeats: int) -> int: return Resolve.stacks(defeats, level)), [0, 1, 2, 3, 4, 5, 5, 5],
			Difficulty.name_of(level))
	assert_eq(Resolve.stacks(3, Difficulty.EXTREME), 0, "Extreme has no Resolve")
	assert_eq(Resolve.stacks(-2, Difficulty.NORMAL), 0)


func test_a_stack_raises_the_damage_dealt_and_lowers_the_damage_taken() -> void:
	for level in [Difficulty.EASY, Difficulty.NORMAL]:
		assert_almost_eq(Resolve.damage_dealt_scale(0, level), 1.0, 0.0001)
		assert_almost_eq(Resolve.damage_taken_scale(0, level), 1.0, 0.0001)
		assert_almost_eq(Resolve.damage_dealt_scale(3, level), 1.3, 0.0001, Difficulty.name_of(level))
		assert_almost_eq(Resolve.damage_taken_scale(3, level), 0.7, 0.0001, Difficulty.name_of(level))
		assert_almost_eq(Resolve.damage_dealt_scale(5, level), 1.5, 0.0001)
		assert_almost_eq(Resolve.damage_taken_scale(5, level), 0.5, 0.0001, "5 stacks halve it")
	assert_almost_eq(Resolve.damage_dealt_scale(5, Difficulty.HARD), 1.25, 0.0001)
	assert_almost_eq(Resolve.damage_taken_scale(5, Difficulty.HARD), 0.75, 0.0001)
	assert_almost_eq(Resolve.damage_dealt_scale(2, Difficulty.HARD), 1.1, 0.0001)
	assert_almost_eq(Resolve.damage_dealt_scale(5, Difficulty.EXTREME), 1.0, 0.0001)
	assert_almost_eq(Resolve.damage_taken_scale(5, Difficulty.EXTREME), 1.0, 0.0001)
	assert_eq([Resolve.percent(3, Difficulty.NORMAL), Resolve.percent(3, Difficulty.HARD), Resolve.percent(5, Difficulty.EASY)], [30, 15, 50])


# --- On Lucian -----------------------------------------------------------------


func _lucian(stacks: int, level := Difficulty.NORMAL) -> Lucian:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	# Shots and trails go here and are freed with it.
	lucian.projectile_parent = add_child_autofree(Node2D.new())
	add_child_autofree(lucian)
	var setup := StageSetup.new()
	setup.difficulty = level
	setup.resolve = stacks
	setup.defeats = stacks
	lucian.apply_setup(setup)
	return lucian


## A plain enemy with no armor.
func _enemy(hp := 10000.0) -> Enemy:
	var enemy := Enemy.new()
	enemy.max_hp = hp
	enemy.position = Vector2(300, 0)
	add_child_autofree(enemy)
	return enemy


func test_lucian_takes_less_with_each_stack_on_top_of_the_difficulty() -> void:
	var expected := {Difficulty.EASY: 0.8 * 0.7, Difficulty.NORMAL: 0.7, Difficulty.HARD: 1.1 * 0.85, Difficulty.EXTREME: 1.3}
	for level: int in expected:
		var lucian := _lucian(3, level)
		assert_almost_eq(lucian.damage_taken_scale, expected[level], 0.0001, Difficulty.name_of(level))
		var before := lucian.hp
		lucian.take_damage(DamageInfo.create(100.0, DamageInfo.Type.TRUE, &"test"))
		assert_almost_eq(before - lucian.hp, 100.0 * expected[level], 0.01, Difficulty.name_of(level))
	var none := _lucian(0, Difficulty.HARD)
	assert_almost_eq(none.damage_taken_scale, 1.1, 0.0001, "no stack: the difficulty alone")
	assert_almost_eq(_lucian(5).damage_taken_scale, 0.5, 0.0001, "5 stacks halve it")


func test_lucian_deals_more_with_each_stack_whatever_the_source() -> void:
	var lucian := _lucian(3)
	assert_almost_eq(lucian.damage_dealt_scale, 1.3, 0.0001)
	var enemy := _enemy()
	for source: StringName in [&"basic", &"lightslinger", &"q", &"r", &"hextech_gunblade", &"smite"]:
		assert_almost_eq(enemy.take_damage(lucian.make_damage(100.0, DamageInfo.Type.TRUE, source)), 130.0, 0.01, String(source))
	assert_almost_eq(enemy.take_damage(lucian.roll_attack(1.0, &"basic")), lucian.stats.ad * 1.3, 0.01, "an attack, before armor")
	assert_almost_eq(_enemy().take_damage(_lucian(2, Difficulty.HARD).make_damage(100.0, DamageInfo.Type.TRUE, &"q")), 110.0, 0.01, "Hard: 5% a stack")
	assert_almost_eq(_enemy().take_damage(_lucian(0).make_damage(100.0, DamageInfo.Type.TRUE, &"q")), 100.0, 0.01, "no stack")


func test_the_burns_lucian_applies_tick_harder_too() -> void:
	var lucian := _lucian(5)
	var enemy := _enemy()
	enemy.add_burn(&"test", 20.0, 1.0, DamageInfo.Type.TRUE, lucian)
	await wait_physics_frames(roundi(DamageOverTime.TICK * Engine.physics_ticks_per_second) + 2)
	assert_almost_eq(enemy.max_hp - enemy.hp, 20.0 * DamageOverTime.TICK * 1.5, 0.01, "one tick, half as much again")


func test_another_attackers_hit_is_not_raised() -> void:
	_lucian(5)
	var enemy := _enemy()
	assert_almost_eq(enemy.take_damage(DamageInfo.create(100.0, DamageInfo.Type.TRUE, &"test")), 100.0, 0.01, "nobody's hit")
	var senna := Node2D.new()
	add_child_autofree(senna)
	assert_almost_eq(enemy.take_damage(DamageInfo.create(100.0, DamageInfo.Type.TRUE, &"senna", senna)), 100.0, 0.01, "an ally's hit")


func test_set_resolve_changes_both_shares_at_once() -> void:
	var lucian := _lucian(4)
	lucian.set_resolve(0)
	assert_eq([lucian.resolve, lucian.damage_dealt_scale, lucian.damage_taken_scale], [0, 1.0, 1.0])
	lucian.set_resolve(2, 6)
	assert_eq([lucian.resolve, lucian.defeats], [2, 6])
	assert_almost_eq(lucian.damage_dealt_scale, 1.2, 0.0001)
	assert_almost_eq(lucian.damage_taken_scale, 0.8, 0.0001)


# --- In a stage ----------------------------------------------------------------


## Stage `act`-`number` of a save that fell there `defeats` times, on `level`.
func _stage(act: int, number: int, defeats := 0, level := Difficulty.NORMAL) -> Stage:
	var save := SaveGame.instance()
	save.difficulty = level
	for i in defeats:
		save.record_defeat(Journey.stage_id(act, number))
	return await _run(StageSetup.for_stage(save, act, number))


func _run(setup: StageSetup) -> Stage:
	var stage: Stage = load(STAGE_SCENE).instantiate()
	stage.setup(setup)
	add_child_autofree(stage)
	await wait_process_frames(2)
	return stage


## The result panel has no Resolve line.
func _assert_no_line(stage: Stage, why := "") -> void:
	for label: Label in stage.result.find_children("*", "Label", true, false):
		assert_false(label.text.begins_with("Resolve"), "%s: %s" % [why, label.text])


## The texts on the stage's result panel.
func _result_texts(stage: Stage) -> Array:
	return stage.result.find_children("*", "Label", true, false).map(func(label: Label) -> String: return label.text)


func test_a_stage_gives_lucian_its_stacks() -> void:
	var stage: Stage = await _stage(2, 1, 3)
	assert_eq([stage.run.resolve, stage.lucian.resolve, stage.lucian.defeats], [3, 3, 3])
	assert_almost_eq(stage.lucian.damage_dealt_scale, 1.3, 0.0001)
	assert_almost_eq(stage.lucian.damage_taken_scale, 0.7, 0.0001)
	var enemy := stage.spawn_enemy(&"melee_minion", stage.lucian.global_position + Vector2(300, 0))
	assert_almost_eq(enemy.take_damage(stage.lucian.make_damage(100.0, DamageInfo.Type.TRUE, &"q")), 130.0, 0.01)
	assert_almost_eq(stage.stats.damage_dealt, 130.0, 0.01, "the result counts what the hit took")


func test_with_the_setting_off_the_stacks_stay_out_of_the_fight() -> void:
	GameSettings.instance().set_value(Resolve.SETTING, false)
	var stage: Stage = await _stage(2, 1, 3)
	assert_eq(stage.run.resolve, 3, "the stage still has them")
	assert_eq([stage.lucian.resolve, stage.lucian.damage_dealt_scale, stage.lucian.damage_taken_scale], [0, 1.0, 1.0])


func test_the_setting_changed_in_a_stage_applies_at_once() -> void:
	var stage: Stage = await _stage(2, 1, 2)
	GameSettings.instance().set_value(Resolve.SETTING, false)
	assert_eq([stage.lucian.resolve, stage.lucian.damage_dealt_scale, stage.lucian.damage_taken_scale], [0, 1.0, 1.0])
	GameSettings.instance().set_value(Resolve.SETTING, true)
	assert_eq(stage.lucian.resolve, 2)
	assert_almost_eq(stage.lucian.damage_dealt_scale, 1.2, 0.0001)
	assert_almost_eq(stage.lucian.damage_taken_scale, 0.8, 0.0001)


func test_the_defeated_screen_counts_the_defeat_once() -> void:
	var stage: Stage = await _stage(2, 1)
	assert_eq(stage.lucian.resolve, 0, "the first try has none")
	stage.show_result(false)
	assert_eq(stage.result.title.text, "DEFEATED")
	assert_eq(SaveGame.instance().defeats, {"2-1": 1})
	stage.show_result(false)
	assert_eq(SaveGame.instance().defeats_on("2-1"), 1, "one defeat a try")
	assert_false(SaveGame.instance().slot_exists(1), "the stage-done save writes it")


func test_dying_counts_the_defeat_and_leaving_does_not() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.leave()
	assert_true(SaveGame.instance().defeats.is_empty(), "Leave is not a defeat")
	stage.lucian.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	# Frames, not seconds: the result pauses the tree, and GUT's timer with it.
	var give_up := Time.get_ticks_msec() + int((Lucian.DEATH_FADE + 3.0) * 1000.0)
	while not stage.result.visible and Time.get_ticks_msec() < give_up:
		await wait_process_frames(1)
	assert_eq(SaveGame.instance().defeats, {"2-1": 1})


func test_a_clear_counts_no_defeat() -> void:
	var stage: Stage = await _stage(2, 1, 2)
	stage.show_result(true)
	assert_eq(SaveGame.instance().defeats_on("2-1"), 2, "they go when the clear is saved")
	_assert_no_line(stage, "a clear")


func test_the_defeat_line_says_what_the_next_try_gets() -> void:
	assert_eq(Resolve.defeat_line(3, Difficulty.NORMAL), "Resolve 3 / 5: +30% damage, -30% damage taken on your next try")
	assert_eq(Resolve.defeat_line(1, Difficulty.EASY), "Resolve 1 / 5: +10% damage, -10% damage taken on your next try")
	assert_eq(Resolve.defeat_line(5, Difficulty.HARD), "Resolve 5 / 5: +25% damage, -25% damage taken on your next try")
	assert_eq(Resolve.defeat_line(0, Difficulty.NORMAL), "", "no stack, no line")


func test_the_defeated_screen_names_the_resolve_of_the_next_try() -> void:
	var stage: Stage = await _stage(2, 1, 2)
	stage.show_result(false)
	assert_has(_result_texts(stage), "Resolve 3 / 5: +30% damage, -30% damage taken on your next try")


func test_the_line_stops_at_5_stacks() -> void:
	var stage: Stage = await _stage(2, 1, 7, Difficulty.HARD)
	stage.show_result(false)
	assert_eq(SaveGame.instance().defeats_on("2-1"), 8)
	assert_has(_result_texts(stage), "Resolve 5 / 5: +25% damage, -25% damage taken on your next try")


func test_losing_the_tutorial_counts_like_any_stage() -> void:
	var stage: Stage = await _stage(1, 1)
	assert_true(stage.run.tutorial)
	stage.show_result(false)
	assert_eq(stage.result.title.text, "GAME OVER")
	assert_eq(SaveGame.instance().defeats, {"1-1": 1})
	assert_has(_result_texts(stage), "Resolve 1 / 5: +10% damage, -10% damage taken on your next try")


func test_no_line_with_the_setting_off_but_the_defeat_is_counted() -> void:
	GameSettings.instance().set_value(Resolve.SETTING, false)
	var stage: Stage = await _stage(2, 1, 1)
	stage.show_result(false)
	assert_eq(SaveGame.instance().defeats_on("2-1"), 2)
	_assert_no_line(stage, "the setting is off")


func test_no_line_on_extreme_but_the_defeat_is_counted() -> void:
	var stage: Stage = await _stage(2, 1, 1, Difficulty.EXTREME)
	assert_eq([stage.lucian.resolve, stage.lucian.damage_dealt_scale], [0, 1.0])
	assert_almost_eq(stage.lucian.damage_taken_scale, Difficulty.scale(Difficulty.EXTREME), 0.0001)
	stage.show_result(false)
	assert_eq(SaveGame.instance().defeats_on("2-1"), 2)
	_assert_no_line(stage, "Extreme")


func test_a_replay_of_a_cleared_stage_has_no_resolve_and_counts_no_defeat() -> void:
	SaveGame.instance().record_defeat("2-1")
	SaveGame.instance().set_cleared(["1-1", "2-1"] as Array[String])
	var stage: Stage = await _stage(2, 1)
	assert_eq([stage.run.resolve, stage.lucian.resolve], [0, 0])
	stage.show_result(false)
	assert_true(SaveGame.instance().defeats.is_empty())
	_assert_no_line(stage, "a replay")


func test_endless_is_untouched() -> void:
	var save := SaveGame.instance()
	save.set_cleared(Journey.all_stage_ids(Journey.ENDLESS_ACT))
	var stage: Stage = await _run(StageSetup.for_endless(save, 3, RandomNumberGenerator.new()))
	assert_eq([stage.lucian.resolve, stage.lucian.damage_dealt_scale, stage.lucian.damage_taken_scale], [0, 1.0, 1.0])
	stage.show_result(false)
	assert_eq(stage.result.title.text, EndlessDirector.RUN_OVER)
	assert_true(save.defeats.is_empty(), "a run that ends is no defeat")
	_assert_no_line(stage, "Endless")


func test_training_is_untouched() -> void:
	var stage: Stage = await _run(StageSetup.from_save(SaveGame.instance()))
	assert_eq([stage.lucian.resolve, stage.lucian.damage_dealt_scale, stage.lucian.damage_taken_scale], [0, 1.0, 1.0])
	stage.show_result(false)
	assert_true(SaveGame.instance().defeats.is_empty())
	_assert_no_line(stage, "Training")
