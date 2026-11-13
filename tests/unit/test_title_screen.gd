extends GutTest

const BROKEN_PREFIX := "user://no_such_dir/test_title_save_slot_"

var game: Game
var quit_called := false
## The save prefix the test runs with, put back after a test breaks it.
var good_prefix := ""


func before_each() -> void:
	quit_called = false
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_title_save_slot_")
	good_prefix = SaveGame.instance().prefix
	_delete_slots()
	SaveGame.instance().load_slot(1)
	game = load("res://src/main/game.tscn").instantiate()
	game.quit_game = func() -> void: quit_called = true
	add_child_autofree(game)


func after_each() -> void:
	get_tree().paused = false
	SaveGame.instance().prefix = good_prefix
	_delete_slots()


func _delete_slots() -> void:
	var save := SaveGame.instance()
	for n in range(1, SaveGame.SLOTS + 1):
		for file in [save.path(n), save.backup_path(n)]:
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func _title() -> TitleScreen:
	return game.screen as TitleScreen


## The pop-up's buttons on screen, in order: "Yes / No / Cancel".
func _choices(popup: ConfirmPopup) -> String:
	var labels := PackedStringArray()
	for button: Button in popup.find_children("*", "Button", true, false):
		if button.visible:
			labels.append(button.text)
	return " / ".join(labels)


## A real ESC press and release, through the viewport: whoever reads it first wins.
func _press_esc() -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ESCAPE
		key.physical_keycode = KEY_ESCAPE
		key.pressed = pressed
		Input.parse_input_event(key)
	Input.flush_buffered_events()


