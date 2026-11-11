extends GutTest


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_stage_hud_save_slot_")


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


## One pip per wave, the boss wave's larger: cleared, current or ahead.
func test_the_pips_follow_the_waves() -> void:
	var runner := WaveRunner.new(WavePlan.waves("2-2"), &"test_boss")
	var info := StageInfo.new()
	add_child_autofree(info)
	info.setup("Stage 2-2 Â· The Sentinels", runner)
	var pips := info.pips
	assert_true(pips.visible)
	assert_eq(pips.total, 4, "3 waves and the boss wave")
	assert_gt(pips.pip_size(4), pips.pip_size(3), "the boss wave's pip is larger")
	assert_eq(_pip_states(pips), [WavePips.State.AHEAD, WavePips.State.AHEAD, WavePips.State.AHEAD, WavePips.State.AHEAD], "before wave 1")
	runner.skip()
	info.refresh()
	assert_eq(_pip_states(pips), [WavePips.State.CURRENT, WavePips.State.AHEAD, WavePips.State.AHEAD, WavePips.State.AHEAD], "wave 1")
	runner.state = WaveRunner.State.BREAK
	runner.wave = 2
	info.refresh()
	assert_eq(_pip_states(pips), [WavePips.State.CLEARED, WavePips.State.CLEARED, WavePips.State.AHEAD, WavePips.State.AHEAD], "the break after wave 2")
	runner.state = WaveRunner.State.FIGHT
	runner.wave = 4
	info.refresh()
	assert_eq(_pip_states(pips), [WavePips.State.CLEARED, WavePips.State.CLEARED, WavePips.State.CLEARED, WavePips.State.CURRENT], "the boss wave")
	runner.state = WaveRunner.State.DONE
	info.refresh()
	assert_eq(_pip_states(pips), [WavePips.State.CLEARED, WavePips.State.CLEARED, WavePips.State.CLEARED, WavePips.State.CLEARED], "the stage is won")


## The state of every pip, in wave order.
func _pip_states(pips: WavePips) -> Array:
	var states := []
	for i in range(1, pips.total + 1):
		states.append(WavePips.state_of(i, pips.wave, pips.fighting))
	return states


func test_a_stage_with_no_boss_has_no_larger_pip() -> void:
	var info := StageInfo.new()
	add_child_autofree(info)
	info.setup("Stage 2-2 Â· The Sentinels", WaveRunner.new(WavePlan.waves("2-2")))
	assert_eq(info.pips.total, 3)
	assert_eq(info.pips.pip_size(3), info.pips.pip_size(1))


## The name is a heading in capitals; its text is the stage's name as given.
func test_the_name_shows_in_capitals_over_the_row() -> void:
	var info := StageInfo.new()
	add_child_autofree(info)
	info.setup("Stage 2-2 Â· The Sentinels", WaveRunner.new(WavePlan.waves("2-2")))
	await wait_process_frames(2)
	assert_eq(info.name_label.text, "Stage 2-2 Â· The Sentinels")
	assert_true(info.name_label.uppercase)
	assert_lt(info.name_label.get_global_rect().end.y, info.timer_label.get_global_rect().position.y + 1.0)


## The break's Skip button and a wave's texts take the same room, so the
## boss bar under the plate never jumps.
func test_the_stage_info_is_as_tall_in_a_break_as_in_a_wave() -> void:
	var runner := WaveRunner.new(WavePlan.waves("2-2"))
	var info := StageInfo.new()
	add_child_autofree(info)
	info.setup("Stage 2-2 Â· The Sentinels", runner)
	await wait_process_frames(2)
	var in_break := info.size.y
	runner.skip()
	await wait_process_frames(2)
	assert_false(info.skip_button.visible)
	assert_eq(info.size.y, in_break)


