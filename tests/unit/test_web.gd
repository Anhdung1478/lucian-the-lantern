extends GutTest
## Web (HTML5/itch.io) compatibility paths: Shift rank-up, Exit hiding,
## Graphics settings & Fullscreen toggle sync, camera default, HUD menu button
## & gold overlap, time-sliced Web music, SaveGame.unsaved, LeaveGuard and
## main-screen Web autosave.

var _old_web := false
var _old_owns_window := true
var _old_streams := {}
var _old_save: SaveGame
var _settings_path := ""


func before_each() -> void:
	_old_web = GameSettings.web
	_old_owns_window = GameSettings.owns_window
	_old_streams = Music._streams
	_old_save = SaveGame._instance
	Music._streams = {}
	_settings_path = "user://test_web_settings_%d.json" % Time.get_ticks_usec()
	SaveGame._instance = SaveGame.new("user://test_web_save_%d_slot_" % Time.get_ticks_usec())
	SaveGame.instance().reset()


func after_each() -> void:
	GameSettings.web = _old_web
	GameSettings.owns_window = _old_owns_window
	Music._streams = _old_streams
	get_tree().paused = false
	for p in [_settings_path, _settings_path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	var save := SaveGame.instance()
	for s in range(1, SaveGame.SLOTS + 1):
		for p in [save.path(s), save.path(s) + ".tmp", save.backup_path(s)]:
			if FileAccess.file_exists(p):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	SaveGame._instance = _old_save


func _find_button_text(root: Node, label: String) -> Button:
	for child in root.get_children():
		if child is Button and (child as Button).text == label:
			return child as Button
		if child is MenuEntry:
			for sub in child.find_children("*", "Label", true, false):
				if (sub as Label).text == label:
					return child as Button
		var found := _find_button_text(child, label)
		if found:
			return found
	return null


func _key_event(code: Key, shift := false, ctrl := false) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.pressed = true
	ev.shift_pressed = shift
	ev.ctrl_pressed = ctrl
	return ev


# --- Shift & Ctrl rank-up ---------------------------------------------------


func test_shift_and_ctrl_rank_up_skills_without_casting() -> void:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 1, 1))
	add_child_autofree(stage)
	await wait_process_frames(2)
	var lucian := stage.lucian
	lucian.progress.bought = [5, 5, 5, 3]
	lucian.progress.level = 3
	var q_before: int = lucian.progress.ranks[ChampionProgress.Slot.Q]
	var w_before: int = lucian.progress.ranks[ChampionProgress.Slot.W]
	var ctrl: LucianController = lucian.get_node("Controller")
	assert_true(ctrl._key_input(_key_event(KEY_Q, true, false)), "Shift+Q handled")
	assert_eq(lucian.progress.ranks[ChampionProgress.Slot.Q], q_before + 1, "Shift+Q ranked up Q")
	assert_true(lucian.skills[ChampionProgress.Slot.Q].cooldown.is_ready(), "Shift+Q did not cast Q")
	assert_true(ctrl._key_input(_key_event(KEY_W, false, true)), "Ctrl+W handled")
	assert_eq(lucian.progress.ranks[ChampionProgress.Slot.W], w_before + 1, "Ctrl+W ranked up W")
	assert_true(lucian.skills[ChampionProgress.Slot.W].cooldown.is_ready(), "Ctrl+W did not cast W")


# --- Exit buttons hidden on Web ---------------------------------------------


func test_exit_buttons_hidden_on_web_and_shown_on_desktop() -> void:
	GameSettings.web = true
	var title_web := TitleScreen.new()
	add_child_autofree(title_web)
	var gear_web := GearMenu.new()
	add_child_autofree(gear_web)
	var menu_web := GameMenu.new()
	add_child_autofree(menu_web)
	assert_null(_find_button_text(title_web, "Exit game"), "Title hides Exit on Web")
	assert_null(_find_button_text(gear_web, "Exit the game"), "GearMenu hides Exit on Web")
	assert_null(_find_button_text(menu_web, "Exit the game"), "GameMenu hides Exit on Web")

	GameSettings.web = false
	var title_desk := TitleScreen.new()
	add_child_autofree(title_desk)
	var gear_desk := GearMenu.new()
	add_child_autofree(gear_desk)
	var menu_desk := GameMenu.new()
	add_child_autofree(menu_desk)
	assert_not_null(_find_button_text(title_desk, "Exit game"), "Title shows Exit on desktop")
	assert_not_null(_find_button_text(gear_desk, "Exit the game"), "GearMenu shows Exit on desktop")
	assert_not_null(_find_button_text(menu_desk, "Exit the game"), "GameMenu shows Exit on desktop")


