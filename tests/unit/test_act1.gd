extends GutTest

var lucian: Lucian


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_act1_save_slot_")
	SaveGame.instance().reset()
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func after_each() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0


func _thresh(at: Vector2) -> Thresh:
	var thresh := Thresh.new()
	thresh.setup(load("res://data/enemies/thresh_1.tres"), 1, 1, lucian)
	thresh.position = at
	add_child_autofree(thresh)
	return thresh


func test_the_hook_pulls_lucian_in() -> void:
	lucian.global_position = Vector2(700, 0)
	var thresh := _thresh(Vector2.ZERO)
	await wait_physics_frames(1)
	thresh.death_sentence()
	await wait_seconds(Thresh.HOOK_WARN + 0.9)
	assert_lt(lucian.global_position.distance_to(thresh.global_position), 260.0)


func test_banshees_veil_blocks_the_hook_and_its_pull() -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"banshees_veil"))
	lucian.global_position = Vector2(700, 0)
	var thresh := _thresh(Vector2.ZERO)
	await wait_physics_frames(1)
	thresh.death_sentence()
	await wait_seconds(Thresh.HOOK_WARN + 0.9)
	assert_gt(lucian.global_position.x, 650.0)


func test_flay_pushes_lucian_away() -> void:
	lucian.global_position = Vector2(200, 0)
	var thresh := _thresh(Vector2.ZERO)
	await wait_physics_frames(1)
	thresh.flay()
	await wait_seconds(Thresh.FLAY_WARN + 0.4)
	assert_gt(lucian.global_position.distance_to(thresh.global_position), 380.0)


func test_the_fight_stops_at_half_health() -> void:
	var thresh := _thresh(Vector2(2000, 0))
	watch_signals(thresh)
	thresh.take_damage(DamageInfo.create(2000.0, DamageInfo.Type.TRUE, &"test"))
	thresh.take_damage(DamageInfo.create(500.0, DamageInfo.Type.TRUE, &"test"))
	assert_signal_emit_count(thresh, "phase_ended", 1)
	assert_almost_eq(thresh.hp, thresh.max_hp * Thresh.PHASE_END, 0.01)
	assert_true(thresh.is_alive())


func test_senna_shoots_the_nearest_enemy() -> void:
	var senna := Senna.new()
	senna.lucian = lucian
	add_child_autofree(senna)
	var dummy: TrainingDummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	dummy.position = Vector2(600, 0)
	add_child_autofree(dummy)
	await wait_seconds(Senna.INTERVAL + 0.6)
	assert_lt(dummy.hp, dummy.max_hp)
	assert_true(senna.is_in_group(&"allies"))
	assert_false(senna.is_in_group(&"enemies"))


func test_a_tip_shows_once_and_later_tips_wait_their_turn() -> void:
	var tips := TipBanner.new()
	add_child_autofree(tips)
	tips.show_tip(&"move", "Move")
	tips.show_tip(&"attack", "Attack")
	tips.show_tip(&"move", "Move again")
	tips._process(0.0)
	assert_true(tips.visible)
	assert_eq(tips.label.text, "Move")
	tips._process(TipBanner.TIME - 1.0)
	assert_eq(tips.label.text, "Move", "the next tip waits")
	tips._process(1.0)
	assert_false(tips.visible)
	tips._process(0.0)
	assert_true(tips.visible)
	assert_eq(tips.label.text, "Attack")
	tips._process(TipBanner.TIME)
	tips._process(0.0)
	assert_false(tips.visible, "a second tip with the same id adds nothing")


func _act1_stage() -> Stage:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 1, 1))
	add_child_autofree(stage)
	await wait_physics_frames(2)
	stage.lucian.invulnerable = true
	return stage


func test_the_first_play_is_the_tutorial() -> void:
	var stage: Stage = await _act1_stage()
	assert_not_null(stage.senna)
	assert_true(stage.lucian.one_gun)
	assert_eq(stage.lucian.next_gun(), LucianVisuals.Gun.LEFT)
	assert_eq(stage.lucian.next_gun(), LucianVisuals.Gun.LEFT)
	assert_eq(stage.runner.total_waves(), 3)