func test_training_shows_only_its_name() -> void:
	var info := StageInfo.new()
	add_child_autofree(info)
	info.setup("Training", null)
	info.refresh()
	assert_eq(info.name_label.text, "Training")
	assert_false(info.wave_label.visible)
	assert_false(info.skip_button.visible)
	assert_false(info.pips.visible)


func test_the_stage_info_fits_training() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)
	hud.setup(lucian, Wallet.new())
	await wait_process_frames(2)
	var info := hud.stage_info
	assert_almost_eq(info.size.x, info.get_combined_minimum_size().x, 1.0, "no room left for the hidden Skip")


## The slots and their hover cards both use the short name, so a long one
## like "Backspace" never overflows a card's header.
func test_skill_and_summoner_slots_and_their_cards_show_the_short_key_name() -> void:
	var shared := GameSettings._instance
	GameSettings._instance = GameSettings.new("user://test_stage_hud_settings.json")
	GameSettings._instance.rebind(&"skill_q", _mouse_four())
	var backspace := InputEventKey.new()
	backspace.keycode = KEY_BACKSPACE
	GameSettings._instance.rebind(&"summoner_d", backspace)
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)
	hud.setup(lucian, Wallet.new())
	await wait_process_frames(1)
	var shown := hud._skill_slots[0]._key
	var skill_card := hud._skill_slots[0].tooltip_content()
	var summoner: SummonerSlot = null
	for child in hud.skill_row.get_children():
		if child is SummonerSlot and summoner == null:
			summoner = child
	var summoner_card := summoner.tooltip_content()
	var skill_text := _card_text(skill_card)
	var summoner_text := _card_text(summoner_card)
	skill_card.free()
	summoner_card.free()
	GameSettings._instance = shared
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_stage_hud_settings.json"))
	assert_eq(shown, "M4")
	assert_string_contains(skill_text, "[M4]")
	assert_string_contains(summoner_text, "[Bcksp]")
	assert_false(summoner_text.contains("Backspace"), "the card keeps the short name too")


## Every label's text on a card.
func _card_text(card: Control) -> String:
	var parts: PackedStringArray = []
	for label: Label in card.find_children("*", "Label", true, false):
		parts.append(label.text)
	for rich: RichTextLabel in card.find_children("*", "RichTextLabel", true, false):
		parts.append(rich.get_parsed_text())
	return "\n".join(parts)


func _mouse_four() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_XBUTTON1
	return event


func test_skip_on_the_hud_starts_the_wave() -> void:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 2, 1))
	add_child_autofree(stage)
	await wait_physics_frames(2)
	stage.hud.stage_info.skip_button.pressed.emit()
	assert_eq(stage.runner.state, WaveRunner.State.FIGHT)


func test_the_boss_bar_and_the_tips_sit_under_the_stage_info() -> void:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 2, 1))
	add_child_autofree(stage)
	await wait_process_frames(2)
	var hud := stage.hud
	assert_gte(hud.boss_bar.get_global_rect().position.y, hud.stage_info.get_global_rect().end.y)
	assert_gte(hud.tips.offset_top, hud.boss_bar.offset_top + hud.boss_bar.custom_minimum_size.y)


