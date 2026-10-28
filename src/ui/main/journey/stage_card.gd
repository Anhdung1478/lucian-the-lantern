class_name StageCard
extends Control
## One stage of an act: its number, its waves, a skull when it ends with a
## mini boss (grey) or the act boss (red), a chain while locked and a green
## check once cleared.

const SIZE := Vector2(200, 230)
const SKULL := preload("res://assets/art/ui/skull.svg")
const CHAIN := preload("res://assets/art/ui/chain.svg")
const MINI_BOSS_COLOR := Color("9aa3b2")
const BOSS_COLOR := Color("e0475a")
const CHECK_COLOR := Color("5ad07a")
const SKULL_SIZE := 36.0

var locked := false
var cleared := false
var skull: TextureRect
var waves_label: Label
var _chain: TextureRect


## `kind` is Journey.boss_kind(): &"boss", &"mini_boss" or &"".
func _init(stage: int, waves: int, kind: StringName) -> void:
	custom_minimum_size = SIZE
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_top = 36.0
	column.add_theme_constant_override(&"separation", 12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var title := UiStyle.label("Stage %d" % stage, 28, UiStyle.TITLE_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var text := "%d waves" % waves
	if kind == &"boss":
		text += " + boss wave"
	elif kind == &"mini_boss":
		text += " + mini boss wave"
	waves_label = UiStyle.label(text, 18, UiStyle.TEXT_COLOR)
	waves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waves_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	waves_label.custom_minimum_size = Vector2(0, 50)
	column.add_child(waves_label)
	skull = TextureRect.new()
	skull.texture = SKULL
	skull.custom_minimum_size = Vector2(SKULL_SIZE, SKULL_SIZE)
	skull.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skull.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	skull.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skull.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skull.visible = kind != &""
	skull.modulate = BOSS_COLOR if kind == &"boss" else MINI_BOSS_COLOR
	column.add_child(skull)
	_chain = TextureRect.new()
	_chain.texture = CHAIN
	_chain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chain.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_chain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chain.offset_left = 80.0
	_chain.offset_right = -80.0
	_chain.offset_top = 184.0
	_chain.offset_bottom = -8.0
	_chain.modulate = Color(1, 1, 1, 0.85)
	_chain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chain.visible = false
	add_child(_chain)


## Sets the card's state: locked (chain), open, or cleared (check).
func set_state(is_locked: bool, is_cleared: bool) -> void:
	locked = is_locked
	cleared = is_cleared
	_chain.visible = is_locked
	modulate = Color(1, 1, 1, 0.6) if is_locked else Color.WHITE
	queue_redraw()


func _draw() -> void:
	var border := UiStyle.BORDER_COLOR if not locked else Color(0.36, 0.4, 0.48)
	if cleared:
		border = CHECK_COLOR
	draw_style_box(UiStyle.panel(UiStyle.PANEL_COLOR, border, 2, 8.0), Rect2(Vector2.ZERO, size))
	if cleared:
		var corner := Vector2(size.x - 34.0, 12.0)
		var points := PackedVector2Array([corner + Vector2(0, 12), corner + Vector2(9, 21), corner + Vector2(24, 2)])
		draw_polyline(points, Color.BLACK, 8.0)
		draw_polyline(points, CHECK_COLOR, 5.0)
