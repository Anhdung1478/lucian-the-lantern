extends GutTest
## The next-wave preview: shown only while a break counts down, one cell per
## enemy, and clear of the Skip button, the boss bar's place and the tips.


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_wave_preview_save_slot_")


func _preview(runner: WaveRunner) -> WavePreview:
	var preview := WavePreview.new()
	add_child_autofree(preview)
	preview.setup(runner)
	return preview


func test_it_shows_the_next_wave_in_a_break_and_not_in_a_wave() -> void:
	var runner := WaveRunner.new(WavePlan.waves("2-2"), &"test_boss")
	var preview := _preview(runner)
	assert_true(preview.visible, "the countdown before wave 1")
	assert_eq(preview.cells.size(), WavePlan.preview_rows(WavePlan.waves("2-2")[0]).size())
	runner.skip()
	preview.refresh()
	assert_false(preview.visible, "a wave")
	runner._skip_to(1)
	preview.refresh()
	assert_true(preview.visible, "a break")


func test_a_boss_wave_shows_the_boss_with_a_gold_rim_and_its_name() -> void:
	var runner := WaveRunner.new(WavePlan.waves("2-3"), &"akshan")
	runner._skip_to(WavePlan.waves("2-3").size())
	var preview := _preview(runner)
	assert_true(preview.visible)
	assert_eq(preview.cells.size(), 1)
	var rim: StyleBoxFlat = preview.cells[0].get_theme_stylebox(&"panel")
	assert_eq(rim.border_color, UiStyle.GOLD_COLOR)
	assert_eq(preview.cells[0].get_meta(&"hover_text"), "Akshan")


func test_a_hover_reaches_the_cells_and_a_click_falls_through() -> void:
	var preview := _preview(WaveRunner.new(WavePlan.waves("2-2")))
	assert_eq(preview.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(preview.cells[0].mouse_filter, Control.MOUSE_FILTER_PASS)
	assert_true(preview.cells[0].has_meta(&"hover_text"))


func test_it_hides_on_the_end_screen() -> void:
	var preview := _preview(WaveRunner.new(WavePlan.waves("2-2")))
	preview.suppressed = true
	preview.refresh()
	assert_false(preview.visible)


func test_training_and_a_cleared_stage_show_nothing() -> void:
	assert_false(_preview(null).visible, "Training has no waves")
	var runner := WaveRunner.new([[&"melee_minion"]])
	runner._skip_to(1)
	assert_false(_preview(runner).visible, "no wave is left")


func test_endless_says_the_kind_and_hides_for_the_modifier_pick() -> void:
	var runner := EndlessRunner.new(3)
	var preview := _preview(runner)
	assert_false(preview.visible, "a normal wave is not announced")
	runner._skip_to(EndlessPlan.MINI_BOSS_EVERY - 1)
	preview.refresh()
	assert_true(preview.visible)
	assert_eq(preview.cells.size(), 0)
	runner._skip_to(EndlessPlan.BOSS_EVERY - 1)
	runner.held = true
	preview.refresh()
	assert_false(preview.visible, "the modifier pick is open")
	runner.held = false
	preview.refresh()
	assert_true(preview.visible)


## It sits in the boss bar's place (no boss bar in a break) and ends above the
## tips, whatever the wave.
func test_it_clears_the_tips() -> void:
	for runner: WaveRunner in [WaveRunner.new(WavePlan.waves("1-1"), &"thresh_1"), WaveRunner.new(WavePlan.waves("2-2"))]:
		var preview := _preview(runner)
		await get_tree().process_frame
		assert_lt(Hud.BOSS_BAR_TOP + preview.get_combined_minimum_size().y, Hud.TIPS_TOP)
