extends GutTest


func test_the_wave_text_follows_the_runner() -> void:
	var runner := WaveRunner.new(WavePlan.waves("2-2"))
	var info := StageInfo.new()
	add_child_autofree(info)
	info.setup("Stage 2-2 · The Sentinels", runner)
	info.refresh()
	assert_true(info.skip_button.visible)
	assert_eq(info.timer_label.text, "Wave 1 in 0:05")
	runner.skip()
	for i in 10:
		runner.tick(WaveRunner.GROUP_GAP)
	info.refresh()
	assert_eq(info.wave_label.text, "Wave 1/3")
	assert_eq(info.enemies_label.text, "Enemies: 13")
	assert_false(info.skip_button.visible)


func test_training_shows_only_its_name() -> void:
	var info := StageInfo.new()
	add_child_autofree(info)
	info.setup("Training", null)
	info.refresh()
	assert_eq(info.name_label.text, "Training")
	assert_false(info.wave_label.visible)
	assert_false(info.skip_button.visible)


func test_the_stage_info_fits_training() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)
	hud.setup(lucian, Wallet.new())
	await wait_process_frames(2)
	var info := hud.stage_info
	assert_almost_eq(info.size.x, info.get_combined_minimum_size().x, 1.0, "no room left for the hidden Skip")


func test_skip_on_the_hud_starts_the_wave() -> void:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 2, 1))
	add_child_autofree(stage)
	await wait_physics_frames(2)
	stage.hud.stage_info.skip_button.pressed.emit()
	assert_eq(stage.runner.state, WaveRunner.State.FIGHT)


func test_the_radar_maps_the_world_onto_itself() -> void:
	var radar := Radar.new()
	add_child_autofree(radar)
	radar.setup(Rect2(0, 0, 5200, 3200), null)
	assert_eq(radar.size, Vector2(Radar.WIDTH, 160))
	assert_eq(radar.to_radar(Vector2(2600, 1600)), Vector2(130, 80))
	assert_eq(radar.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_the_radar_sits_inside_the_bottom_right_corner() -> void:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 1, 1))
	add_child_autofree(stage)
	await wait_process_frames(2)
	var radar := stage.hud.radar
	var screen := (radar.get_parent() as Control).size
	assert_eq(radar.size, Vector2(Radar.WIDTH, 160))
	assert_almost_eq(radar.position + radar.size, screen - Vector2.ONE * Hud.MARGIN, Vector2.ONE)


func test_elites_are_bigger_dots_and_bosses_skulls() -> void:
	assert_gt(Radar.dot_size(&"elite"), Radar.dot_size(&"normal"))
	assert_eq(Radar.dot_size(&"boss"), Radar.SKULL_SIZE)


func test_the_boss_bar_shows_only_while_a_boss_lives() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	var bar := BossBar.new()
	add_child_autofree(bar)
	await wait_physics_frames(1)
	assert_false(bar.visible)
	var data := EnemyData.new()
	data.kind = &"boss"
	data.display_name = "Test Boss"
	data.max_hp = 1000.0
	var boss := Minion.new()
	boss.setup(data, 1, 1, lucian)
	boss.position = Vector2(3000, 0)
	add_child_autofree(boss)
	await wait_physics_frames(6)
	assert_true(bar.visible)
	boss.take_damage(DamageInfo.create(5000.0, DamageInfo.Type.TRUE, &"test"))
	await wait_physics_frames(6)
	assert_false(bar.visible)


func test_fps_sits_top_left() -> void:
	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)
	assert_eq(hud._fps_label.anchor_left, 0.0)
	assert_eq(hud._fps_label.anchor_right, 0.0)
