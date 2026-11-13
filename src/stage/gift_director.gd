class_name GiftDirector
extends Node
## The Lantern's gift inside a story stage (design: Modifiers' sibling, see
## LanternGifts). The Stage adds one when the stage has 4 or more waves. At
## the start of the break after half its waves it holds the break for the
## ModifierPick of three gifts over a paused game, applies the pick and lets
## the break go. The merchant comes with the break as usual.

var stage: Stage
var runner: WaveRunner
## The gift picked (a LanternGifts id): NONE before the pick.
var gift := LanternGifts.NONE
## The pick on screen, or null.
var pick: ModifierPick
## The wave after which the pick comes.
var offer_wave := 0


## Watches `stage_runner`'s breaks (call it before the first wave).
func start(owner_stage: Stage, stage_runner: WaveRunner) -> void:
	stage = owner_stage
	runner = stage_runner
	offer_wave = LanternGifts.offer_wave(runner.wave_count())
	runner.break_started.connect(_on_break_started)


## Gift `id` is the stage's: Lucian's stats, and the kills' gold.
func choose(id: int) -> void:
	gift = id
	stage.lucian.set_gift(id)
	stage.run.gold_mult = LanternGifts.gold_mult(id)


## The break after the offer wave holds, once, never after a boss wave.
## Deferred: a shot's physics callback can end the wave.
func _on_break_started(_seconds: float) -> void:
	if runner.wave != offer_wave or runner.is_boss_wave() or gift != LanternGifts.NONE or pick:
		return
	runner.held = true
	_open_pick.call_deferred()


## The pick over a paused game, the backpack, settings and menu closed and the screens
## locked (no ESC, no P). None once the stage is over.
func _open_pick() -> void:
	if pick or not runner.held or stage.lucian.dead or stage.result.visible:
		return
	var screens := stage.screens
	if screens.backpack.visible:
		screens.set_backpack_open(false)
	if screens.settings.is_open():
		screens.set_settings_open(false)
	screens.set_menu_open(false)
	screens.locked = true
	pick = ModifierPick.new(LanternGifts.offer(stage.rng), true)
	pick.picked.connect(_on_picked)
	add_child(pick)
	get_tree().paused = true


## A card: it becomes the stage's gift, and the break counts down. Only the
## first click counts (the pick is freed at the frame's end).
func _on_picked(id: int) -> void:
	if pick == null:
		return
	choose(id)
	Sfx.play(&"buff")
	pick.queue_free()
	pick = null
	stage.screens.locked = false
	get_tree().paused = false
	runner.release()
