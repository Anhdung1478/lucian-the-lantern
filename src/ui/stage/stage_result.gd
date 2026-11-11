class_name StageResult
extends CanvasLayer
## The end of a stage, full screen over a paused game, in the Lantern look:
## the game blurred behind an ornate plate with the lantern in a medallion on
## its top edge, lit warm after a clear, dim and red after a defeat. On the
## plate: STAGE CLEARED or DEFEATED (GAME OVER when the tutorial is lost, or
## the caller's own title: Endless's RUN OVER), the stage between gold rules,
## a stats column and a rewards column whose essences count up, after a defeat
## what hit Lucian (DeathRecap), then Retry, Next stage and Main screen (a single Back to title after a game over).

## The button pressed: &"retry", &"next", &"main" or &"title".
signal chosen(then: StringName)

const LAYER := 42
const REWARD_COLOR := UiStyle.GOOD_COLOR
## The recap's killed-by line, its tip (a calmer color) and its shares' gap.
const KILLED_COLOR := UiStyle.ERROR_COLOR
const TIP_COLOR := UiStyle.LANTERN_COLOR
const SHARE_GAP := 36
const PANEL_WIDTH := 1040.0
const BUTTON_SIZE := Vector2(260, 60)
const CLEARED_GLOW := Color(1.0, 0.78, 0.3, 0.22)
const DEFEATED_GLOW := Color(0.7, 0.05, 0.05, 0.28)
## The plate's padding, and the room its column keeps under the medallion.
const PAD := 30.0
const CREST_ROOM := 28.0
## The medallion over the plate's top edge, and the lantern in it.
const MEDALLION := 44.0
const LANTERN_SIZE := 70.0
const LANTERN := preload("res://assets/art/ui/title_lantern.svg")
## The medallion after a clear: a warm light around a lit lantern.
const LIT_LIGHT := Color(1.0, 0.85, 0.54, 0.5)
## After a defeat: a red light, a dull ring and the lantern gone dim and red.
const DIM_LIGHT := Color(0.8, 0.08, 0.06, 0.34)
const DIM_RING := Color(0.5, 0.29, 0.25)
const DIM_LANTERN := Color(0.72, 0.26, 0.22)
const TITLE_FONT := 60
const TITLE_SPACING := 8
## The title's glow: how far past the title it reaches (× its size), and how
## strong it is beside the screen's glow.
const TITLE_GLOW_REACH := Vector2(1.5, 2.8)
const TITLE_GLOW_ALPHA := 1.8
const STAGE_FONT := 24
const STAGE_RULE := 170.0
const HEAD_FONT := 18
const HEAD_SPACING := 4
const ROW_FONT := 22
const LINE_FONT := 20
## A green line's least width before it wraps.
const LINE_WIDTH := 400.0
## A stats row: a faint well with its icon in the name's left margin.
const ROW_COLOR := Color(0.0, 0.0, 0.0, 0.24)
const ROW_RADIUS := 6
const ROW_PAD := 12.0
const ROW_MARGIN := 3.0
const STAT_ICON := 24.0
const STAT_ICON_ROOM := 48.0
## A stats row's icon, by its label; a row without one has a gold diamond.
const STAT_ICONS := {
	"Time": preload("res://assets/art/stats/ability_haste.svg"),
	"Kills": preload("res://assets/art/ui/skull.svg"),
	"Damage dealt": preload("res://assets/art/stats/ad.svg"),
	"Damage taken": preload("res://assets/art/stats/armor.svg"),
	"Gold earned": preload("res://assets/art/ui/gold.svg"),
}
const ESSENCE_ICON := 32.0
const ESSENCE_LINE := "+%d %s essence"
## The essences count up from 0 for this long (the final numbers at once
## with low effects), fast at first.
const COUNT_TIME := 0.6
const COUNT_EASE := 0.5

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
## The recap's rows, and the section holding them (shown after a defeat).
var _recap: VBoxContainer
var _recap_section: Control
var _gradient: Gradient
## Draws the medallion; the top of the plate's column.
var _crest := Control.new()
var _title_glow := Control.new()
## The essence rows' labels and their final amounts, by kind.
var _essence_labels := {}
var _amounts := {}
var _count_left := 0.0


func _ready() -> void:
	layer = LAYER
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	set_process(false)
	_build()


## The essences count up to their amounts.
func _process(delta: float) -> void:
	_count_left = maxf(_count_left - delta, 0.0)
	_show_essences(ease(1.0 - _count_left / COUNT_TIME, COUNT_EASE))
	set_process(_count_left > 0.0)


## "4:32": minutes and seconds, rounded up.
static func clock(seconds: float) -> String:
	var whole := ceili(seconds)
	return "%d:%02d" % [whole / 60, whole % 60]


