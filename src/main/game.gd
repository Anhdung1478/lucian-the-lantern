class_name Game
extends Node
## The root scene. Opens on the title screen; a slot leads to the main screen,
## which swaps in a stage and comes back when it ends (the stage-done
## auto-save). Every exit asks first, and Cancel (or ESC) stays: leaving to
## the title or the game, from a menu or the window's close button, asks
## "Save before leaving?" Yes / No / Cancel; Leave this stage asks Leave /
## Cancel; on the title (nothing to save) Exit and the X ask Exit / Cancel.

const STAGE_SCENE := preload("res://src/stage/stage.tscn")
## Above the screens' own pop-ups (ConfirmPopup.LAYER), which can be open
## when the window is closed: the prompt is drawn on top and gets clicks first.
const PROMPT_LAYER := 90

## The TitleScreen, the MainScreen, the Stage being played or the TheEndScreen.
var screen: Node
## The stage being played, for its id when it ends.
var _run := StageSetup.new()
var prompt := ConfirmPopup.new(PROMPT_LAYER)
## Replaced in tests, which must not close the test run.
var quit_game := func() -> void: get_tree().quit()

## Whether the tree was paused before the prompt paused it.
var _was_paused := false
## Rolls an Endless Retry's map when the choice is Random.
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
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


## The window's X: "Exit the game?" on the title screen, else "Save before leaving?".
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if screen is TitleScreen:
			ask_to_exit()
		else:
			ask_to_quit()


func show_title() -> void:
	var title := TitleScreen.new()
	title.new_game_started.connect(func() -> void: start_stage(StageSetup.for_stage(SaveGame.instance(), 1, 1)))
	title.game_loaded.connect(show_main_screen)
	title.exit_requested.connect(ask_to_exit)
	_swap(title)


## The title screen has nothing unsaved: its Exit and the window's X ask
## "Exit the game?" Exit / Cancel.
func ask_to_exit() -> void:
	if prompt.is_open():
		return
	prompt.confirm("Exit the game?", "Exit", quit_game)


## Leave to main menu: "Save before leaving?" Yes saves and No doesn't, then
## the title screen; Cancel stays, with the gear menu still open.
func ask_to_leave() -> void:
	if prompt.is_open():
		return
	prompt.ask_or_cancel("Save before leaving?", _leave.bind(true), _leave.bind(false))


func _leave(save: bool) -> void:
	if save and not _save():
		prompt.ask("Could not save. Leave anyway?", show_title, Callable(), false)
		return
	show_title()


## `focus_act`: the act the Journey opens on; `focus_endless`: it opens on
## Endless instead (after a run), with `endless_map` (the run's map choice)
## still chosen.
func show_main_screen(focus_act := 0, focus_endless := false, endless_map := EndlessPlan.RANDOM) -> void:
	var main := MainScreen.new()
	main.focus_act = focus_act
	main.focus_endless = focus_endless
	main.endless_map = endless_map
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
	stage.leave_requested.connect(ask_to_leave_stage.bind(stage))
	_swap(stage)


## Leave this stage, from the stage's ESC menu: Leave ends the stage as left
## (the stage-done auto-save, then the main screen); Cancel goes back to the
## menu, still paused.
func ask_to_leave_stage(stage: Stage) -> void:
	if prompt.is_open():
		return
	prompt.confirm(_leave_stage_question(), "Leave", stage.leave)


## What Leave this stage asks (Endless: leave the run; Training earns no essences).
func _leave_stage_question() -> String:
	if _run.endless:
		return "Leave this run? Your best wave is kept."
	if _run.act == 0:
		return "Leave Training?"
	return "Leave this stage? Essences collected so far are kept."


## "Save before leaving?": Yes saves to the current slot (inside a stage
## that keeps what was collected, as leaving it would), then the game closes;
## No closes it without saving; Cancel keeps playing. If the save fails,
## "Could not save. Quit anyway?": No keeps playing.
func ask_to_quit() -> void:
	if prompt.is_open():
		return
	_was_paused = get_tree().paused
	get_tree().paused = true
	prompt.ask_or_cancel("Save before leaving?", _quit.bind(true), _quit.bind(false), _keep_playing)


func _quit(save: bool) -> void:
	if save and not _save():
		prompt.ask("Could not save. Quit anyway?", quit_game, _keep_playing, false)
		return
	quit_game.call()


## Saves the current slot (an Endless run's best with it: it is kept in
## memory as each wave is won). On a stage's result panel the stage is done
## first, as Continue would, so a clear is not lost; an Endless run has no
## id to clear, so `cleared` never gets "endless".
func _save() -> bool:
	var stage := screen as Stage
	if stage and stage.result.visible:
		var id := "" if _run.endless else _run.stage_id
		return SaveGame.instance().finish_stage(&"cleared" if stage.result.cleared else &"failed", id)
	return SaveGame.instance().save()


## Unpauses, unless something else (the stage's ESC menu) had paused first.
func _keep_playing() -> void:
	get_tree().paused = _was_paused


## Deferred: the stage is still inside its own signal here. `then` is the
## player's choice: retry or next start that stage; the title screen after
## losing the tutorial (Act 1 before its first clear); otherwise the main
## screen. A failed save sends retry and next to the main screen, where it
## shows; so does next after the last stage. An Endless run ends its own way
## (_end_run).
func _on_stage_finished(result: StringName, then: StringName) -> void:
	if _run.endless:
		_end_run(result, then)
		return
	var act := _run.act
	var stage := _run.stage
	var next := Journey.next_stage(act, stage)
	# Before finish_stage records it.
	var story_ends := result == &"cleared" and next == Vector2i.ZERO and not _run.stage_id in SaveGame.instance().cleared
	var saved := SaveGame.instance().finish_stage(result, _run.stage_id)
	if result == &"failed" and _run.tutorial:
		then = &"title"
	if not saved and then in [&"retry", &"next"]:
		then = &"main"
	if then == &"next" and next == Vector2i.ZERO:
		then = &"main"
	if story_ends:
		_show_the_end.call_deferred(then, saved)
		return
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


## An Endless run is over (Lucian fell or the player left): the stage-done
## auto-save keeps the best, with no stage id, so `cleared` never gets
## "endless". Retry starts a new run on the same map choice (Random rolls
## again); otherwise, and when the save failed, the main screen with the
## Journey on Endless.
func _end_run(result: StringName, then: StringName) -> void:
	var saved := SaveGame.instance().finish_stage(result, "")
	if saved and then == &"retry":
		start_stage.call_deferred(StageSetup.for_endless(SaveGame.instance(), _run.map_choice, _rng))
		return
	show_main_screen.call_deferred(0, true, _run.map_choice)
	if not saved:
		_report_save_failed.call_deferred()


## The story's end, after the stage-end screen's button; Continue goes where
## that button said (retry: the stage again, else the main screen). A failed
## save shows its toast on the main screen, as for any stage.
func _show_the_end(then: StringName, saved: bool) -> void:
	var act := _run.act
	var stage := _run.stage
	var end := TheEndScreen.new()
	end.continue_pressed.connect(func() -> void:
		if then == &"retry":
			start_stage(StageSetup.for_stage(SaveGame.instance(), act, stage))
		else:
			show_main_screen(act)
			if not saved:
				_report_save_failed())
	_swap(end)


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
