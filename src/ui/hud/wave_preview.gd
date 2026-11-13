class_name WavePreview
extends Plate
## Under the stage info, in the boss bar's place, while a break (or the
## countdown before wave 1) runs: "NEXT" as a heading, then each enemy of the
## next wave as a small icon in a dark cell with "×N" beside it; a boss or a
## mini boss has a gold rim and its name. Endless rolls a wave's enemies when
## it starts, so it only says "Mini boss wave" or "Boss wave", and nothing
## before a normal one. Hovering an icon names the enemy. Only hover, never
## a click.

const PAD := 10.0
const LINE_GAP := 4
const ROW_GAP := 14
const ENTRY_GAP := 6
const CELL_SIZE := 34.0
const FONT_SIZE := 18
const BOSS_WAVE_TEXT := "Boss wave"
const MINI_BOSS_WAVE_TEXT := "Mini boss wave"

var runner: WaveRunner
## The end screen is up: the HUD sets it.
var suppressed := false
## The enemy cells now shown, one per row.
var cells: Array[Control] = []

var _heading := HudHeading.new()
var _row := HBoxContainer.new()
## What the row was built for, so it is built again only when that changes.
var _shown: Variant = null


func _init() -> void:
	super(PAD, false)
	opacity = Hud.PLATE_OPACITY
	_heading.label.text = Lang.t("Next")


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
	refresh()


func setup(stage_runner: WaveRunner) -> void:
	runner = stage_runner
	refresh()


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	var ids: Array = [] if runner == null else runner.next_ids()
	var kind := &"" if runner == null else runner.next_kind()
	var held := runner is EndlessRunner and (runner as EndlessRunner).held
	var text := _wave_text(kind) if ids.is_empty() else ""
	visible = not suppressed and not held and (not ids.is_empty() or text != "")
	if not visible:
		return
	var key: Variant = [ids, text]
	if key == _shown:
		return
	_shown = key
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	cells.clear()
	if text != "":
		_row.add_child(_text(text, UiStyle.GOLD_COLOR))
	for info in WavePlan.preview_rows(ids):
		_row.add_child(_entry(info))


## The words for a wave only its kind is known of; "" for a normal one.
func _wave_text(kind: StringName) -> String:
	match kind:
		&"boss":
			return Lang.t(BOSS_WAVE_TEXT)
		&"mini_boss":
			return Lang.t(MINI_BOSS_WAVE_TEXT)
	return ""


## An enemy's icon in its cell, and beside it "×N" (its name for a boss).
func _entry(info: Dictionary) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override(&"separation", ENTRY_GAP)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cell := PanelContainer.new()
	var rim := UiStyle.GOLD_COLOR if info.boss else UiStyle.CELL_BORDER
	cell.add_theme_stylebox_override(&"panel", UiStyle.cell_style(rim, info.boss))
	cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Hover reaches the hover card; a click falls through to the game.
	cell.mouse_filter = Control.MOUSE_FILTER_PASS
	cell.set_meta(&"hover_text", info.name)
	var icon := TextureRect.new()
	icon.texture = info.art
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(icon)
	cells.append(cell)
	box.add_child(cell)
	box.add_child(_text(info.name if info.boss else "×%d" % info.count, UiStyle.TEXT_COLOR))
	return box


func _text(text: String, color: Color) -> Label:
	var label := UiStyle.label(text, FONT_SIZE, color)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