## `stats` is a list of [label, value] pairs, in order. `can_next`: there is a
## next stage to play (it only shows after a clear). `title_text`, when set,
## replaces the outcome's title (its color, glow and lantern stay the outcome's).
## `recap` is DeathRecap.build's parts; a clear never shows it.
func show_result(is_cleared: bool, stage_name: String, stats: Array, collected: Dictionary, rewards: Array[String], is_game_over := false, can_next := false, title_text := "", recap := {}) -> void:
	cleared = is_cleared
	game_over = is_game_over and not is_cleared
	if title_text != "":
		title.text = title_text
	elif cleared:
		title.text = "STAGE CLEARED"
	else:
		title.text = "GAME OVER" if game_over else "DEFEATED"
	title.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if cleared else UiStyle.ERROR_COLOR)
	_gradient.colors = PackedColorArray([_glow_color(), Color(0, 0, 0, 0)])
	_crest.queue_redraw()
	_title_glow.queue_redraw()
	_stage_label.text = stage_name
	retry_button.visible = not game_over
	next_button.visible = cleared and can_next
	main_button.text = "Back to title" if game_over else "Main screen"
	_fill_stats(stats)
	_fill_rewards(collected, rewards)
	_fill_recap({} if cleared else recap)
	visible = true


func _glow_color() -> Color:
	return CLEARED_GLOW if cleared else DEFEATED_GLOW


func _fill_stats(stats: Array) -> void:
	for child in _stats.get_children():
		child.queue_free()
	for pair: Array in stats:
		_stats.add_child(_stat_row(pair[0], pair[1]))


## A stats row: its name and its value (the row's two children) on a faint
## well. The row draws the well and, in the name's left margin, its icon.
func _stat_row(text: String, value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var name_label := UiStyle.label(text, ROW_FONT, UiStyle.TEXT_COLOR)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_stylebox_override(&"normal", _row_margin(STAT_ICON_ROOM, 0.0))
	var value_label := UiStyle.label(value, ROW_FONT, UiStyle.TITLE_COLOR)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_stylebox_override(&"normal", _row_margin(0.0, ROW_PAD))
	row.add_child(name_label)
	row.add_child(value_label)
	var icon: Texture2D = STAT_ICONS.get(text)
	var well := StyleBoxFlat.new()
	well.bg_color = ROW_COLOR
	well.set_corner_radius_all(ROW_RADIUS)
	row.draw.connect(func() -> void:
		row.draw_style_box(well, Rect2(Vector2.ZERO, row.size))
		var middle := Vector2(STAT_ICON_ROOM * 0.5, row.size.y * 0.5)
		if icon:
			row.draw_texture_rect(icon, Rect2(middle - Vector2.ONE * STAT_ICON * 0.5, Vector2.ONE * STAT_ICON), false)
		else:
			row.draw_colored_polygon(Plate.diamond(middle, Ornament.DIAMOND), UiStyle.BORDER_COLOR))
	return row


## A label's margins inside a stats row.
func _row_margin(left: float, right: float) -> StyleBoxEmpty:
	var margin := StyleBoxEmpty.new()
	margin.content_margin_left = left
	margin.content_margin_right = right
	margin.content_margin_top = ROW_MARGIN
	margin.content_margin_bottom = ROW_MARGIN
	return margin


func _fill_rewards(collected: Dictionary, rewards: Array[String]) -> void:
	for child in _rewards.get_children():
		child.queue_free()
	_essence_labels.clear()
	_amounts.clear()
	for kind: StringName in Essences.KINDS:
		if collected[kind] <= 0:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 12)
		var icon := TextureRect.new()
		icon.texture = Stage.ESSENCE_ICONS[kind]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(ESSENCE_ICON, ESSENCE_ICON)
		row.add_child(icon)
		var label := UiStyle.label("", ROW_FONT, Stage.ESSENCE_COLORS[kind])
		row.add_child(label)
		_rewards.add_child(row)
		_essence_labels[kind] = label
		_amounts[kind] = collected[kind]
	if _amounts.is_empty():
		_rewards.add_child(UiStyle.label("No essences", ROW_FONT, UiStyle.DIM_COLOR))
	for line in rewards:
		_rewards.add_child(_reward_line(line))
	_count_left = 0.0 if GameSettings.instance().low_effects() else COUNT_TIME
	_show_essences(0.0 if _count_left > 0.0 else 1.0)
	set_process(_count_left > 0.0)


## Each essence row reads `share` (0–1) of its amount.
func _show_essences(share: float) -> void:
	for kind: StringName in _essence_labels:
		(_essence_labels[kind] as Label).text = ESSENCE_LINE % [roundi(_amounts[kind] * share), kind]


