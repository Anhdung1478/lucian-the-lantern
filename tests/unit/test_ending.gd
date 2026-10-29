extends GutTest
## The ending: Thresh falls in 6-5, SennaFreed plays (skippable), the stage
## pays and clears, "The story is complete" on the first clear, and Game shows
## TheEndScreen on that first clear only.

const PREFIX := "user://test_ending_save_slot_"

var game: Game
var _prefix := ""


func before_each() -> void:
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new(PREFIX)
	_prefix = SaveGame.instance().prefix
	SaveGame.instance().reset()
	_remove_slot_files()
	game = load("res://src/main/game.tscn").instantiate()
	game.quit_game = func() -> void: pass
	add_child_autofree(game)


func after_each() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	_remove_slot_files()
	SaveGame.instance().prefix = _prefix


func _remove_slot_files() -> void:
	for file in [SaveGame.instance().path(1), SaveGame.instance().backup_path(1)]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func _lethal() -> DamageInfo:
	return DamageInfo.create(999999.0, DamageInfo.Type.TRUE, &"test")


## 6-5 played through Game, Thresh in Phase 2 and about to fall.
func _fight() -> Stage:
	game.start_stage(StageSetup.for_stage(SaveGame.instance(), 6, 5))
	await wait_process_frames(2)
	var stage := game.screen as Stage
	stage.lucian.invulnerable = true
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	var boss := stage.boss_unit as ThreshFinal
	boss._attack_left = 1000.0
	for id: StringName in boss._cooldowns:
		boss._cooldowns[id] = 1000.0
	boss.move_speed = 0.0
	await wait_physics_frames(1)
	boss.take_damage(_lethal())
	await wait_physics_frames(2)
	boss._rise_left = 0.0
	await wait_physics_frames(1)
	return stage


## Thresh falls; the cutscene is skipped; the result is up.
func _win(stage: Stage) -> void:
	stage.boss_unit.take_damage(_lethal())
	await wait_physics_frames(3)
	assert_is(stage.cutscene, SennaFreed)
	stage.cutscene.skip()
	await wait_physics_frames(2)


func test_the_fall_plays_senna_freed_and_the_stage_waits_for_it() -> void:
	var stage := await _fight()
	stage.boss_unit.take_damage(_lethal())
	await wait_physics_frames(3)
	assert_is(stage.cutscene, SennaFreed)
	assert_false(stage.result.visible, "not cleared until the scene ends")
	assert_not_null(stage.boss_unit, "he is still there for the scene")
	assert_eq(stage.collected[Essences.BLUE], 0)
	stage.cutscene.skip()
	await wait_physics_frames(2)
	assert_null(stage.cutscene)
	assert_true(stage.result.visible)
	assert_eq(stage.collected[Essences.BLUE], KillRewards.BOSS_BLUE)


func test_skipping_clears_and_pays_20_then_4_on_a_replay() -> void:
	var stage := await _fight()
	await _win(stage)
	assert_eq(stage.collected[Essences.PURPLE], 20)
	assert_has(stage.reward_lines, "Senna is free")
	assert_has(stage.reward_lines, "The story is complete")
	assert_true(stage.result.cleared)
	SaveGame.instance().finish_stage(&"cleared", "6-5")
	var replay := await _fight()
	await _win(replay)
	assert_eq(replay.collected[Essences.PURPLE], 4)
	assert_has(replay.reward_lines, "Senna is free")
	assert_does_not_have(replay.reward_lines, "The story is complete")


## The visual pass: Thresh dissolved, but his Phase 2 aura (drawn on the
## unit, not its art) and his empty health bar stayed floating over the spot
## while Senna spoke. The scene runs at 8x speed to her line.
func test_thresh_dissolves_whole_aura_and_bar_too() -> void:
	var stage := await _fight()
	var thresh := stage.boss_unit as ThreshFinal
	stage.boss_unit.take_damage(_lethal())
	await wait_physics_frames(3)
	var scene := stage.cutscene as SennaFreed
	assert_not_null(scene)
	assert_true(thresh.has_aura(), "Phase 2: the aura is on him")
	Engine.time_scale = 8.0
	for frame in 600:
		if scene._speaker.text == "Senna":
			break
		await wait_process_frames(1)
	Engine.time_scale = 1.0
	assert_eq(scene._speaker.text, "Senna", "her line, after he dissolved")
	assert_almost_eq(thresh.modulate.a, 0.0, 0.01, "the unit, aura and bar with it")
	scene.skip()


## The final review: the souls freed at his fall froze with the world (their
## fade is a tween of their own, under the frozen $World) and stood at full
## colour through the scene. They rise and fade as it begins: gone before
## its first line. The scene runs at 8x speed to that line.
func test_the_souls_freed_at_the_fall_are_gone_before_the_first_caption() -> void:
	var stage := await _fight()
	var thresh := stage.boss_unit as ThreshFinal
	thresh._drop_lantern(stage.lucian.global_position + Vector2(250, 0))
	await wait_physics_frames(2)
	var souls := get_tree().get_nodes_in_group(&"enemies").filter(func(node: Node) -> bool:
		return (node as EnemyUnit).summoned and (node as EnemyUnit).summoner == thresh)
	assert_eq(souls.size(), 3, "his souls are out")
	thresh.take_damage(_lethal())
	await wait_physics_frames(3)
	var scene := stage.cutscene as SennaFreed
	assert_not_null(scene)
	if scene == null:
		return
	Engine.time_scale = 8.0
	for frame in 600:
		if scene._caption.text != "":
			break
		await wait_process_frames(1)
	Engine.time_scale = 1.0
	assert_eq(scene._caption.text, "It ends here.", "the first line")
	for soul: Variant in souls:
		assert_true(not is_instance_valid(soul) or (soul as Node2D).modulate.a < 0.05, "freed: risen and faded")
	scene.skip()


