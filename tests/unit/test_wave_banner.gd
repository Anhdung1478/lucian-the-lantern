extends GutTest
## The wave banner: what it says for a wave (lines), the boss or mini boss a
## wave brings (lead), its fade and slide, and that the stage shows it at
## each wave's start, on the HUD's layer and under the HUD's top rows.

## Journey.ENDLESS_MAPS: Jungle.
const JUNGLE := 3


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save or settings.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_wave_banner_save_slot_")
	if GameSettings._instance == null or GameSettings._instance.path == GameSettings.DEFAULT_PATH:
		GameSettings._instance = GameSettings.new("user://test_wave_banner_settings.json")


func after_each() -> void:
	get_tree().paused = false
	GameSettings.instance().set_value(&"quality", "high")


func _banner() -> WaveBanner:
	var banner := WaveBanner.new()
	add_child_autofree(banner)
	return banner


func _labels(banner: WaveBanner) -> Array[Label]:
	var found: Array[Label] = []
	for label in banner.find_children("*", "Label", true, false):
		found.append(label as Label)
	return found


func _texts(banner: WaveBanner) -> Array:
	return _labels(banner).map(func(label: Label) -> String: return label.text)


func _story(act: int, stage_number: int) -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, stage_number))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


func _endless() -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_endless(SaveGame.instance(), JUNGLE, RandomNumberGenerator.new()))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


# --- What it says -------------------------------------------------------------


func test_a_plain_wave_reads_its_number() -> void:
	assert_eq(WaveBanner.lines(3), PackedStringArray(["WAVE 3"]))
	assert_eq(WaveBanner.lines(23), PackedStringArray(["WAVE 23"]))
	assert_eq(WaveBanner.lines(3, &"", "Nobody"), PackedStringArray(["WAVE 3"]), "no lead, no name")


func test_a_mini_boss_wave_reads_mini_boss_over_its_name() -> void:
	assert_eq(WaveBanner.lines(4, &"mini_boss", "Infernal Drake"), PackedStringArray(["MINI BOSS", "Infernal Drake"]))


func test_the_boss_wave_reads_boss_over_its_name() -> void:
	assert_eq(WaveBanner.lines(3, &"boss", "Thresh"), PackedStringArray(["BOSS", "Thresh"]))


# --- The boss or mini boss a wave brings --------------------------------------


func test_the_lead_of_a_story_boss_wave_is_the_stages_boss() -> void:
	var runner := WaveRunner.new(WavePlan.waves("2-3"), &"akshan")
	runner.skip()
	assert_null(WaveBanner.lead(runner, "2-3"), "wave 1 brings none")
	runner.skip_to_boss()
	runner.tick(0.1)
	var lead := WaveBanner.lead(runner, "2-3")
	assert_eq(lead.id, &"akshan")
	assert_eq(lead.kind, &"boss")


func test_the_lead_of_a_story_wave_is_the_mini_boss_among_its_enemies() -> void:
	var runner := WaveRunner.new(WavePlan.waves("3-2"))
	runner.skip()
	assert_null(WaveBanner.lead(runner, "3-2"), "wave 1 brings none")
	runner.skip_to_last_wave()
	runner.tick(0.1)
	var lead := WaveBanner.lead(runner, "3-2")
	assert_eq(lead.id, WavePlan.INFERNAL_DRAKE)
	assert_eq(lead.kind, &"mini_boss")


func test_no_lead_before_the_first_wave_or_for_an_unknown_stage() -> void:
	var runner := WaveRunner.new(WavePlan.waves("3-2"))
	assert_null(WaveBanner.lead(runner, "3-2"), "wave 0")
	runner.skip()
	assert_null(WaveBanner.lead(runner, "9-9"))


func test_the_lead_of_an_endless_wave_is_the_runs_mini_boss_or_boss() -> void:
	var runner := EndlessRunner.new(7)
	runner.skip()
	assert_null(WaveBanner.lead(runner, EndlessPlan.STAGE_ID), "wave 1 brings none")
	runner._skip_to(4)
	runner.tick(0.1)
	assert_eq(runner.wave, 5)
	var mini := WaveBanner.lead(runner, EndlessPlan.STAGE_ID)
	assert_eq(mini.id, runner.mini_boss)
	assert_eq(mini.kind, &"mini_boss")
	runner._skip_to(9)
	runner.tick(0.1)
	assert_eq(runner.wave, 10)
	var boss := WaveBanner.lead(runner, EndlessPlan.STAGE_ID)
	assert_eq(boss.id, runner.boss)
	assert_eq(boss.kind, &"boss")