## A real left click on `control`'s middle, through the viewport: whatever
## is on top there gets it.
func _click(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = at
		click.global_position = at
		get_viewport().push_input(click, true)
	await wait_process_frames(1)


func test_the_game_opens_on_the_title_screen() -> void:
	assert_is(game.screen, TitleScreen)


## A real key press and release, through the viewport.
func _press_key(code: Key) -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = code
		key.physical_keycode = code
		key.pressed = pressed
		Input.parse_input_event(key)
	Input.flush_buffered_events()


## Item 33: the arrow keys and Enter work the title menu and its pages; Load
## game is skipped while there is nothing to load.
func test_the_arrow_keys_and_enter_work_the_title_pages() -> void:
	var title := _title()
	assert_true(title.load_button.disabled)
	_press_key(KEY_DOWN)
	_press_key(KEY_DOWN)
	assert_eq(title.keys.lit_button(), title.find_button("Settings"), "past Load game")
	_press_key(KEY_UP)
	_press_key(KEY_ENTER)
	assert_true(title.is_showing_slots(), "Start new game")
	assert_eq(title.keys.lit, -1, "a page starts unlit")
	_press_key(KEY_DOWN)
	_press_key(KEY_KP_ENTER)
	assert_true(title.is_showing_difficulty(), "empty slot 1")
	_press_key(KEY_UP)
	assert_eq(title.keys.lit_button().text, "Back")
	_press_key(KEY_ENTER)
	assert_true(title.is_showing_slots())
	assert_eq(game.screen, title, "nothing started")


# --- The backdrop: the night scene and the three figures -------------------------


func test_the_backdrop_and_the_figures_ignore_the_mouse_and_keep_their_art_s_shape() -> void:
	var title := _title()
	var backdrop := title.backdrop
	assert_is(backdrop, TitleBackdrop)
	assert_eq(title.get_child(0), backdrop, "behind everything")
	await wait_process_frames(1)
	assert_eq(backdrop.size, title.size, "fills the screen")
	assert_eq(backdrop.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	var layers := backdrop.find_children("*", "Control", true, false)
	assert_gte(layers.size(), 5, "the three figures, the near layer and the moving layer")
	for layer: Control in layers:
		assert_eq(layer.mouse_filter, Control.MOUSE_FILTER_IGNORE, layer.name)
	for figure: TitleFigure in [backdrop.lucian, backdrop.senna, backdrop.thresh]:
		assert_almost_eq(figure.size.x / figure.size.y, figure.box.size.x / figure.box.size.y, 0.01, "%s keeps its art's shape" % figure.name)
	assert_lt(backdrop.senna.get_index(), backdrop.lucian.get_index(), "Senna stands behind Lucian")
	assert_lt(backdrop.thresh.get_index(), backdrop.foreground.get_index(), "the near grass and graves stand in front of the figures")
	assert_lt(backdrop.foreground.get_index(), backdrop.effects.get_index(), "the mist rolls in front of everything")


func test_lucian_and_senna_stand_left_of_the_column_and_thresh_right_of_it() -> void:
	var title := _title()
	var backdrop := title.backdrop
	await wait_process_frames(2)
	var middle := title.size.x * 0.5
	for page: String in ["menu", "slots"]:
		if page == "slots":
			title.show_slots(false)
			await wait_process_frames(2)
		var column := title.column.get_global_rect()
		assert_gt(column.size.x, 400.0, "the %s column is laid out" % page)
		for figure: TitleFigure in [backdrop.lucian, backdrop.senna]:
			var rect := figure.get_global_rect()
			assert_lt(rect.get_center().x, middle, "%s left of centre" % figure.name)
			assert_lt(rect.end.x, column.position.x, "%s clear of the %s column" % [figure.name, page])
		var thresh := backdrop.thresh.get_global_rect()
		assert_gt(thresh.get_center().x, middle, "Thresh right of centre")
		assert_gt(thresh.position.x, column.end.x, "Thresh clear of the %s column" % page)
	for figure: TitleFigure in [backdrop.lucian, backdrop.senna, backdrop.thresh]:
		var rect := figure.get_global_rect()
		assert_gt(rect.end.y, title.size.y - 60.0, "%s stands at the bottom" % figure.name)
		assert_lte(rect.end.y, title.size.y, "%s's feet show" % figure.name)


func test_on_a_wider_screen_the_figures_keep_to_the_edges() -> void:
	# The backdrop fills its parent, as it fills the title screen.
	var screen := Control.new()
	screen.size = Vector2(1920, 1080)
	var backdrop := TitleBackdrop.new()
	screen.add_child(backdrop)
	add_child_autofree(screen)
	var lucian := backdrop.lucian.get_rect()
	var senna := backdrop.senna.get_rect()
	var thresh := backdrop.thresh.get_rect()
	screen.size = Vector2(2560, 1080)
	assert_eq(backdrop.size, screen.size)
	assert_eq(backdrop.lucian.get_rect(), lucian, "Lucian keeps to the left edge")
	assert_eq(backdrop.senna.get_rect(), senna, "Senna too")
	assert_eq(backdrop.thresh.get_rect(), Rect2(thresh.position + Vector2(640, 0), thresh.size), "Thresh keeps to the right edge")


func test_the_scene_is_drawn_once_and_only_its_effects_move_while_it_shows() -> void:
	var title := _title()
	var backdrop := title.backdrop
	await wait_process_frames(2)
	var still: Array[Control] = [backdrop, backdrop.lucian, backdrop.senna, backdrop.thresh, backdrop.foreground]
	for layer in still:
		watch_signals(layer)
	watch_signals(backdrop.effects)
	await wait_process_frames(4)
	for layer in still:
		assert_signal_emit_count(layer, "draw", 0, "%s is drawn once" % layer.name)
	assert_gt(get_signal_emit_count(backdrop.effects, "draw"), 2, "mist, wisps and motes move")
	assert_true(backdrop.is_processing())
	title.visible = false
	assert_false(backdrop.is_processing(), "hidden")
	title.visible = true
	assert_true(backdrop.is_processing(), "shown again")


func test_on_low_effects_nothing_moves() -> void:
	var settings := GameSettings.instance()
	var quality: Variant = settings.get_value(&"quality")
	settings.set_value(&"quality", "high", false)
	var backdrop := _title().backdrop
	await wait_process_frames(1)
	assert_true(backdrop.is_processing())
	assert_true(backdrop.effects.visible)
	settings.set_value(&"quality", "low", false)
	assert_false(backdrop.is_processing(), "low effects: the scene stands still")
	assert_false(backdrop.effects.visible, "and the mist, souls and glints are gone")
	assert_almost_eq(backdrop.senna.modulate.a, TitleBackdrop.SENNA_ALPHA, 0.001, "Senna does not shimmer")
	watch_signals(backdrop.effects)
	await wait_process_frames(3)
	assert_signal_emit_count(backdrop.effects, "draw", 0)
	settings.set_value(&"quality", "medium", false)
	assert_true(backdrop.is_processing(), "back on")
	assert_true(backdrop.effects.visible)
	settings.set_value(&"quality", quality, false)


func test_a_backdrop_opened_on_low_effects_stands_still() -> void:
	var settings := GameSettings.instance()
	var quality: Variant = settings.get_value(&"quality")
	settings.set_value(&"quality", "low", false)
	var backdrop := TitleBackdrop.new()
	add_child_autofree(backdrop)
	assert_false(backdrop.is_processing())
	assert_false(backdrop.effects.visible)
	settings.set_value(&"quality", quality, false)


func test_hiding_thresh_takes_his_lantern_s_light_off_the_others() -> void:
	var backdrop := TitleBackdrop.new()
	backdrop.thresh.visible = false
	add_child_autofree(backdrop)
	assert_false(backdrop.lucian.lantern_lit, "Lucian")
	assert_false(backdrop.senna.lantern_lit, "Senna")
	backdrop.thresh.visible = true
	assert_true(backdrop.lucian.lantern_lit, "Thresh is back")
	assert_true(backdrop.senna.lantern_lit)


func test_every_button_is_still_found_and_clicks_through_the_backdrop() -> void:
	var title := _title()
	await wait_process_frames(2)
	for text: String in ["Start new game", "Load game", "Settings", "Exit game"]:
		assert_not_null(title.find_button(text), text)
	await _click(title.find_button("Start new game"))
	assert_true(title.is_showing_slots(), "Start new game opens the slots")
	await _click(title.find_button("Back"))
	assert_false(title.is_showing_slots(), "Back")
	await _click(title.find_button("Settings"))
	assert_true(title.settings.visible, "Settings opens")
	title.settings.close()
	await _click(title.find_button("Exit game"))
	assert_true(game.prompt.is_open(), "Exit game asks")
	game.prompt.cancel()
	SaveGame.instance().copy_to(2)
	title.show_menu()
	await _click(title.find_button("Load game"))
	assert_true(title.is_showing_slots(), "Load game opens the slots")
	assert_eq(title._slots_title.text, "LOAD GAME")


func test_load_game_is_disabled_with_no_saves() -> void:
	assert_true(_title().load_button.disabled)


func test_a_new_game_in_an_empty_slot_starts_act_1_on_the_difficulty_picked() -> void:
	_title().show_slots(false)
	_title().slot_list.buttons[1].pressed.emit()
	assert_true(_title().is_showing_difficulty(), "the difficulty comes first")
	assert_false(SaveGame.instance().slot_exists(2), "nothing written yet")
	_title().difficulty_buttons[Difficulty.HARD].pressed.emit()
	await wait_process_frames(2)
	assert_is(game.screen, Stage)
	assert_eq((game.screen as Stage).run.stage_id, "1-1")
	assert_true((game.screen as Stage).run.tutorial)
	assert_eq((game.screen as Stage).run.difficulty, Difficulty.HARD)
	assert_eq(SaveGame.instance().slot, 2)
	assert_true(SaveGame.instance().slot_exists(2))
	var loaded := SaveGame.new(SaveGame.instance().prefix)
	loaded.load_slot(2)
	assert_eq(loaded.difficulty, Difficulty.HARD, "written with the new game")


func test_the_difficulty_page_says_it_cannot_be_changed_later() -> void:
	_title().show_difficulty(1)
	var texts: Array[String] = []
	for label: Label in _title()._difficulty_page.find_children("*", "Label", true, false):
		texts.append(label.text)
	assert_has(texts, "Enemy HP and damage. It can't be changed later.")


func test_the_difficulty_page_lists_the_four_levels() -> void:
	_title().show_difficulty(1)
	var texts := _title().difficulty_buttons.map(func(button: Button) -> String: return button.text)
	assert_eq(texts, ["Easy   ×0.8", "Normal   ×1.0", "Hard   ×1.1", "Extreme   ×1.3"])
	for level in Difficulty.LEVELS:
		assert_eq(_title().difficulty_buttons[level].get_meta(&"hover_text"), Difficulty.describe(level))
		assert_string_contains(_title().difficulty_buttons[level].get_meta(&"hover_text"), "Resolve", "R1: what the level does to Resolve")
	assert_not_null(_title().find_button("Back"))


func test_back_and_esc_on_the_difficulty_page_return_to_the_slots() -> void:
	_title().show_slots(false)
	_title().slot_list.buttons[0].pressed.emit()
	_title().find_button("Back").pressed.emit()
	assert_true(_title().is_showing_slots())
	assert_false(_title().is_showing_difficulty())
	_title().slot_list.buttons[0].pressed.emit()
	var esc := InputEventAction.new()
	esc.action = &"open_menu"
	esc.pressed = true
	_title()._input(esc)
	assert_true(_title().is_showing_slots())
	assert_false(SaveGame.instance().slot_exists(1), "no game started")


func test_the_difficulty_page_fits_and_clears_the_figures() -> void:
	var title := _title()
	title.show_difficulty(1)
	await wait_process_frames(2)
	var column := title.column.get_global_rect()
	assert_true(title.get_global_rect().encloses(column), "%s on screen" % column)
	for figure: TitleFigure in [title.backdrop.lucian, title.backdrop.senna]:
		assert_lt(figure.get_global_rect().end.x, column.position.x, figure.name)
	assert_gt(title.backdrop.thresh.get_global_rect().position.x, column.end.x)


func test_a_new_game_on_a_used_slot_asks_first() -> void:
	SaveGame.instance().copy_to(3)
	_title().show_slots(false)
	_title().slot_list.buttons[2].pressed.emit()
	assert_true(_title().confirm.is_open())
	assert_eq(_choices(_title().confirm), "Yes / No", "Overwrite stays Yes / No")
	_title().confirm.answer(false)
	assert_is(game.screen, TitleScreen)
	assert_false(_title().is_showing_difficulty())
	_title().slot_list.buttons[2].pressed.emit()
	_title().confirm.answer(true)
	assert_true(_title().is_showing_difficulty(), "Yes goes on to the difficulty")


func test_load_game_opens_the_main_screen_on_that_slot() -> void:
	SaveGame.instance().essences.add(Essences.BLUE, 77)
	SaveGame.instance().copy_to(3)
	SaveGame.instance().reset()
	game.show_title()
	await wait_process_frames(1)
	assert_false(_title().load_button.disabled)
	_title().show_slots(true)
	assert_true(_title().slot_list.buttons[0].disabled, "empty slot 1")
	_title().slot_list.buttons[2].pressed.emit()
	await wait_process_frames(2)
	assert_is(game.screen, MainScreen)
	assert_eq(SaveGame.instance().slot, 3)
	assert_eq(SaveGame.instance().essences.amount(Essences.BLUE), 77)


func test_esc_goes_back_from_the_slot_list() -> void:
	_title().show_slots(true)
	var esc := InputEventAction.new()
	esc.action = &"open_menu"
	esc.pressed = true
	_title()._input(esc)
	assert_false(_title().is_showing_slots())


func test_exit_game_asks_and_exit_quits() -> void:
	_title().find_button("Exit game").pressed.emit()
	assert_false(quit_called, "not before Exit")
	assert_true(game.prompt.is_open())
	assert_eq(game.prompt._message.text, "Exit the game?")
	assert_eq(_choices(game.prompt), "Exit / Cancel")
	game.prompt.answer(true)
	assert_true(quit_called)


func test_the_window_close_on_the_title_asks_and_exit_quits() -> void:
	game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_false(quit_called, "not before Exit")
	assert_eq(game.prompt._message.text, "Exit the game?")
	assert_eq(_choices(game.prompt), "Exit / Cancel")
	game.prompt.answer(true)
	assert_true(quit_called)


func test_cancel_on_exit_game_stays_on_the_title() -> void:
	_title().find_button("Exit game").pressed.emit()
	game.prompt.cancel()
	assert_false(game.prompt.is_open())
	assert_false(quit_called)
	assert_is(game.screen, TitleScreen)
	game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	game.prompt.cancel()
	assert_false(quit_called)
	assert_is(game.screen, TitleScreen)


func test_esc_on_exit_game_is_cancel() -> void:
	_title().find_button("Exit game").pressed.emit()
	_press_esc()
	assert_false(game.prompt.is_open())
	assert_false(quit_called)
	assert_is(game.screen, TitleScreen)


func test_leave_to_main_menu_asks_then_shows_the_title() -> void:
	game.show_main_screen()
	await wait_process_frames(1)
	(game.screen as MainScreen).gear.find_button("Leave to main menu").pressed.emit()
	assert_true(game.prompt.is_open())
	game.prompt.answer(true)
	await wait_process_frames(2)
	assert_is(game.screen, TitleScreen)
	assert_true(SaveGame.instance().slot_exists(SaveGame.instance().slot))


func test_cancel_on_leave_to_main_menu_keeps_the_gear_menu_open() -> void:
	game.show_main_screen()
	await wait_process_frames(1)
	var main := game.screen as MainScreen
	main.gear.open()
	main.gear.find_button("Leave to main menu").pressed.emit()
	assert_eq(game.prompt._message.text, "Save before leaving?")
	assert_eq(_choices(game.prompt), "Yes / No / Cancel")
	game.prompt.cancel()
	await wait_process_frames(2)
	assert_false(game.prompt.is_open())
	assert_eq(game.screen, main)
	assert_true(main.gear.visible)
	assert_false(SaveGame.instance().slot_exists(SaveGame.instance().slot), "no save")


func test_esc_on_leave_to_main_menu_is_cancel() -> void:
	game.show_main_screen()
	await wait_process_frames(1)
	var main := game.screen as MainScreen
	main.gear.open()
	main.gear.find_button("Leave to main menu").pressed.emit()
	_press_esc()
	assert_false(game.prompt.is_open())
	assert_eq(game.screen, main)
	assert_true(main.gear.visible, "the gear menu didn't read that ESC")


func test_play_time_counts_off_the_title_screen_only() -> void:
	await wait_seconds(0.3)
	assert_eq(SaveGame.instance().play_time, 0.0)
	game.show_main_screen()
	await wait_seconds(0.3)
	assert_gt(SaveGame.instance().play_time, 0.2)


func test_the_slot_list_shows_play_time() -> void:
	SaveGame.instance().add_play_time(5025.0)
	SaveGame.instance().copy_to(2)
	_title().show_slots(true)
	assert_string_contains(_title().slot_list.row_text(1), "1h 23m")


func test_a_used_slot_leaves_room_around_its_text() -> void:
	SaveGame.instance().add_play_time(99.0 * 3600.0 + 59.0 * 60.0)
	SaveGame.instance().copy_to(2)
	_title().show_slots(false)
	var button := _title().slot_list.buttons[1]
	# The text's own width (and the button's padding) must not set the width.
	assert_lte(button.get_minimum_size().x + 40.0, SlotList.BUTTON_SIZE.x, _title().slot_list.row_text(1))


func _break_slot(n: int) -> void:
	var save := SaveGame.instance()
	var file := FileAccess.open(save.path(n), FileAccess.WRITE)
	file.store_string("{not json")
	file.close()


func test_a_broken_slot_says_so_and_loading_it_only_offers_a_new_game() -> void:
	SaveGame.instance().essences.add(Essences.BLUE, 42)
	_break_slot(2)
	game.show_title()
	await wait_process_frames(1)
	assert_false(_title().load_button.disabled, "a broken slot still opens the list, to explain it")
	_title().show_slots(true)
	var button := _title().slot_list.buttons[1]
	assert_eq(_title().slot_list.row_text(1), "Slot 2 · can't be read")
	assert_false(button.disabled)
	assert_eq(button.get_theme_color(&"font_color"), UiStyle.ERROR_COLOR)
	button.pressed.emit()
	await wait_process_frames(2)
	assert_is(game.screen, TitleScreen, "never loaded")
	assert_eq(SaveGame.instance().slot, 1)
	assert_eq(SaveGame.instance().essences.amount(Essences.BLUE), 42, "the game in memory is untouched")
	assert_true(_title().confirm.is_open())
	assert_eq(_title().confirm._message.text, TitleScreen.BROKEN_LOAD % 2)
	assert_eq(_choices(_title().confirm), "New game / Cancel")
	_title().confirm.answer(true)
	assert_true(_title().is_showing_difficulty(), "New game goes on to the difficulty")
	assert_eq(_title()._new_slot, 2)


func test_a_new_game_on_a_broken_slot_asks_to_overwrite_it() -> void:
	_break_slot(3)
	_title().show_slots(false)
	_title().slot_list.buttons[2].pressed.emit()
	assert_true(_title().confirm.is_open())
	assert_eq(_title().confirm._message.text, TitleScreen.BROKEN_OVERWRITE % 3)
	_title().confirm.answer(true)
	assert_true(_title().is_showing_difficulty())
	assert_eq(_title()._new_slot, 3)


func test_a_failed_new_game_save_shows_in_red_and_starts_nothing() -> void:
	SaveGame.instance().load_slot(1)
	SaveGame.instance().essences.add(Essences.BLUE, 7)
	var kept := SaveGame.instance().to_dict()
	SaveGame.instance().prefix = BROKEN_PREFIX
	var title := _title()
	watch_signals(title)
	title.show_slots(false)
	title.slot_list.buttons[1].pressed.emit()
	title.difficulty_buttons[Difficulty.HARD].pressed.emit()
	assert_true(title.is_showing_difficulty(), "the player stays on the difficulty page")
	assert_eq(title.notice_label.text, "Could not write slot 2. The game can't start until it can save.")
	assert_true(title.notice_label.is_visible_in_tree(), "the notice shows on this page")
	assert_signal_not_emitted(title, "new_game_started")
	assert_is(game.screen, TitleScreen, "nothing started")
	assert_eq(SaveGame.instance().slot, 1, "the old slot is back")
	var now := SaveGame.instance().to_dict()
	kept.erase("saved_at")
	now.erase("saved_at")
	assert_eq(now, kept, "and its data")
	assert_push_warning_count(1)


func test_back_from_the_difficulty_page_clears_the_failed_save_notice() -> void:
	SaveGame.instance().prefix = BROKEN_PREFIX
	var title := _title()
	title.show_slots(false)
	title.slot_list.buttons[1].pressed.emit()
	title.difficulty_buttons[Difficulty.NORMAL].pressed.emit()
	assert_ne(title.notice_label.text, "")
	title.find_button("Back").pressed.emit()
	assert_true(title.is_showing_slots())
	assert_eq(title.notice_label.text, "", "Back clears it")
	assert_eq(title.error_label.text, "")
	assert_push_warning_count(1)
