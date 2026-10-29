class_name StageResult
extends CanvasLayer
## The end of a stage, full screen over a paused game: STAGE CLEARED or
## DEFEATED (GAME OVER when the tutorial is lost, or the caller's own title:
## Endless's RUN OVER), the stage, a stats column and a rewards column, then
## Retry, Next stage and Main screen (a single Back to title after a game
## over).

## The button pressed: &"retry", &"next", &"main" or &"title".
signal chosen(then: StringName)

const LAYER := 42
const REWARD_COLOR := Color("5ad07a")
const PANEL_WIDTH := 1040.0
const BUTTON_SIZE := Vector2(260, 60)
const CLEARED_GLOW := Color(1.0, 0.78, 0.3, 0.22)
const DEFEATED_GLOW := Color(0.7, 0.05, 0.05, 0.28)

var cleared := false
## The tutorial was lost: the only way out is back to the title screen.
var game_over := false
var title: Label
var retry_button: Button
var next_button: Button
var main_button: Button

var _stage_label: Label
var _stats: VBoxContainer
var _rewards: VBoxContainer
var _gradient: Gradient


func _ready() -> void:
	layer = LAYER
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	_build()


## "4:32": minutes and seconds, rounded up.
static func clock(seconds: float) -> String:
	var whole := ceili(seconds)
	return "%d:%02d" % [whole / 60, whole % 60]


## `stats` is a list of [label, value] pairs, in order. `can_next`: there is a
## next stage to play (it only shows after a clear). `title_text`, when set,
## replaces the outcome's title (its color and glow stay the outcome's).
func show_result(is_cleared: bool, stage_name: String, stats: Array, collected: Dictionary, rewards: Array[String], is_game_over := false, can_next := false, title_text := "") -> void:
	cleared = is_cleared
	game_over = is_game_over and not is_cleared
	if title_text != "":
		title.text = title_text
	elif cleared:
		title.text = "STAGE CLEARED"
	else:
		title.text = "GAME OVER" if game_over else "DEFEATED"
	title.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if cleared else UiStyle.ERROR_COLOR)
	_gradient.colors = PackedColorArray([CLEARED_GLOW if cleared else DEFEATED_GLOW, Color(0, 0, 0, 0)])
	_stage_label.text = stage_name
	retry_button.visible = not game_over
	next_button.visible = cleared and can_next
	main_button.text = "Back to title" if game_over else "Main screen"
	_fill_stats(stats)
	_fill_rewards(collected, rewards)
	visible = true


func _fill_stats(stats: Array) -> void:
	for child in _stats.get_children():
		child.queue_free()
	for pair: Array in stats:
		var row := HBoxContainer.new()
		var name_label := UiStyle.label(pair[0], 22, UiStyle.TEXT_COLOR)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value_label := UiStyle.label(pair[1], 22, UiStyle.TITLE_COLOR)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(name_label)
		row.add_child(value_label)
		_stats.add_child(row)


func _fill_rewards(collected: Dictionary, rewards: Array[String]) -> void:
	for child in _rewards.get_children():
		child.queue_free()
	var any := false
	for kind: StringName in Essences.KINDS:
		if collected[kind] <= 0:
			continue
		any = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 10)
		var icon := TextureRect.new()
		icon.texture = Stage.ESSENCE_ICONS[kind]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(32, 32)
		row.add_child(icon)
		row.add_child(UiStyle.label("+%d %s essence" % [collected[kind], kind], 22, Stage.ESSENCE_COLORS[kind]))
		_rewards.add_child(row)
	if not any:
		_rewards.add_child(UiStyle.label("No essences", 22, UiStyle.DIM_COLOR))
	for line in rewards:
		var reward := UiStyle.label(line, 20, REWARD_COLOR)
		reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward.custom_minimum_size = Vector2(440, 0)
		_rewards.add_child(reward)


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.85)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	# A soft glow behind the panel: a radial gradient, tinted per outcome.
	_gradient = Gradient.new()
	_gradient.colors = PackedColorArray([CLEARED_GLOW, Color(0, 0, 0, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = _gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var glow := TextureRect.new()
	glow.texture = texture
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(glow)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", UiStyle.panel())
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 16)
	panel.add_child(column)
	title = UiStyle.label("", 56, UiStyle.GOLD_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_stage_label = UiStyle.label("", 26, UiStyle.TITLE_COLOR)
	_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_stage_label)
	column.add_child(HSeparator.new())
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override(&"separation", 40)
	column.add_child(columns)
	_stats = _section(columns, "STATS")
	columns.add_child(VSeparator.new())
	_rewards = _section(columns, "REWARDS")
	column.add_child(HSeparator.new())
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 30)
	column.add_child(buttons)
	retry_button = _button(buttons, "Retry", false, &"retry")
	next_button = _button(buttons, "Next stage", false, &"next")
	main_button = _button(buttons, "Main screen", true, &"main")


## A column with its head, returning the box the rows go into.
func _section(parent: Control, head: String) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.size_flags_stretch_ratio = 1.0
	section.add_theme_constant_override(&"separation", 10)
	section.add_child(UiStyle.label(head, 20, UiStyle.DIM_COLOR))
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override(&"separation", 10)
	section.add_child(rows)
	parent.add_child(section)
	return rows


func _button(parent: Control, text: String, lit: bool, then: StringName) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	UiStyle.style_button(button, 24, lit)
	button.pressed.connect(func() -> void: chosen.emit(&"title" if game_over and then == &"main" else then))
	parent.add_child(button)
	return button