# --- The banner ---------------------------------------------------------------


func test_it_is_hidden_until_a_wave_is_announced() -> void:
	var banner := _banner()
	assert_false(banner.visible)
	banner.announce(3)
	assert_true(banner.visible)
	assert_eq(banner.shown, PackedStringArray(["WAVE 3"]))
	assert_eq(_texts(banner), ["WAVE 3"])


func test_it_fades_in_stays_and_fades_out() -> void:
	var banner := _banner()
	banner.announce(3)
	assert_eq(banner.modulate.a, 0.0)
	banner._process(WaveBanner.FADE * 0.5)
	assert_almost_eq(banner.modulate.a, 0.5, 0.01)
	banner._process(WaveBanner.FADE * 0.5)
	assert_almost_eq(banner.modulate.a, 1.0, 0.01)
	banner._process(WaveBanner.TIME - 0.01)
	assert_almost_eq(banner.modulate.a, 1.0, 0.01, "at full strength for TIME")
	banner._process(WaveBanner.FADE * 0.5)
	assert_between(banner.modulate.a, 0.4, 0.6)
	assert_true(banner.visible)
	banner._process(WaveBanner.FADE * 0.5 + 0.02)
	assert_false(banner.visible)
	assert_false(banner.is_processing())


func test_it_slides_down_into_place_as_it_fades_in() -> void:
	var banner := _banner()
	banner.announce(3)
	assert_almost_eq(banner.position.y, WaveBanner.TOP - WaveBanner.SLIDE, 0.01)
	banner._process(WaveBanner.FADE * 0.5)
	assert_between(banner.position.y, WaveBanner.TOP - WaveBanner.SLIDE + 0.1, WaveBanner.TOP - 0.1)
	banner._process(WaveBanner.FADE * 0.5)
	assert_almost_eq(banner.position.y, WaveBanner.TOP, 0.01)
	banner._process(WaveBanner.TIME * 0.5)
	assert_almost_eq(banner.position.y, WaveBanner.TOP, 0.01, "at rest until it goes")
	banner._process(WaveBanner.TIME * 0.5 + WaveBanner.FADE * 0.5)
	assert_between(banner.position.y, WaveBanner.TOP - WaveBanner.EXIT_RISE + 0.1, WaveBanner.TOP - 0.1, "it rises as it fades out")


func test_with_low_effects_it_only_fades() -> void:
	GameSettings.instance().set_value(&"quality", "low")
	var banner := _banner()
	banner.announce(3)
	assert_eq(banner.modulate.a, 0.0)
	assert_almost_eq(banner.position.y, WaveBanner.TOP, 0.01, "no slide")
	banner._process(WaveBanner.FADE * 0.5)
	assert_almost_eq(banner.modulate.a, 0.5, 0.01)
	assert_almost_eq(banner.position.y, WaveBanner.TOP, 0.01)


func test_a_new_wave_replaces_the_one_on_show() -> void:
	var banner := _banner()
	banner.announce(4)
	banner._process(WaveBanner.FADE + 0.5)
	banner.announce(5, &"mini_boss", "Ocean Drake")
	assert_eq(_texts(banner), ["MINI BOSS", "Ocean Drake"])
	assert_eq(banner.kind, &"mini_boss")
	assert_eq(banner.modulate.a, 0.0, "from its start")
	banner._process(WaveBanner.FADE + WaveBanner.TIME)
	assert_true(banner.visible, "its own time")


func test_the_boss_wave_is_larger_and_red() -> void:
	var banner := _banner()
	banner.announce(2)
	var plain := _labels(banner)[0]
	assert_eq(plain.get_theme_color(&"font_color"), UiStyle.TITLE_COLOR)
	var plain_size := plain.get_theme_font_size(&"font_size")
	banner.announce(3, &"boss", "Thresh")
	var title := _labels(banner)[0]
	assert_eq(title.text, "BOSS")
	assert_eq(title.get_theme_color(&"font_color"), UiStyle.ERROR_COLOR)
	assert_gt(title.get_theme_font_size(&"font_size"), plain_size)
	assert_eq(_labels(banner)[1].text, "Thresh")