# --- Graphics page & Fullscreen toggle sync ---------------------------------


func _row_titles(page: Node) -> Array[String]:
	var titles: Array[String] = []
	for child in page.get_children():
		if child is SettingsRow:
			for lbl in child.find_children("*", "Label", true, false):
				titles.append((lbl as Label).text)
				break
	return titles


func test_web_graphics_page_and_fullscreen_toggle_sync() -> void:
	GameSettings.web = true
	var gs := GameSettings.new(_settings_path)
	assert_eq(gs.get_value(&"quality"), "medium", "Fresh Web settings default to medium quality")
	var screen := SettingsScreen.new()
	var state := {"fs": false, "calls": 0}
	screen.fullscreen_getter = func() -> bool: return state.fs
	screen.fullscreen_setter = func(on: bool) -> void:
		state.fs = on
		state.calls += 1
	add_child_autofree(screen)
	screen.setup(gs)
	var web_rows := _row_titles(screen._pages[2])
	assert_eq(web_rows, ["Fullscreen", "Quality", "Show FPS"], "Web Graphics page has only Fullscreen, Quality, Show FPS")

	# External fullscreen change before open() updates the toggle without calling setter.
	state.fs = true
	screen.open(2)
	assert_true(screen._fullscreen_toggle.button_pressed, "open() syncs Fullscreen toggle ON")
	assert_eq(state.calls, 0, "open() sync never calls fullscreen_setter")

	# Browser exits fullscreen while Settings is open -> viewport size_changed syncs toggle.
	state.fs = false
	screen._on_viewport_resized()
	assert_false(screen._fullscreen_toggle.button_pressed, "size_changed syncs Fullscreen toggle OFF")
	assert_eq(state.calls, 0, "size_changed sync never calls fullscreen_setter")

	# Desktop Graphics page stays unchanged.
	GameSettings.web = false
	var gs_desk := GameSettings.new(_settings_path + ".desk")
	var screen_desk := SettingsScreen.new()
	add_child_autofree(screen_desk)
	screen_desk.setup(gs_desk)
	var desk_rows := _row_titles(screen_desk._pages[2])
	assert_has(desk_rows, "Window mode")
	assert_has(desk_rows, "Resolution")
	assert_has(desk_rows, "VSync")
	assert_has(desk_rows, "FPS cap")
	assert_has(desk_rows, "Quality")
	assert_has(desk_rows, "Show FPS")


# --- Camera default mode ----------------------------------------------------


func test_camera_starts_follow_on_web_and_free_on_desktop() -> void:
	GameSettings.web = true
	var cam_web := StageCamera.new()
	add_child_autofree(cam_web)
	assert_eq(cam_web.mode, StageCamera.Mode.FOLLOW, "Web camera defaults to FOLLOW")

	GameSettings.web = false
	var cam_desk := StageCamera.new()
	add_child_autofree(cam_desk)
	assert_eq(cam_desk.mode, StageCamera.Mode.FREE, "Desktop camera defaults to FREE")


# --- Web HUD menu button & gold overlap -------------------------------------


