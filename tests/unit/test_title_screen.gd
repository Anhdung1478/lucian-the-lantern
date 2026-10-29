extends GutTest

var game: Game
var quit_called := false


func before_each() -> void:
	quit_called = false
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_title_save_slot_")
	_delete_slots()
	SaveGame.instance().load_slot(1)
	game = load("res://src/main/game.tscn").instantiate()
	game.quit_game = func() -> void: quit_called = true
	add_child_autofree(game)


func after_each() -> void:
	get_tree().paused = false
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


func test_the_game_opens_on_the_title_screen() -> void:
	assert_is(game.screen, TitleScreen)


func test_load_game_is_disabled_with_no_saves() -> void:
	assert_true(_title().load_button.disabled)


func test_a_new_game_in_an_empty_slot_starts_act_1() -> void:
	_title().show_slots(false)
	_title().slot_list.buttons[1].pressed.emit()
	await wait_process_frames(2)
	assert_is(game.screen, Stage)
	assert_eq((game.screen as Stage).run.stage_id, "1-1")
	assert_true((game.screen as Stage).run.tutorial)
	assert_eq(SaveGame.instance().slot, 2)
	assert_true(SaveGame.instance().slot_exists(2))


func test_a_new_game_on_a_used_slot_asks_first() -> void:
	SaveGame.instance().copy_to(3)
	_title().show_slots(false)
	_title().slot_list.buttons[2].pressed.emit()
	assert_true(_title().confirm.is_open())
	assert_eq(_choices(_title().confirm), "Yes / No", "Overwrite stays Yes / No")
	_title().confirm.answer(false)
	assert_is(game.screen, TitleScreen)


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
	assert_string_contains(_title().slot_list.buttons[1].text, "1h 23m")


func test_a_used_slot_leaves_room_around_its_text() -> void:
	SaveGame.instance().add_play_time(99.0 * 3600.0 + 59.0 * 60.0)
	SaveGame.instance().copy_to(2)
	_title().show_slots(false)
	var button := _title().slot_list.buttons[1]
	# The text's own width (and the button's padding) must not set the width.
	assert_lte(button.get_minimum_size().x + 40.0, SlotList.BUTTON_SIZE.x, button.text)
