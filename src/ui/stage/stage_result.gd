class_name StageResult
extends CanvasLayer
## The end of a stage, over a paused game: STAGE CLEARED or DEFEATED, the
## stage, the waves cleared, the essences collected and any first-clear
## reward, then Continue.

signal continue_pressed

const LAYER := 42
const REWARD_COLOR := Color("5ad07a")

var cleared := false
var title: Label
var continue_button: Button

var _lines: VBoxContainer


func _ready() -> void:
	layer = LAYER
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	_build()


## "4:32": minutes and seconds, rounded up.
static func clock(seconds: float) -> String:
	var whole := ceili(seconds)
	return "%d:%02d" % [whole / 60, whole % 60]


func show_result(is_cleared: bool, stage_name: String, waves_text: String, collected: Dictionary, rewards: Array[String]) -> void:
	cleared = is_cleared
	title.text = "STAGE CLEARED" if cleared else "DEFEATED"
	title.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if cleared else UiStyle.ERROR_COLOR)
	for child in _lines.get_children():
		child.queue_free()
	_lines.add_child(UiStyle.label(stage_name, 24, UiStyle.TITLE_COLOR))
	if waves_text != "":
		_lines.add_child(UiStyle.label(waves_text, 20, UiStyle.TEXT_COLOR))
	var essences := HBoxContainer.new()
	essences.add_theme_constant_override(&"separation", 10)
	_lines.add_child(essences)
	for kind: StringName in Essences.KINDS:
		if collected[kind] > 0:
			var icon := TextureRect.new()
			icon.texture = Stage.ESSENCE_ICONS[kind]
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.custom_minimum_size = Vector2(32, 32)
			essences.add_child(icon)
			essences.add_child(UiStyle.label("+%d" % collected[kind], 22, Stage.ESSENCE_COLORS[kind]))
	if essences.get_child_count() == 0:
		essences.add_child(UiStyle.label("No essences", 20, UiStyle.DIM_COLOR))
	for line in rewards:
		_lines.add_child(UiStyle.label(line, 20, REWARD_COLOR))
	visible = true


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", UiStyle.panel())
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 16)
	panel.add_child(column)
	title = UiStyle.label("", 40, UiStyle.GOLD_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	column.add_child(HSeparator.new())
	_lines = VBoxContainer.new()
	_lines.add_theme_constant_override(&"separation", 10)
	column.add_child(_lines)
	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(320, 60)
	UiStyle.style_button(continue_button, 26, true)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_button.pressed.connect(continue_pressed.emit)
	column.add_child(continue_button)
