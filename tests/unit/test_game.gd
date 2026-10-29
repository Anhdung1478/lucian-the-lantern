extends GutTest

const PREFIX := "user://test_game_save_slot_"
## A folder that doesn't exist: every save fails.
const BROKEN_PREFIX := "user://no_such_dir/test_game_save_slot_"

var game: Game
var quit_called := false
var _prefix := ""


func before_each() -> void:
	quit_called = false
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new(PREFIX)
	_prefix = SaveGame.instance().prefix
	SaveGame.instance().reset()
	for file in [SaveGame.instance().path(1), SaveGame.instance().backup_path(1)]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	game = load("res://src/main/game.tscn").instantiate()
	game.quit_game = func() -> void: quit_called = true
	add_child_autofree(game)


## The prompt and the ESC menu pause the tree; never leave GUT paused.
func after_each() -> void:
	get_tree().paused = false
	# A stage ended into a save: other tests expect no slot file.
	for file in [SaveGame.instance().path(1), SaveGame.instance().backup_path(1)]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	SaveGame.instance().prefix = _prefix


func _leave_button(stage: Stage) -> Button:
	for button: Button in stage.screens.menu.find_children("*", "Button", true, false):
		if button.text == "Leave this stage":
			return button
	return null


## The prompt's buttons on screen, in order: "Yes / No / Cancel".
func _choices() -> String:
	var labels := PackedStringArray()
	for button: Button in game.prompt.find_children("*", "Button", true, false):
		if button.visible:
			labels.append(button.text)
	return " / ".join(labels)


func _prompt_button(text: String) -> Button:
	for button: Button in game.prompt.find_children("*", "Button", true, false):
		if button.visible and button.text == text:
			return button
	return null


## A real ESC press and release, through the viewport: whoever reads it first wins.
func _press_esc() -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ESCAPE
		key.physical_keycode = KEY_ESCAPE
		key.pressed = pressed
		Input.parse_input_event(key)
	Input.flush_buffered_events()


## A stage under the Game, with its ESC menu open (the tree paused).
func _stage_with_the_menu_open() -> Stage:
	game.start_stage(StageSetup.new())
	await wait_physics_frames(2)
	var stage := game.screen as Stage
	stage.screens.set_menu_open(true)
	return stage


func test_starts_on_the_title_screen() -> void:
	assert_is(game.screen, TitleScreen)


func test_training_swaps_in_the_stage_with_its_setup() -> void:
	var run := StageSetup.new()
	run.equip_slots = 2
	game.start_stage(run)
	await wait_process_frames(2)
	assert_is(game.screen, Stage)
	assert_eq((game.screen as Stage).lucian.inventory.unlocked_equip, 2)


func test_leaving_the_stage_asks_then_saves_and_returns() -> void:
	var stage: Stage = await _stage_with_the_menu_open()
	_leave_button(stage).pressed.emit()
	assert_true(game.prompt.is_open())
	assert_eq(game.prompt._message.text, "Leave this stage? Essences collected so far are kept.")
	assert_eq(_choices(), "Leave / Cancel")
	assert_eq(game.screen, stage, "nothing happens before Leave")
	_prompt_button("Leave").pressed.emit()
	await wait_process_frames(2)
	assert_true(FileAccess.file_exists(SaveGame.instance().path(1)))
	assert_is(game.screen, MainScreen)
	assert_false(get_tree().paused)


func test_cancel_on_leave_this_stage_goes_back_to_the_esc_menu() -> void:
	var stage: Stage = await _stage_with_the_menu_open()
	_leave_button(stage).pressed.emit()
	_prompt_button("Cancel").pressed.emit()
	assert_false(game.prompt.is_open())
	assert_eq(game.screen, stage)
	assert_true(stage.screens.menu.visible)
	assert_true(get_tree().paused, "the ESC menu is still open")
	assert_false(FileAccess.file_exists(SaveGame.instance().path(1)))


func test_esc_on_leave_this_stage_is_cancel() -> void:
	var stage: Stage = await _stage_with_the_menu_open()
	_leave_button(stage).pressed.emit()
	_press_esc()
	assert_false(game.prompt.is_open())
	assert_eq(game.screen, stage)
	assert_true(stage.screens.menu.visible, "the ESC menu didn't read that ESC")
	assert_true(get_tree().paused)
	assert_false(FileAccess.file_exists(SaveGame.instance().path(1)))


