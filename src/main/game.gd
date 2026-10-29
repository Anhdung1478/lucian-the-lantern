class_name Game
extends Node
## The root scene. Opens on the title screen; a slot leads to the main screen,
## which swaps in a stage and comes back when it ends (the stage-done
## auto-save). Leaving to the title or the game, from a menu or the window's
## close button, asks "Save before leaving?" (the title itself has nothing to save).

const STAGE_SCENE := preload("res://src/stage/stage.tscn")
## Above the screens' own pop-ups (ConfirmPopup.LAYER), which can be open
## when the window is closed: the prompt is drawn on top and gets clicks first.
const PROMPT_LAYER := 90

## The TitleScreen, the MainScreen or the Stage being played.
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
	show_title()


## Play time, for the slot lists: everywhere but the title screen. Game pauses
## with the tree, so pauses don't count.
func _process(delta: float) -> void:
	if screen and not screen is TitleScreen:
		SaveGame.instance().add_play_time(delta)


## The title screen has nothing unsaved: its Exit and the window's X quit at once.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if screen is TitleScreen:
			quit_game.call()
		else:
			ask_to_quit()


func show_title() -> void:
	var title := TitleScreen.new()
	title.new_game_started.connect(func() -> void: start_stage(StageSetup.for_stage(SaveGame.instance(), 1, 1)))
	title.game_loaded.connect(show_main_screen)
	title.exit_requested.connect(func() -> void: quit_game.call())
	_swap(title)


## Leave to main menu: "Save before leaving?", then the title screen.
func ask_to_leave() -> void:
	if prompt.is_open():
		return
	prompt.ask("Save before leaving?", _leave.bind(true), _leave.bind(false), false)


func _leave(save: bool) -> void:
	if save and not _save():
		prompt.ask("Could not save. Leave anyway?", show_title, Callable(), false)
		return
	show_title()


func show_main_screen(focus_act := 0) -> void:
	var main := MainScreen.new()
	main.focus_act = focus_act
	main.start_requested.connect(start_stage)
	main.exit_requested.connect(ask_to_quit)
	main.leave_requested.connect(ask_to_leave)
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
	if save and not _save():
		prompt.ask("Could not save. Quit anyway?", quit_game, _keep_playing, false)
		return
	quit_game.call()


## Saves the current slot. On a stage's result panel the stage is done
## first, as Continue would, so a clear is not lost.
func _save() -> bool:
	var stage := screen as Stage
	if stage and stage.result.visible:
		return SaveGame.instance().finish_stage(&"cleared" if stage.result.cleared else &"failed", _run.stage_id)
	return SaveGame.instance().save()


## Unpauses, unless something else (the stage's ESC menu) had paused first.
func _keep_playing() -> void:
	get_tree().paused = _was_paused


## Deferred: the stage is still inside its own signal here. `then` is the
## player's choice: retry or next start that stage; the title screen after
## losing the tutorial (Act 1 before its first clear); otherwise the main
## screen. A failed save sends retry and next to the main screen, where it
## shows; so does next after the last stage.
func _on_stage_finished(result: StringName, then: StringName) -> void:
	var saved := SaveGame.instance().finish_stage(result, _run.stage_id)
	var act := _run.act
	var stage := _run.stage
	var next := Journey.next_stage(act, stage)
	if result == &"failed" and _run.tutorial:
		then = &"title"
	if not saved and then in [&"retry", &"next"]:
		then = &"main"
	if then == &"next" and next == Vector2i.ZERO:
		then = &"main"
	match then:
		&"title":
			show_title.call_deferred()
		&"retry":
			start_stage.call_deferred(StageSetup.for_stage(SaveGame.instance(), act, stage))
		&"next":
			start_stage.call_deferred(StageSetup.for_stage(SaveGame.instance(), next.x, next.y))
		_:
			show_main_screen.call_deferred(act)
	if not saved:
		_report_save_failed.call_deferred()


func _report_save_failed() -> void:
	if screen is MainScreen:
		(screen as MainScreen).show_toast("Could not save", true)
	elif screen is TitleScreen:
		(screen as TitleScreen).notice_label.text = "Could not save"


## The old screen goes at once; the prompt stays last so it gets input first.
func _swap(next: Node) -> void:
	if screen:
		remove_child(screen)
		screen.queue_free()
	get_tree().paused = false
	screen = next
	add_child(next)
	move_child(next, 0)
