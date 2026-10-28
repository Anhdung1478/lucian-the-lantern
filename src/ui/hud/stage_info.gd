class_name StageInfo
extends PanelContainer
## Top center of the stage: the stage's name, "Wave 2/3" (or "Boss wave")
## and the enemies left; before a wave, "Wave 2 in 0:17" and Skip. Training
## shows only its name. Only the Skip button takes clicks.

signal skip_pressed

var runner: WaveRunner
var name_label := UiStyle.label("", 20, UiStyle.TITLE_COLOR)
var wave_label := UiStyle.label("", 20, UiStyle.TEXT_COLOR)
var enemies_label := UiStyle.label("", 20, UiStyle.TEXT_COLOR)
var timer_label := UiStyle.label("", 20, UiStyle.GOLD_COLOR)
var skip_button := Button.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 22)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	for label in [name_label, wave_label, enemies_label, timer_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
	skip_button.text = "Skip"
	skip_button.custom_minimum_size = Vector2(90, 34)
	UiStyle.style_button(skip_button, 18)
	skip_button.set_meta(&"hover_text", "Start the next wave now. Lucian still gets the health and mana regen of the time skipped.")
	skip_button.pressed.connect(skip_pressed.emit)
	row.add_child(skip_button)


func setup(stage_name: String, stage_runner: WaveRunner) -> void:
	name_label.text = stage_name
	runner = stage_runner
	refresh()


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	var waiting := runner != null and runner.is_waiting()
	wave_label.visible = runner != null and not waiting
	enemies_label.visible = runner != null and not waiting
	timer_label.visible = waiting
	skip_button.visible = waiting
	if runner == null:
		return
	if waiting:
		var next := runner.wave + 1
		var what := "Boss wave" if next > runner.wave_count() else "Wave %d" % next
		timer_label.text = "%s in %s" % [what, StageResult.clock(runner.countdown())]
	else:
		wave_label.text = "Boss wave" if runner.is_boss_wave() else "Wave %d/%d" % [runner.wave, runner.wave_count()]
		enemies_label.text = "Enemies: %d" % runner.alive()
