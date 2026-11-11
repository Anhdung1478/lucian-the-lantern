class_name StageInfo
extends Plate
## Top center of the stage, on a plain plate: the stage's name as a heading
## (small spaced capitals between two gold rules), and under it a row: one
## pip per wave (WavePips), "Wave 2/3" (or "Boss wave") and the enemies
## left; before a wave, "Wave 2 in 0:17" and Skip. Endless has no last wave
## and so no pips: "Wave 23", "Mini boss wave" or "Boss wave", and a dim
## "Best 22" at the row's end. Training shows only its name. Only the Skip
## button takes clicks.

signal skip_pressed

## Space between the heading and the row.
const LINE_GAP := 4
## Space between the row's parts.
const ROW_GAP := 18
const FONT_SIZE := 18
const BEST_FONT_SIZE := 16
const SKIP_SIZE := Vector2(84, 30)
const SKIP_FONT_SIZE := 16
## The room over and under Skip's text: less than a styled button's, so it is
## no taller than SKIP_SIZE.
const SKIP_MARGIN := 2.0
## The room between the plate's frame and the lines.
const PAD := 10.0

var runner: WaveRunner
var name_label: Label
var pips := WavePips.new()
var wave_label := UiStyle.label("", FONT_SIZE, UiStyle.TEXT_COLOR)
var enemies_label := UiStyle.label("", FONT_SIZE, UiStyle.TEXT_COLOR)
var timer_label := UiStyle.label("", FONT_SIZE, UiStyle.GOLD_COLOR)
var skip_button := Button.new()
## Endless only: the save's best run, in waves.
var best_label := UiStyle.label("", BEST_FONT_SIZE, UiStyle.DIM_COLOR)

var _heading := HudHeading.new()
## Everything under the heading; Training has none.
var _row := HBoxContainer.new()


func _init() -> void:
	super(PAD, false)
	opacity = Hud.PLATE_OPACITY
	name_label = _heading.label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override(&"separation", LINE_GAP)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lines)
	lines.add_child(_heading)
	_row.add_theme_constant_override(&"separation", ROW_GAP)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_child(_row)
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(pips)
	for label in [wave_label, enemies_label, timer_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_row.add_child(label)
	skip_button.text = "Skip"
	skip_button.custom_minimum_size = SKIP_SIZE
	skip_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_button(skip_button, SKIP_FONT_SIZE)
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		var box := skip_button.get_theme_stylebox(state)
		box.content_margin_top = SKIP_MARGIN
		box.content_margin_bottom = SKIP_MARGIN
	skip_button.set_meta(&"hover_text", "Start the next wave now. Lucian still gets the health and mana regen of the time skipped.")
	skip_button.pressed.connect(skip_pressed.emit)
	_row.add_child(skip_button)
	# As tall with Skip as without, so the plate never changes its height.
	_row.custom_minimum_size.y = skip_button.get_combined_minimum_size().y
	best_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	best_label.visible = false
	_row.add_child(best_label)
	refresh()


func setup(stage_name: String, stage_runner: WaveRunner) -> void:
	name_label.text = stage_name
	runner = stage_runner
	refresh()


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	var waiting := runner != null and runner.is_waiting()
	var endless := runner is EndlessRunner
	# Endless's break after a boss wave waits for the modifier pick: no
	# countdown, no Skip.
	var held := endless and (runner as EndlessRunner).held
	_row.visible = runner != null
	pips.visible = runner != null and not endless
	wave_label.visible = runner != null and not waiting
	enemies_label.visible = runner != null and not waiting
	timer_label.visible = waiting and not held
	skip_button.visible = waiting and not held
	best_label.visible = endless
	if runner == null:
		return
	if endless:
		best_label.text = "Best %d" % SaveGame.instance().endless_best
	else:
		pips.show_waves(runner.total_waves(), runner.boss != &"", runner.wave, runner.state == WaveRunner.State.FIGHT)
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