## What hit Lucian: who struck the last blow, the shares of the damage and
## a tip, then the Evolution Tree line when something can be bought.
func _fill_recap(recap: Dictionary) -> void:
	_recap_section.visible = not recap.is_empty()
	for child in _recap.get_children():
		child.queue_free()
	if recap.is_empty():
		return
	_recap.add_child(UiStyle.label(recap.killed, ROW_FONT, KILLED_COLOR))
	var shares := HBoxContainer.new()
	shares.add_theme_constant_override(&"separation", SHARE_GAP)
	for share: String in recap.shares:
		shares.add_child(UiStyle.label(share, LINE_FONT, UiStyle.TEXT_COLOR))
	_recap.add_child(shares)
	_recap.add_child(_reward_line(recap.tip, TIP_COLOR))
	if recap.tree != "":
		_recap.add_child(_reward_line(recap.tree))


## A line with a diamond before it, green unless told otherwise; a long one wraps.
func _reward_line(text: String, color := REWARD_COLOR) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	var bullet := Control.new()
	bullet.custom_minimum_size = Vector2(ESSENCE_ICON, LINE_FONT)
	bullet.draw.connect(func() -> void:
		bullet.draw_colored_polygon(Plate.diamond(Vector2(bullet.size.x * 0.5, LINE_FONT * 0.7), Ornament.DIAMOND), color))
	row.add_child(bullet)
	var reward := UiStyle.label(text, LINE_FONT, color)
	reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward.custom_minimum_size = Vector2(LINE_WIDTH, 0)
	reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(reward)
	return row


func _build() -> void:
	var backdrop := MenuBackdrop.new()
	add_child(backdrop)
	# A soft glow behind the plate: a radial gradient, tinted per outcome.
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
	var plate := Plate.new(PAD)
	plate.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	center.add_child(plate)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	plate.add_child(column)
	_crest.custom_minimum_size.y = CREST_ROOM
	_crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crest.draw.connect(_draw_medallion)
	column.add_child(_crest)
	title = UiStyle.label("", TITLE_FONT, UiStyle.GOLD_COLOR)
	# As wide as its text, so its glow is too.
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	Ornament.space_out(title, TITLE_SPACING)
	column.add_child(title)
	_title_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_glow.show_behind_parent = true
	_title_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_glow.draw.connect(_draw_title_glow)
	title.add_child(_title_glow)
	_stage_label = UiStyle.label("", STAGE_FONT, UiStyle.TITLE_COLOR)
	column.add_child(Ornament.between_rules(_stage_label, STAGE_RULE))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override(&"separation", 22)
	column.add_child(columns)
	_stats = _section(columns, "STATS")
	columns.add_child(Ornament.divider(true))
	_rewards = _section(columns, "REWARDS")
	_recap = _section(column, "WHAT HIT YOU")
	_recap_section = _recap.get_parent()
	column.add_child(Ornament.divider())
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 30)
	column.add_child(buttons)
	retry_button = _button(buttons, "Retry", false, &"retry")
	next_button = _button(buttons, "Next stage", false, &"next")
	main_button = _button(buttons, "Main screen", true, &"main")


## The lantern in its medallion on the middle of the plate's top edge (PAD
## above the column), lit after a clear, dim and red after a defeat.
func _draw_medallion() -> void:
	var at := Vector2(_crest.size.x * 0.5, -PAD)
	if cleared:
		Ornament.draw_medallion(_crest, at, MEDALLION, LANTERN, LANTERN_SIZE, LIT_LIGHT)
	else:
		Ornament.draw_medallion(_crest, at, MEDALLION, LANTERN, LANTERN_SIZE, DIM_LIGHT, DIM_RING, DIM_LANTERN)


## The outcome's soft glow behind the title, wider than it.
func _draw_title_glow() -> void:
	var reach := _title_glow.size * TITLE_GLOW_REACH
	var light := _glow_color()
	light.a = minf(light.a * TITLE_GLOW_ALPHA, 1.0)
	_title_glow.draw_texture_rect(JourneyMap.glow(), Rect2((_title_glow.size - reach) * 0.5, reach), false, light)


## A column with its head (spaced capitals and a rule), returning the box
## the rows go into.
func _section(parent: Control, head: String) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.size_flags_stretch_ratio = 1.0
	section.add_theme_constant_override(&"separation", 10)
	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override(&"separation", 12)
	var head_label := UiStyle.label(head, HEAD_FONT, UiStyle.TITLE_COLOR)
	Ornament.space_out(head_label, HEAD_SPACING)
	head_row.add_child(head_label)
	head_row.add_child(Ornament.rule(false, Ornament.RULE_WIDTH, true))
	section.add_child(head_row)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override(&"separation", 6)
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