## The final review: with Thresh gone before the scene ends (not reachable
## in play today), the stage still clears and pays its purple.
func test_the_ending_clears_the_stage_even_with_thresh_gone() -> void:
	var stage := await _fight()
	var thresh := stage.boss_unit
	thresh.take_damage(_lethal())
	await wait_physics_frames(3)
	assert_is(stage.cutscene, SennaFreed)
	thresh.queue_free()
	await wait_physics_frames(1)
	stage.cutscene.skip()
	await wait_physics_frames(2)
	assert_true(stage.result.visible, "the result is up")
	assert_true(stage.result.cleared)
	assert_has(stage.reward_lines, "Senna is free")
	assert_eq(stage.collected[Essences.PURPLE], 20)


func test_a_debug_thresh_plays_no_cutscene() -> void:
	game.start_stage(StageSetup.new())
	await wait_process_frames(2)
	var stage := game.screen as Stage
	stage.lucian.invulnerable = true
	var thresh := stage.spawn_enemy(&"thresh_final", stage.lucian.global_position + Vector2(700, 0)) as ThreshFinal
	thresh._attack_left = 1000.0
	thresh.move_speed = 0.0
	await wait_physics_frames(1)
	thresh.take_damage(_lethal())
	await wait_physics_frames(2)
	thresh._rise_left = 0.0
	await wait_physics_frames(1)
	thresh.take_damage(_lethal())
	await wait_physics_frames(3)
	assert_null(stage.cutscene)
	assert_false(is_instance_valid(thresh))


func test_the_stage_ending_moment_drops_no_loot() -> void:
	var stage := await _fight()
	await _win(stage)
	assert_eq(stage.get_node("World").find_children("*", "LootDrop", true, false).size(), 0)


# --- Game and TheEndScreen -----------------------------------------------------


func test_the_first_clear_shows_the_end_screen_with_the_play_time() -> void:
	SaveGame.instance().play_time = 3725.0
	var stage := await _fight()
	await _win(stage)
	stage.result.chosen.emit(&"main")
	await wait_process_frames(3)
	assert_is(game.screen, TheEndScreen)
	var end := game.screen as TheEndScreen
	assert_eq(end.time_label.text, "Story time: 1:02:05")
	assert_eq(end.credit_labels.size(), 3)
	assert_eq(end.credit_labels[2].text, "A fan game. League of Legends characters belong to Riot Games.")
	end.continue_button.pressed.emit()
	await wait_process_frames(3)
	assert_is(game.screen, MainScreen)
	assert_eq((game.screen as MainScreen).focus_act, 6)


func test_continue_after_retry_plays_6_5_again() -> void:
	var stage := await _fight()
	await _win(stage)
	stage.result.chosen.emit(&"retry")
	await wait_process_frames(3)
	assert_is(game.screen, TheEndScreen)
	(game.screen as TheEndScreen).continue_button.pressed.emit()
	await wait_process_frames(3)
	assert_is(game.screen, Stage)
	assert_eq((game.screen as Stage).run.stage_id, "6-5")


func test_a_replay_goes_straight_where_the_button_said() -> void:
	SaveGame.instance().set_cleared(["6-5"] as Array[String])
	game.start_stage(StageSetup.for_stage(SaveGame.instance(), 6, 5))
	await wait_process_frames(2)
	var stage := game.screen as Stage
	stage.show_result(true)
	stage.result.chosen.emit(&"main")
	await wait_process_frames(3)
	assert_is(game.screen, MainScreen, "no end screen on a replay")


func test_a_failed_save_still_shows_the_end_screen() -> void:
	var stage := await _fight()
	await _win(stage)
	SaveGame.instance().prefix = "user://no_such_dir/test_ending_"
	stage.result.chosen.emit(&"retry")
	await wait_process_frames(3)
	assert_is(game.screen, TheEndScreen)
	(game.screen as TheEndScreen).continue_button.pressed.emit()
	await wait_process_frames(3)
	assert_is(game.screen, MainScreen, "retry goes to the main screen when the save failed")


func test_esc_does_nothing_on_the_end_screen() -> void:
	var stage := await _fight()
	await _win(stage)
	stage.result.chosen.emit(&"main")
	await wait_process_frames(3)
	var end := game.screen as TheEndScreen
	var esc := InputEventAction.new()
	esc.action = &"open_menu"
	esc.pressed = true
	Input.parse_input_event(esc)
	await wait_process_frames(2)
	assert_eq(game.screen, end)
	assert_false(game.prompt.is_open())
	assert_false(get_tree().paused)


func test_play_time_text() -> void:
	assert_eq(TheEndScreen.story_time(0.0), "0:00:00")
	assert_eq(TheEndScreen.story_time(3725.9), "1:02:05")
	assert_eq(TheEndScreen.story_time(36000.0), "10:00:00")