func test_hud_menu_button_on_web_opens_menu_and_clears_gold_plate() -> void:
	GameSettings.web = false
	var stage_desk: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage_desk.setup(StageSetup.for_stage(SaveGame.instance(), 1, 1))
	add_child_autofree(stage_desk)
	await wait_process_frames(2)
	assert_null(stage_desk.hud.menu_button, "Desktop HUD has no menu button")
	stage_desk.queue_free()
	await wait_process_frames(1)

	GameSettings.web = true
	var stage_web: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage_web.setup(StageSetup.for_stage(SaveGame.instance(), 1, 1))
	add_child_autofree(stage_web)
	await wait_process_frames(2)
	var btn := stage_web.hud.menu_button
	var gold := stage_web.hud.gold_panel
	assert_not_null(btn, "Web HUD has a menu button")
	assert_not_null(gold, "Web HUD has a gold plate")

	for amount: int in [1, 99999]:
		stage_web.wallet.gold = amount
		stage_web.wallet.changed.emit(amount)
		await wait_process_frames(2)
		assert_false(gold.get_global_rect().intersects(btn.get_global_rect()),
				"Gold plate and menu button must not overlap at %d gold" % amount)

	assert_false(stage_web.screens.menu.is_open())
	btn.pressed.emit()
	assert_true(stage_web.screens.menu.is_open(), "Pressing Web HUD menu button opens the menu")


# --- Time-sliced Web music --------------------------------------------------


func test_web_music_uses_time_sliced_render_matching_render_layer() -> void:
	GameSettings.web = true
	var music := Music.new()
	music.renders = true
	add_child_autofree(music)
	music.set_process(false)
	music._render(Score.THEME)
	assert_eq(music._task, -1, "Web music never starts a WorkerThreadPool task")
	assert_not_null(music._web_render, "Web music starts a Score.PieceRender")

	# Verify one layer of each piece matches Score.render_layer() exactly.
	for p in Score.PIECES.size():
		var layer := p % Score.LAYER_COUNT
		var job := Score.LayerRender.new(p, layer)
		var steps := 0
		while not job.step_once():
			steps += 1
		var expected := Score.render_layer(p, layer)
		assert_eq(job.samples.size(), expected.size(), "Piece %d layer %d sample count" % [p, layer])
		assert_eq(job.samples, expected, "Piece %d layer %d samples match render_layer()" % [p, layer])


# --- SaveGame.unsaved, LeaveGuard & Web autosave ----------------------------


func test_save_game_unsaved_and_leave_guard_rule() -> void:
	var save := SaveGame.instance()
	assert_false(save.unsaved, "Fresh reset save is not unsaved")
	assert_false(LeaveGuard.is_unsafe(save, false), "Clean save on main screen is safe")
	assert_true(LeaveGuard.is_unsafe(save, true), "Open stage is always unsafe")

	save.essences.add(Essences.BLUE, 5)
	assert_true(save.unsaved, "Essence change marks unsaved")
	assert_true(LeaveGuard.is_unsafe(save, false), "Unsaved change on main screen is unsafe")

	assert_true(save.save())
	assert_false(save.unsaved, "Successful save clears unsaved")
	assert_false(LeaveGuard.is_unsafe(save, false), "Saved slot on main screen is safe")

	save.load_slot(1)
	assert_false(save.unsaved, "load_slot clears unsaved")

	save.reset()
	assert_false(save.unsaved, "reset clears unsaved")

	assert_true(save.start_new(1, Difficulty.NORMAL))
	assert_false(save.unsaved, "start_new clears unsaved")


func test_web_autosave_saves_main_screen_changes_once_and_skips_loads_and_stages() -> void:
	GameSettings.web = true
	var save := SaveGame.instance()
	assert_true(save.start_new(1, Difficulty.NORMAL))
	var game := Game.new()
	add_child_autofree(game)
	await wait_process_frames(2)

	# On MainScreen, a purchase saves once at end of frame.
	game.show_main_screen()
	await wait_process_frames(2)
	save.essences.add(Essences.BLUE, 10)
	assert_true(save.unsaved, "Dirty before end of frame")
	await wait_process_frames(2)
	assert_false(save.unsaved, "Autosave wrote the slot at end of frame")
	var reloaded := SaveGame.new(save.prefix)
	assert_true(reloaded.load_slot(1))
	assert_eq(reloaded.essences.amount(Essences.BLUE), 10, "Autosaved essence persisted to disk")

	# Loading a slot does not leave unsaved dirty or rewrite.
	save.load_slot(1)
	assert_false(save.unsaved)
	await wait_process_frames(2)
	assert_false(save.unsaved)

	# Inside a stage, changes do not autosave.
	game.start_stage(StageSetup.for_stage(save, 1, 1))
	await wait_process_frames(2)
	save.essences.add(Essences.BLUE, 25)
	assert_true(save.unsaved)
	await wait_process_frames(2)
	assert_true(save.unsaved, "Changes inside a stage are not autosaved")