func test_a_replay_has_no_senna_and_no_thresh() -> void:
	SaveGame.instance().set_cleared(["1-1"] as Array[String])
	var stage: Stage = await _act1_stage()
	assert_null(stage.senna)
	assert_eq(stage.runner.total_waves(), 2)


func test_half_health_plays_the_cutscene_and_skip_clears_the_stage() -> void:
	var stage: Stage = await _act1_stage()
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	await wait_physics_frames(1)
	assert_is(stage.boss_unit, Thresh)
	stage.boss_unit.take_damage(DamageInfo.create(5000.0, DamageInfo.Type.TRUE, &"test"))
	await wait_physics_frames(2)
	assert_not_null(stage.cutscene)
	stage.cutscene.skip_button.pressed.emit()
	await wait_physics_frames(2)
	assert_eq(stage.result.title.text, "STAGE CLEARED")
	assert_eq(stage.collected[Essences.PURPLE], 10)
	assert_true("thresh_1" in SaveGame.instance().bosses)


func test_the_tutorial_tips_come_with_what_they_teach() -> void:
	var stage: Stage = await _act1_stage()
	var tips := stage.hud.tips
	assert_true(tips.visible)
	assert_string_contains(tips.label.text, "to move")
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	tips._process(TipBanner.TIME)
	tips._process(0.0)
	assert_string_contains(tips.label.text, "Thresh's hook")


func test_a_replay_has_no_tips() -> void:
	SaveGame.instance().set_cleared(["1-1"] as Array[String])
	var stage: Stage = await _act1_stage()
	assert_false(stage.hud.tips.visible)


## Act 1 with Thresh just brought to half HP: the cutscene is playing.
func _start_cutscene() -> Stage:
	var stage: Stage = await _act1_stage()
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	await wait_physics_frames(1)
	stage.boss_unit.take_damage(DamageInfo.create(5000.0, DamageInfo.Type.TRUE, &"test"))
	await wait_physics_frames(1)
	return stage


func test_the_cutscene_freezes_the_stage() -> void:
	var stage: Stage = await _start_cutscene()
	assert_eq(stage.get_node("World").process_mode, Node.PROCESS_MODE_DISABLED)
	assert_false(stage.hud.visible)
	assert_true(stage.screens.locked)
	assert_true(stage.lucian.invulnerable)
	stage.cutscene.skip_button.pressed.emit()
	assert_eq(stage.get_node("World").process_mode, Node.PROCESS_MODE_INHERIT)


func test_the_cutscene_waits_while_the_game_is_paused() -> void:
	var stage: Stage = await _start_cutscene()
	assert_true(stage.cutscene.can_process(), "Space, clicks and Skip reach it")
	# The "Save before leaving?" prompt pauses the tree.
	get_tree().paused = true
	var camera_at := stage.camera.global_position
	# A SceneTreeTimer: GUT's own waits stop with the tree.
	await get_tree().create_timer(1.0).timeout
	assert_false(stage.cutscene.can_process())
	assert_eq(stage.camera.global_position, camera_at, "the first pan waits")
	assert_eq(stage.cutscene._caption.text, "", "no caption yet")
	get_tree().paused = false
	stage.cutscene.skip()


func test_skip_takes_senna_and_thresh_away_with_the_rewards() -> void:
	var stage: Stage = await _start_cutscene()
	var thresh := stage.boss_unit
	var senna := stage.senna
	stage.cutscene.skip_button.pressed.emit()
	assert_false(thresh.is_in_group(&"enemies"))
	await wait_physics_frames(2)
	assert_false(is_instance_valid(thresh))
	assert_false(is_instance_valid(senna))
	assert_eq(stage.collected[Essences.BLUE], KillRewards.BOSS_BLUE)
	assert_eq(stage.collected[Essences.ORANGE], KillRewards.BOSS_ORANGE)
	assert_has(stage.reward_lines, "Lucian takes Senna's gun: two guns from now on")
	assert_has(stage.reward_lines, "E – Relentless Pursuit is free in the Evolution Tree")