func test_quit_asks_and_yes_saves() -> void:
	game.ask_to_quit()
	assert_true(game.prompt.is_open())
	game.prompt.answer(true)
	assert_true(FileAccess.file_exists(SaveGame.instance().path(1)))
	assert_true(quit_called)


func test_quit_no_leaves_without_saving() -> void:
	game.ask_to_quit()
	game.prompt.answer(false)
	assert_false(FileAccess.file_exists(SaveGame.instance().path(1)))
	assert_true(quit_called)


func test_cancel_on_exit_in_a_stage_keeps_the_esc_menu_paused() -> void:
	var stage: Stage = await _stage_with_the_menu_open()
	stage.screens.menu.exit_requested.emit()
	assert_eq(game.prompt._message.text, "Save before leaving?")
	assert_eq(_choices(), "Yes / No / Cancel")
	game.prompt.cancel()
	assert_false(game.prompt.is_open())
	assert_false(quit_called)
	assert_false(FileAccess.file_exists(SaveGame.instance().path(1)))
	assert_eq(game.screen, stage)
	assert_true(stage.screens.menu.visible)
	assert_true(get_tree().paused, "the ESC menu is still open")


func test_cancel_on_exit_on_the_main_screen_unpauses() -> void:
	game.show_main_screen()
	await wait_process_frames(1)
	var main := game.screen as MainScreen
	main.gear.open()
	main.gear.find_button("Exit the game").pressed.emit()
	assert_true(get_tree().paused, "the prompt pauses")
	_prompt_button("Cancel").pressed.emit()
	assert_false(game.prompt.is_open())
	assert_false(quit_called)
	assert_false(FileAccess.file_exists(SaveGame.instance().path(1)))
	assert_false(get_tree().paused, "the pause is as it was")
	assert_eq(game.screen, main)
	assert_true(main.gear.visible)


func test_esc_on_exit_in_a_stage_is_cancel() -> void:
	var stage: Stage = await _stage_with_the_menu_open()
	stage.screens.menu.exit_requested.emit()
	_press_esc()
	assert_false(game.prompt.is_open())
	assert_false(quit_called)
	assert_false(FileAccess.file_exists(SaveGame.instance().path(1)))
	assert_true(stage.screens.menu.visible, "the ESC menu didn't read that ESC")
	assert_true(get_tree().paused)


func test_window_close_asks() -> void:
	game.show_main_screen()
	await wait_process_frames(1)
	game.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	assert_true(game.prompt.is_open())
	assert_eq(_choices(), "Yes / No / Cancel")
	game.prompt.cancel()
	assert_false(quit_called)
	assert_false(get_tree().paused)


func test_the_save_prompt_is_above_the_main_screen_popup_and_answers_alone() -> void:
	game.show_main_screen()
	await wait_process_frames(1)
	var main := game.screen as MainScreen
	var overwrite: Array[bool] = []
	main.confirm.ask("Overwrite slot 2?", func() -> void: overwrite.append(true), func() -> void: overwrite.append(false))
	game.ask_to_quit()
	assert_true(main.confirm.is_open())
	assert_true(game.prompt.is_open())
	assert_gt(game.prompt.layer, main.confirm.layer, "drawn on top, and clicks reach it first")
	assert_eq(game.prompt.get_index(), game.get_child_count() - 1, "the prompt stays last")
	game.prompt.answer(true)
	assert_true(FileAccess.file_exists(SaveGame.instance().path(1)))
	assert_true(quit_called)
	assert_eq(overwrite, [] as Array[bool], "the screen's question isn't answered")


func test_a_failed_save_asks_to_quit_anyway() -> void:
	SaveGame.instance().prefix = BROKEN_PREFIX
	game.ask_to_quit()
	game.prompt.answer(true)
	assert_false(quit_called, "not before Yes")
	assert_true(game.prompt.is_open())
	assert_eq(game.prompt._message.text, "Could not save. Quit anyway?")
	assert_eq(_choices(), "Yes / No", "still Yes / No")
	game.prompt.answer(true)
	assert_true(quit_called)
	assert_push_warning_count(1)


