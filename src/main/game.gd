class_name Game
extends Node
## The root scene. Shows the main screen, swaps in a stage for Training and
## comes back when it ends (the stage-done auto-save). Leaving the game,
## from a menu or the window's close button, asks "Save before leaving?".

const STAGE_SCENE := preload("res://src/stage/stage.tscn")
## Above the screens' own pop-ups (ConfirmPopup.LAYER), which can be open
## when the window is closed: the prompt is drawn on top and gets clicks first.
const PROMPT_LAYER := 90

## The MainScreen or the Stage being played.
var screen: Node
## The stage being played, for its id when it ends.
var _run := StageSetup.new()
var prompt := ConfirmPopup.new(PROMPT_LAYER)
## Replaced in tests, which must not close the test run.
var quit_game := func() -> void: get_tree().quit()

## Whether the tree was paused before the prompt paused it.
var _was_paused := false


func _ready() -> void:
	GameSettings.instance().apply()
	get_tree().auto_accept_quit = false
	add_child(Sfx.new())
	add_child(prompt)
	show_main_screen()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		ask_to_quit()


func show_main_screen() -> void:
	var main := MainScreen.new()
	main.start_requested.connect(start_stage)
	main.exit_requested.connect(ask_to_quit)
	_swap(main)


func start_stage(run: StageSetup) -> void:
	_run = run
	var stage: Stage = STAGE_SCENE.instantiate()
	stage.setup(run)
	stage.finished.connect(_on_stage_finished)
	stage.exit_requested.connect(ask_to_quit)
	_swap(stage)


## "Save before leaving?": Yes saves to the current slot (inside a stage
## that keeps what was collected, as leaving it would), then the game closes.
## If the save fails, "Could not save. Quit anyway?": No keeps playing.
func ask_to_quit() -> void:
	if prompt.is_open():
		return
	_was_paused = get_tree().paused
	get_tree().paused = true
	prompt.ask("Save before leaving?", _quit.bind(true), _quit.bind(false), false)


func _quit(save: bool) -> void:
	if save and not SaveGame.instance().save():
		prompt.ask("Could not save. Quit anyway?", quit_game, _keep_playing, false)
		return
	quit_game.call()


## Unpauses, unless something else (the stage's ESC menu) had paused first.
func _keep_playing() -> void:
	get_tree().paused = _was_paused


## Deferred: the stage is still inside its own menu's signal here. A failed
## save shows on the new main screen.
func _on_stage_finished(result: StringName) -> void:
	var saved := SaveGame.instance().finish_stage(result, _run.stage_id)
	show_main_screen.call_deferred()
	if not saved:
		_report_save_failed.call_deferred()


func _report_save_failed() -> void:
	(screen as MainScreen).show_toast("Could not save", true)


## The old screen goes at once; the prompt stays last so it gets input first.
func _swap(next: Node) -> void:
	if screen:
		remove_child(screen)
		screen.queue_free()
	get_tree().paused = false
	screen = next
	add_child(next)
	move_child(next, 0)