func test_the_radar_maps_the_world_onto_itself() -> void:
	var radar := Radar.new()
	add_child_autofree(radar)
	radar.setup(Rect2(0, 0, 5200, 3200), null)
	assert_eq(radar.size, Vector2(Radar.WIDTH, 160))
	assert_eq(radar.to_radar(Vector2(2600, 1600)), Vector2(130, 80))
	assert_eq(radar.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_the_radar_marks_its_four_frame_corners() -> void:
	assert_eq(Radar.corners(Vector2(260, 160)), PackedVector2Array([Vector2(0, 0), Vector2(260, 0), Vector2(260, 160), Vector2(0, 160)]))


func test_a_buff_icon_is_a_rounded_cell_that_draws_with_and_without_a_ready_pulse() -> void:
	var icon := BuffIcon.new()
	add_child_autofree(icon)
	for ready in [false, true]:
		icon.buff = {"id": &"test", "name": "Test", "icon": null, "text": "", "count": "3", "left": 2.0, "duration": 4.0, "ready": ready}
		await wait_process_frames(2)
		assert_eq(icon.custom_minimum_size, Vector2(BuffIcon.SIZE, BuffIcon.SIZE))
	assert_eq(icon.mouse_filter, Control.MOUSE_FILTER_PASS, "still hoverable")


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


func test_the_boss_bar_names_the_boss_in_capitals_over_a_health_bar() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	var bar := BossBar.new()
	add_child_autofree(bar)
	var boss := _unit(&"boss", "Test Boss", lucian)
	await wait_process_frames(2)
	assert_eq(bar._heading.label.text, "Test Boss")
	assert_true(bar._heading.label.uppercase, "shown in capitals")
	assert_eq(bar._bar.amount, 1000.0)
	assert_eq(bar._text.text, "1000 / 1000")
	boss.take_damage(DamageInfo.create(400.0, DamageInfo.Type.TRUE, &"test"))
	await wait_process_frames(2)
	assert_eq(bar._bar.amount, 600.0)
	assert_gt(bar._bar.ghost_amount(), 600.0, "the lost part lingers as a ghost")
	assert_eq(bar._text.text, "600 / 1000")


func test_a_mini_boss_is_a_12_px_skull() -> void:
	assert_eq(Radar.dot_size(&"mini_boss"), 12.0)
	assert_lt(Radar.dot_size(&"mini_boss"), Radar.dot_size(&"boss"))
	assert_gt(Radar.dot_size(&"mini_boss"), Radar.dot_size(&"elite"))


## A unit of `kind` far from Lucian, built in code.
func _unit(kind: StringName, shown_name: String, lucian: Lucian) -> EnemyUnit:
	var data := EnemyData.new()
	data.kind = kind
	data.display_name = shown_name
	data.max_hp = 1000.0
	var unit := Minion.new()
	unit.setup(data, 1, 1, lucian)
	unit.position = Vector2(3000, 0)
	add_child_autofree(unit)
	return unit


func test_a_mini_boss_has_a_boss_size_health_bar() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	assert_eq(_unit(&"mini_boss", "Test Drake", lucian).health_bar.size, EnemyUnit.BOSS_BAR)


func test_the_boss_bar_shows_a_mini_boss_and_prefers_a_boss() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	var bar := BossBar.new()
	add_child_autofree(bar)
	var drake := _unit(&"mini_boss", "Test Drake", lucian)
	await wait_process_frames(3)
	assert_true(bar.visible)
	assert_eq(bar.boss, drake)
	var boss := _unit(&"boss", "Test Boss", lucian)
	await wait_process_frames(3)
	assert_eq(bar.boss, boss, "a boss takes the bar")
	_unit(&"mini_boss", "Another Drake", lucian)
	await wait_process_frames(3)
	assert_eq(bar.boss, boss, "a boss keeps it")
	boss.take_damage(DamageInfo.create(5000.0, DamageInfo.Type.TRUE, &"test"))
	await wait_process_frames(3)
	assert_true(bar.visible)
	assert_eq(bar.boss.data.kind, &"mini_boss", "back to a mini boss")


## The Lantern look: the bottom bar on an ornate plate, the smaller panels
## on plain ones, all a little see-through.
func test_the_hud_sits_on_plates() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)
	hud.setup(lucian, Wallet.new())
	assert_true(hud.bottom_panel.ornate, "the bottom bar")
	assert_eq(hud.bottom_panel.opacity, Hud.PLATE_OPACITY)
	for plate: Plate in [hud.stats_panel, hud.extra_stats, hud.stage_info, hud._gold_label.get_parent().get_parent()]:
		assert_false(plate.ornate)
		assert_eq(plate.opacity, Hud.PLATE_OPACITY)