func test_a_failed_save_on_leave_to_main_menu_asks_yes_or_no() -> void:
	game.show_main_screen()
	await wait_process_frames(1)
	SaveGame.instance().prefix = BROKEN_PREFIX
	game.ask_to_leave()
	game.prompt.answer(true)
	assert_eq(game.prompt._message.text, "Could not save. Leave anyway?")
	assert_eq(_choices(), "Yes / No")
	game.prompt.answer(true)
	await wait_process_frames(2)
	assert_is(game.screen, TitleScreen)
	assert_push_warning_count(1)


func test_no_after_a_failed_save_keeps_playing() -> void:
	SaveGame.instance().prefix = BROKEN_PREFIX
	game.ask_to_quit()
	game.prompt.answer(true)
	game.prompt.answer(false)
	assert_false(quit_called)
	assert_false(game.prompt.is_open())
	assert_false(get_tree().paused)
	assert_push_warning_count(1)


func test_no_after_a_failed_save_leaves_the_stage_menu_paused() -> void:
	game.start_stage(StageSetup.new())
	await wait_physics_frames(2)
	var stage := game.screen as Stage
	stage.screens.set_menu_open(true)
	SaveGame.instance().prefix = BROKEN_PREFIX
	stage.screens.menu.exit_requested.emit()
	game.prompt.answer(true)
	game.prompt.answer(false)
	assert_false(quit_called)
	assert_true(stage.screens.menu.visible)
	assert_true(get_tree().paused, "the ESC menu is still open")
	assert_push_warning_count(1)


func test_a_failed_stage_save_shows_a_red_toast() -> void:
	game.start_stage(StageSetup.new())
	await wait_physics_frames(2)
	SaveGame.instance().prefix = BROKEN_PREFIX
	(game.screen as Stage).screens.menu.leave_requested.emit()
	game.prompt.answer(true)
	await wait_physics_frames(2)
	assert_is(game.screen, MainScreen)
	var main := game.screen as MainScreen
	assert_eq(main.toast_text(), "Could not save")
	assert_eq(main._toast.get_theme_color(&"font_color"), UiStyle.ERROR_COLOR)
	assert_push_warning_count(1)


func test_leave_works_under_the_game() -> void:
	game.start_stage(StageSetup.new())
	await wait_physics_frames(2)
	var leave := _leave_button(game.screen as Stage)
	assert_false(leave.disabled)
	assert_false(leave.has_meta(&"hover_text"))


func test_leave_is_disabled_when_the_stage_runs_alone() -> void:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	add_child_autofree(stage)
	var leave := _leave_button(stage)
	assert_true(leave.disabled)
	assert_eq(leave.get_meta(&"hover_text", ""), "Not available yet")


func test_a_cleared_act_stage_is_saved_as_cleared() -> void:
	SaveGame.instance().set_cleared(Journey.all_stage_ids(1))
	game.start_stage(StageSetup.for_stage(SaveGame.instance(), 2, 1))
	await wait_process_frames(2)
	var stage := game.screen as Stage
	stage.show_result(true)
	stage.result.main_button.pressed.emit()
	await wait_process_frames(2)
	assert_true("2-1" in SaveGame.instance().cleared)
	assert_is(game.screen, MainScreen)
	var journey: JourneySection = game.screen.sections[MainScreen.SECTION_JOURNEY]
	assert_eq(journey.current, 1)


func test_retry_starts_the_same_stage_again_saved() -> void:
	SaveGame.instance().set_cleared(Journey.all_stage_ids(1))
	game.start_stage(StageSetup.for_stage(SaveGame.instance(), 2, 1))
	await wait_process_frames(2)
	var first := game.screen as Stage
	first.show_result(true)
	first.result.retry_button.pressed.emit()
	await wait_process_frames(2)
	assert_is(game.screen, Stage)
	assert_ne(game.screen, first)
	assert_eq((game.screen as Stage).run.stage_id, "2-1")
	assert_true("2-1" in SaveGame.instance().cleared)
	assert_true(FileAccess.file_exists(SaveGame.instance().path(1)))
	assert_false(get_tree().paused)


