class_name StageInfo
extends PanelContainer
## Top center of the stage: the stage's name, "Wave 2/3" (or "Boss wave")
## and the enemies left; before a wave, "Wave 2 in 0:17" and Skip. Endless
## has no last wave: "Wave 23", "Mini boss wave" or "Boss wave", and a dim
## "Best 22" line under it. Training shows only its name. Only the Skip
## button takes clicks.

signal skip_pressed

## Space between the row and Endless's "Best" line.
const LINE_GAP := 2
const BEST_FONT_SIZE := 16

var runner: WaveRunner
var name_label := UiStyle.label("", 20, UiStyle.TITLE_COLOR)
var wave_label := UiStyle.label("", 20, UiStyle.TEXT_COLOR)
var enemies_label := UiStyle.label("", 20, UiStyle.TEXT_COLOR)
var timer_label := UiStyle.label("", 20, UiStyle.GOLD_COLOR)
var skip_button := Button.new()
## Endless only: the save's best run, in waves.
var best_label := UiStyle.label("", BEST_FONT_SIZE, UiStyle.DIM_COLOR)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override(&"separation", LINE_GAP)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lines)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 22)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_child(row)
	for label in [name_label, wave_label, enemies_label, timer_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
	skip_button.text = "Skip"
	skip_button.custom_minimum_size = Vector2(90, 34)
	UiStyle.style_button(skip_button, 18)
	skip_button.set_meta(&"hover_text", "Start the next wave now. Lucian still gets the health and mana regen of the time skipped.")
	skip_button.pressed.connect(skip_pressed.emit)
	row.add_child(skip_button)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	best_label.visible = false
	lines.add_child(best_label)


func setup(stage_name: String, stage_runner: WaveRunner) -> void:
	name_label.text = stage_name
	runner = stage_runner
	refresh()


func _process(_delta: float) -> void:
	refresh()


## The height Endless's "Best" line adds under the row.
func best_height() -> float:
	return best_label.get_combined_minimum_size().y + LINE_GAP


func refresh() -> void:
	var waiting := runner != null and runner.is_waiting()
	var endless := runner is EndlessRunner
	# Endless's break after a boss wave waits for the modifier pick: no
	# countdown, no Skip.
	var held := endless and (runner as EndlessRunner).held
	wave_label.visible = runner != null and not waiting
	enemies_label.visible = runner != null and not waiting
	timer_label.visible = waiting and not held
	skip_button.visible = waiting and not held
	best_label.visible = endless
	if runner == null:
		return
	if endless:
		best_label.text = "Best %d" % SaveGame.instance().endless_best
	if waiting:
		var next := runner.wave + 1
		var what := _endless_wave(next) if endless else ("Boss wave" if next > runner.wave_count() else "Wave %d" % next)
		timer_label.text = "%s in %s" % [what, StageResult.clock(runner.countdown())]
	else:
		wave_label.text = _endless_wave(runner.wave) if endless else ("Boss wave" if runner.is_boss_wave() else "Wave %d/%d" % [runner.wave, runner.wave_count()])
		enemies_label.text = "Enemies: %d" % runner.alive()


## Endless's name for wave `w`: no "/ N", since none is the last.
func _endless_wave(w: int) -> String:
	if EndlessPlan.is_boss_wave(w):
		return "Boss wave"
	if EndlessPlan.is_mini_boss_wave(w):
		return "Mini boss wave"
	return "Wave %d" % w