## The round portrait carries the level badge on its ring, over the XP bar.
func test_the_portrait_shows_the_level_and_the_xp() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)
	hud.setup(lucian, Wallet.new())
	var progress := lucian.progress
	progress.add_xp(progress.xp_for_next() + 30)
	await wait_process_frames(2)
	assert_eq(hud.portrait.texture, lucian.skin.portrait)
	assert_eq(hud.level_label.text, "2")
	assert_almost_eq(hud.xp_bar.value, 30.0 / progress.xp_for_next(), 0.001)
	assert_true(hud.portrait.get_global_rect().encloses(hud.level_label.get_global_rect()), "the badge sits on the portrait")
	assert_gte(hud.xp_bar.get_global_rect().position.y, hud.portrait.get_global_rect().end.y, "the XP bar is under it")


## The bottom bar covers no more of the fight than it did before the
## Lantern look (176 px).
func test_the_bottom_bar_is_no_taller_than_before() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)
	hud.setup(lucian, Wallet.new())
	await wait_process_frames(2)
	assert_lte(hud.bottom_panel.size.y, 176.0)


func test_fps_sits_top_left() -> void:
	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)
	assert_eq(hud._fps_label.anchor_left, 0.0)
	assert_eq(hud._fps_label.anchor_right, 0.0)



func test_the_vignette_shows_below_30_percent_health_and_grows_toward_zero() -> void:
	assert_eq(LowHealthVignette.strength_for(300.0, 1000.0, false, false), 0.0, "gone at 30%")
	assert_eq(LowHealthVignette.strength_for(900.0, 1000.0, false, false), 0.0)
	assert_gt(LowHealthVignette.strength_for(299.0, 1000.0, false, false), 0.0)
	assert_almost_eq(LowHealthVignette.strength_for(150.0, 1000.0, false, false), 0.5, 0.001)
	assert_eq(LowHealthVignette.strength_for(0.0, 1000.0, false, false), 1.0)


func test_the_vignette_is_gone_when_dead_on_low_effects_or_with_no_max() -> void:
	assert_eq(LowHealthVignette.strength_for(100.0, 1000.0, true, false), 0.0)
	assert_eq(LowHealthVignette.strength_for(100.0, 1000.0, false, true), 0.0)
	assert_eq(LowHealthVignette.strength_for(0.0, 0.0, false, false), 0.0)


func test_the_vignette_pulses_between_a_dim_and_a_full_alpha() -> void:
	var full := LowHealthVignette.alpha_for(1.0, 0.0)
	var dim := LowHealthVignette.alpha_for(1.0, 0.5)
	assert_almost_eq(full, LowHealthVignette.ALPHA_AT_ZERO, 0.001)
	assert_almost_eq(dim, full * (1.0 - LowHealthVignette.PULSE_DIP), 0.001)
	assert_eq(LowHealthVignette.alpha_for(0.0, 0.0), 0.0)
	assert_gt(LowHealthVignette.alpha_for(0.01, 0.0), 0.0)


func test_the_hud_has_the_vignette_under_everything_and_it_never_takes_the_mouse() -> void:
	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)
	assert_eq(hud.vignette.get_index(), 0, "first, so drawn under the rest")
	assert_eq(hud.vignette.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(hud.vignette.get_parent(), hud.get_node("Root"))


func test_the_vignette_follows_lucian_and_the_setting() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	await wait_physics_frames(1)
	var vignette := LowHealthVignette.new()
	add_child_autofree(vignette)
	lucian.hp = lucian.stats.max_hp * 0.2
	vignette.show_health(lucian)
	assert_true(vignette.visible)
	lucian.hp = lucian.stats.max_hp * 0.5
	vignette.show_health(lucian)
	assert_false(vignette.visible)
	lucian.hp = lucian.stats.max_hp * 0.2
	lucian.dead = true
	vignette.show_health(lucian)
	assert_false(vignette.visible)