func test_next_stage_starts_the_one_after() -> void:
	SaveGame.instance().set_cleared(Journey.all_stage_ids(1))
	game.start_stage(StageSetup.for_stage(SaveGame.instance(), 2, 1))
	await wait_process_frames(2)
	var stage := game.screen as Stage
	stage.show_result(true)
	stage.result.next_button.pressed.emit()
	await wait_process_frames(2)
	assert_is(game.screen, Stage)
	assert_eq((game.screen as Stage).run.stage_id, "2-2")
	assert_true("2-1" in SaveGame.instance().cleared)


func test_next_after_the_last_stage_goes_to_the_main_screen() -> void:
	var last_act := Journey.ACTS.size()
	game._run = StageSetup.for_stage(SaveGame.instance(), last_act, Journey.stage_count(last_act))
	assert_eq(Journey.next_stage(game._run.act, game._run.stage), Vector2i.ZERO, "no stage after it")
	game._on_stage_finished(&"cleared", &"next")
	await wait_process_frames(2)
	assert_is(game.screen, TheEndScreen, "the story's first clear ends on its own screen")
	(game.screen as TheEndScreen).continue_button.pressed.emit()
	await wait_process_frames(2)
	assert_is(game.screen, MainScreen)
	# A replay goes straight to the main screen.
	game._on_stage_finished(&"cleared", &"next")
	await wait_process_frames(2)
	assert_is(game.screen, MainScreen)


func test_a_failed_save_on_retry_lands_on_the_main_screen_with_the_toast() -> void:
	SaveGame.instance().set_cleared(Journey.all_stage_ids(1))
	game.start_stage(StageSetup.for_stage(SaveGame.instance(), 2, 1))
	await wait_process_frames(2)
	SaveGame.instance().prefix = BROKEN_PREFIX
	var stage := game.screen as Stage
	stage.show_result(false)
	stage.result.retry_button.pressed.emit()
	await wait_process_frames(2)
	assert_is(game.screen, MainScreen)
	assert_eq((game.screen as MainScreen).toast_text(), "Could not save")
	assert_push_warning_count(1)


func test_losing_the_tutorial_goes_back_to_the_title() -> void:
	game.start_stage(StageSetup.for_stage(SaveGame.instance(), 1, 1))
	await wait_process_frames(2)
	var stage := game.screen as Stage
	stage.show_result(false)
	stage.result.main_button.pressed.emit()
	await wait_process_frames(2)
	assert_is(game.screen, TitleScreen)
	assert_false("1-1" in SaveGame.instance().cleared)
	assert_true(FileAccess.file_exists(SaveGame.instance().path(1)), "a lost stage still auto-saves")
	assert_false(get_tree().paused)


func test_losing_a_later_stage_goes_to_the_main_screen() -> void:
	SaveGame.instance().set_cleared(Journey.all_stage_ids(1))
	game.start_stage(StageSetup.for_stage(SaveGame.instance(), 2, 1))
	await wait_process_frames(2)
	var stage := game.screen as Stage
	stage.show_result(false)
	stage.result.main_button.pressed.emit()
	await wait_process_frames(2)
	assert_is(game.screen, MainScreen)


func test_a_failed_save_after_a_game_over_shows_on_the_title() -> void:
	game.start_stage(StageSetup.for_stage(SaveGame.instance(), 1, 1))
	await wait_process_frames(2)
	SaveGame.instance().prefix = BROKEN_PREFIX
	var stage := game.screen as Stage
	stage.show_result(false)
	stage.result.main_button.pressed.emit()
	await wait_process_frames(2)
	assert_is(game.screen, TitleScreen)
	assert_eq((game.screen as TitleScreen).notice_label.text, "Could not save")


func test_closing_the_window_on_stage_cleared_keeps_the_clear() -> void:
	SaveGame.instance().set_cleared(Journey.all_stage_ids(1))
	game.start_stage(StageSetup.for_stage(SaveGame.instance(), 2, 1))
	await wait_process_frames(2)
	(game.screen as Stage).show_result(true)
	game.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	game.prompt.answer(true)
	assert_true(quit_called)
	var saved := SaveGame.new(SaveGame.instance().prefix)
	saved.load_slot(1)
	assert_true("2-1" in saved.cleared, str(saved.cleared))
