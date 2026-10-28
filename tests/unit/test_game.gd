extends GutTest

const PREFIX := "user://test_game_save_slot_"

var game: Game
var quit_called := false


func before_each() -> void:
	quit_called = false
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new(PREFIX)
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


func test_starts_on_the_main_screen() -> void:
	assert_is(game.screen, MainScreen)


func test_training_swaps_in_the_stage_with_its_setup() -> void:
	var run := StageSetup.new()
	run.equip_slots = 2
	game.start_stage(run)
	await wait_frames(2)
	assert_is(game.screen, Stage)
	assert_eq((game.screen as Stage).lucian.inventory.unlocked_equip, 2)


func test_leaving_the_stage_saves_and_returns() -> void:
	game.start_stage(StageSetup.new())
	await wait_frames(2)
	(game.screen as Stage).screens.menu.leave_requested.emit()
	await wait_frames(2)
	assert_true(FileAccess.file_exists(SaveGame.instance().path(1)))
	assert_is(game.screen, MainScreen)
	assert_false(get_tree().paused)


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


func test_window_close_asks() -> void:
	game.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	assert_true(game.prompt.is_open())