# --- Secondary bindings, Menu (Tab) & Rank-up (Ctrl/Alt) --------------------


func test_secondary_bindings_defaults_persistence_and_rank_up() -> void:
	var gs := GameSettings.new(_settings_path)
	# Most actions default to no secondary binding.
	assert_eq(gs.key_label(&"skill_q", 0), "Q")
	assert_eq(gs.key_label(&"skill_q", 1), "-")
	# Menu defaults to Escape (primary) and Tab (secondary).
	assert_eq(gs.key_label(&"open_menu", 0), "Escape")
	assert_eq(gs.key_label(&"open_menu", 1), "Tab")
	# Rank-up defaults to Ctrl+Q (primary) and Shift+Q (secondary).
	assert_eq(gs.key_label(&"rank_q", 0), "Ctrl+Q")
	assert_eq(gs.key_label(&"rank_q", 1), "Shift+Q")

	# Rebind secondary slot of skill_q to V, persist, reload, and clear.
	gs.rebind(&"skill_q", _key_event(KEY_V), 1)
	assert_eq(gs.key_label(&"skill_q", 1), "V")
	var reloaded := GameSettings.new(_settings_path)
	assert_eq(reloaded.key_label(&"skill_q", 1), "V")
	reloaded.clear_binding(&"skill_q", 1)
	assert_eq(reloaded.key_label(&"skill_q", 1), "-")

	# Verify Alt+Q ranks up Q without casting.
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 1, 1))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.progress.bought = [5, 5, 5, 3]
	stage.lucian.progress.level = 3
	var ctrl: LucianController = stage.lucian.get_node("Controller")
	var alt_q := InputEventKey.new()
	alt_q.physical_keycode = KEY_Q
	alt_q.pressed = true
	alt_q.alt_pressed = true
	var before: int = stage.lucian.progress.ranks[ChampionProgress.Slot.Q]
	assert_true(ctrl._key_input(alt_q), "Alt+Q handled")
	assert_eq(stage.lucian.progress.ranks[ChampionProgress.Slot.Q], before + 1, "Alt+Q ranked up Q")
	assert_true(stage.lucian.skills[ChampionProgress.Slot.Q].cooldown.is_ready(), "Alt+Q did not cast Q")


# --- Save Export / Import JSON ----------------------------------------------


func test_save_export_and_import_json_round_trip_and_rejects_invalid() -> void:
	var save := SaveGame.instance()
	assert_true(save.start_new(1, Difficulty.HARD))
	save.essences.add(Essences.BLUE, 123)
	save.essences.add(Essences.ORANGE, 45)
	save.set_cleared(["1-1", "2-1"])
	var exported := save.export_json()
	assert_true(exported.contains("\"essences\""))

	# Reset slot 1 and import the exported JSON back.
	assert_true(save.start_new(1, Difficulty.EASY))
	assert_eq(save.essences.amount(Essences.BLUE), 0)
	assert_true(save.import_json(exported), "Valid save JSON imports cleanly")
	assert_eq(save.essences.amount(Essences.BLUE), 123)
	assert_eq(save.essences.amount(Essences.ORANGE), 45)
	assert_eq(save.difficulty, Difficulty.HARD)
	assert_eq(save.cleared, ["1-1", "2-1"])
	assert_false(save.unsaved, "Import writes the slot and clears unsaved")

	# Rejects broken JSON and unrelated JSON without losing current progress.
	assert_false(save.import_json("{not json"))
	assert_false(save.import_json("{\"hello\": \"world\"}"))
	assert_eq(save.essences.amount(Essences.BLUE), 123, "Failed import preserves progress")

	# GearMenu exposes Export save and Import save buttons.
	var gear := GearMenu.new()
	add_child_autofree(gear)
	assert_not_null(_find_button_text(gear, "Export save"))
	assert_not_null(_find_button_text(gear, "Import save"))