func test_after_the_cutscene_every_wave_counts_as_cleared() -> void:
	var stage: Stage = await _act1_stage()
	for wave in 2:
		stage.skip_break()
		for i in 20:
			stage.runner.tick(WaveRunner.GROUP_GAP)
		for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
			enemy.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
		await wait_physics_frames(1)
	stage.skip_break()
	stage.runner.tick(0.1)
	await wait_physics_frames(1)
	stage.boss_unit.take_damage(DamageInfo.create(5000.0, DamageInfo.Type.TRUE, &"test"))
	# The stage reacts to his half HP after the frame's physics.
	await wait_physics_frames(1)
	stage.cutscene.skip()
	assert_eq(stage.runner.waves_done(), 3)
	assert_eq(stage.runner.alive(), 0)
	assert_true(stage.result.visible)


func test_the_cutscene_plays_to_its_end() -> void:
	var stage: Stage = await _start_cutscene()
	var thresh_at := stage.boss_unit.global_position
	Engine.time_scale = 20.0
	# Frames, not seconds: the result pauses the tree, and GUT's timer with it.
	var give_up := Time.get_ticks_msec() + 10000
	while not stage.result.visible and Time.get_ticks_msec() < give_up:
		await wait_process_frames(1)
	assert_eq(stage.result.title.text, "STAGE CLEARED")
	assert_null(stage.senna)
	assert_lt(stage.lucian.global_position.distance_to(thresh_at), 250.0, "Lucian walked to where Senna fell")
	assert_eq(stage.collected[Essences.PURPLE], 10)


func test_the_cutscene_frames_the_hook_then_thresh() -> void:
	var stage: Stage = await _start_cutscene()
	var cutscene := stage.cutscene
	var thresh_at := stage.boss_unit.global_position
	var senna_at := stage.senna.global_position
	var in_caption := func() -> bool: return cutscene._in_caption
	# The first caption comes once the pan has ended.
	assert_true(await wait_until(in_caption, 3.0))
	assert_almost_eq(stage.camera.global_position, (thresh_at + senna_at) * 0.5, Vector2.ONE * 2.0, "both ends of the hook in view")
	# Space moves the captions on: Thresh's line, then "SENNA!" after the hook.
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	get_viewport().push_input(space)
	assert_true(await wait_until(in_caption, 3.0))
	assert_eq(cutscene._caption.text, "SENNA!")
	get_viewport().push_input(space)
	# Her pull is the step after "SENNA!"; the soul's flight comes next.
	var pull: Tween = cutscene._step
	assert_true(await wait_until(func() -> bool: return cutscene._step != pull, 3.0))
	assert_almost_eq(stage.camera.global_position, thresh_at, Vector2.ONE * 2.0, "on Thresh as she is pulled in")
	cutscene.skip()


func test_thresh_essences_rise_where_he_sank_and_the_purple_over_lucian() -> void:
	var stage: Stage = await _start_cutscene()
	var thresh_x := stage.boss_unit.global_position.x
	var lucian_x := stage.lucian.global_position.x
	stage.cutscene.skip()
	var popups := {}
	for node in stage.damage_numbers.get_children():
		if node is FloatingText:
			popups[(node as FloatingText).text] = (node as FloatingText).position
	assert_almost_eq(popups["+%d" % KillRewards.BOSS_BLUE].x, thresh_x, 1.0)
	assert_almost_eq(popups["+10"].x, lucian_x, 1.0, "not on top of the blue")


func test_no_cutscene_or_boss_purple_after_a_defeat() -> void:
	var stage: Stage = await _act1_stage()
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	await wait_process_frames(1)
	stage.lucian.invulnerable = false
	stage.lucian.take_damage(DamageInfo.create(999999.0, DamageInfo.Type.TRUE, &"test"))
	assert_true(stage.lucian.dead)
	stage.boss_unit.take_damage(DamageInfo.create(5000.0, DamageInfo.Type.TRUE, &"test"))
	await wait_process_frames(2)
	assert_null(stage.cutscene)
	assert_true(SaveGame.instance().bosses.is_empty())