func test_it_never_takes_mouse_input() -> void:
	var banner := _banner()
	banner.announce(10, &"boss", "Thresh")
	assert_eq(banner.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	var parts := banner.find_children("*", "Control", true, false)
	assert_gt(parts.size(), 4, "the lines and their rules")
	for part: Control in parts:
		assert_eq(part.mouse_filter, Control.MOUSE_FILTER_IGNORE, part.get_class())


func test_its_time_only_runs_while_the_game_does() -> void:
	assert_eq(_banner().process_mode, Node.PROCESS_MODE_PAUSABLE)


# --- In the stage -------------------------------------------------------------


func test_a_wave_start_shows_the_banner_on_the_huds_layer() -> void:
	var stage: Stage = await _story(2, 1)
	var banner := stage.wave_banner
	assert_eq(banner.get_parent(), stage.hud)
	assert_false(banner.visible, "not before wave 1")
	stage.skip_break()
	assert_true(banner.visible)
	assert_eq(banner.shown, PackedStringArray(["WAVE 1"]))
	banner._process(WaveBanner.FADE + WaveBanner.TIME + WaveBanner.FADE + 0.02)
	assert_false(banner.visible)
	await wait_physics_frames(1)
	stage.jump_to_last_wave()
	stage.runner.tick(0.1)
	assert_true(banner.visible, "again for the next")
	assert_eq(banner.shown, PackedStringArray(["WAVE 4"]))


func test_the_boss_wave_names_the_boss() -> void:
	var stage: Stage = await _story(2, 3)
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	assert_eq(stage.wave_banner.shown, PackedStringArray(["BOSS", "Akshan"]))
	assert_eq(stage.wave_banner.kind, &"boss")


func test_a_mini_boss_wave_names_the_mini_boss() -> void:
	var stage: Stage = await _story(3, 2)
	stage.skip_break()
	assert_eq(stage.wave_banner.shown, PackedStringArray(["WAVE 1"]))
	stage.jump_to_last_wave()
	stage.runner.tick(0.1)
	assert_eq(stage.wave_banner.shown, PackedStringArray(["MINI BOSS", "Infernal Drake"]))


func test_endless_shows_it_too_under_the_stage_info_and_the_boss_bar() -> void:
	var stage: Stage = await _endless()
	var banner := stage.wave_banner
	stage.skip_break()
	assert_eq(banner.shown, PackedStringArray(["WAVE 1"]))
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	var boss: EnemyData = load(Stage.ENEMY_PATH % stage.runner.boss)
	assert_eq(banner.shown, PackedStringArray(["BOSS", boss.display_name]))
	await wait_process_frames(2)
	assert_true(stage.hud.boss_bar.visible)
	# Endless's boss bar is the lowest: it sits under the stage info's Best line.
	var top := banner.get_global_rect().position.y
	assert_gt(top, stage.hud.boss_bar.get_global_rect().end.y, "clear of the boss bar")
	assert_gt(top, stage.hud.stage_info.get_global_rect().end.y, "and of the stage info")
	assert_gt(WaveBanner.TOP - WaveBanner.SLIDE, stage.hud.boss_bar.get_global_rect().end.y, "even as it slides in")


func test_it_hides_with_the_hud() -> void:
	var stage: Stage = await _story(2, 1)
	stage.skip_break()
	assert_true(stage.wave_banner.is_visible_in_tree())
	stage.freeze(true)
	assert_false(stage.wave_banner.is_visible_in_tree(), "a cutscene hides the HUD")
	stage.freeze(false)
	stage.show_result(false)
	assert_false(stage.wave_banner.is_visible_in_tree(), "so does the end screen")


func test_training_has_no_banner() -> void:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	add_child_autofree(stage)
	await wait_process_frames(2)
	assert_null(stage.wave_banner)


## A tip under the boss bar (Act 1's "Thresh's hook…") and the boss's banner
## show together: the banner starts under the tip, not over it.
func test_the_banner_sits_under_the_huds_tips() -> void:
	var tips := TipBanner.new()
	add_child_autofree(tips)
	tips.show_tip(&"t", "Thresh's hook flies along the red line. Move sideways!")
	tips._process(0.0)
	await wait_process_frames(2)
	assert_gt(WaveBanner.TOP, Hud.TIPS_TOP + tips.size.y, "clear of a tip")
