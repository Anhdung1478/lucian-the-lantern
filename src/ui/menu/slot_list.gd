class_name SlotList
extends VBoxContainer
## The 3 save slots as buttons: "Slot 2 · 1h 23m · saved 2026-10-28 14:03",
## "Slot 3 · empty", "Slot 1 (current)" or, in red, "Slot 2 · can't be read"
## (SaveGame.slot_broken). The owner decides what a pick does. Used by Save
## as copy, Start new game and Load game.
## With `parts` set (the title's pages and the gear menu's copy list) a row is three aligned columns instead
## of one string: "Slot 2" at the left, the play time in the middle, the save
## date dim at the right; an empty slot says "Empty" in the middle, greyed.
## The button's `text` is then empty; `row_text()` has the one-line wording.

signal picked(slot: int, used: bool)

## Wide enough for "Slot 2 · 99h 59m · saved 2026-10-28 14:03" with room around it.
const BUTTON_SIZE := Vector2(520, 56)

## A parted row's width (420 px on screen): the title's slot pages and the
## difficulty page share it, so the edges stay still between them.
const PARTS_WIDTH := 504.0

## Sizes of the parted row's columns: the slot name, and the date.
const NAME_WIDTH := 110.0
const DATE_WIDTH := 160.0
const ROW_INSET := 18.0

var buttons: Array[Button] = []
## Rows as three columns (see above). Set before the first refresh.
var parts := false:
	set(on):
		parts = on
		for button in buttons:
			button.custom_minimum_size.x = PARTS_WIDTH if on else BUTTON_SIZE.x
		refresh(_current, _empty_enabled)

var _current := 0
var _empty_enabled := true
## Button -> its three labels (name, time, date), in parts mode.
var _columns := {}


func _init() -> void:
	add_theme_constant_override(&"separation", 14)
	for n in range(1, SaveGame.SLOTS + 1):
		var button := Button.new()
		button.custom_minimum_size = BUTTON_SIZE
		UiStyle.style_button(button)
		button.pressed.connect(func() -> void: picked.emit(n, SaveGame.instance().slot_exists(n)))
		add_child(button)
		buttons.append(button)
	refresh()


## Re-reads the slots. `current` is shown as such and disabled; with
## `empty_enabled` off (Load game), empty slots are disabled too. A broken
## slot stays enabled, so a pick can explain it.
func refresh(current := 0, empty_enabled := true) -> void:
	_current = current
	_empty_enabled = empty_enabled
	var save := SaveGame.instance()
	for i in buttons.size():
		var n := i + 1
		var button := buttons[i]
		var used := save.slot_exists(n)
		var broken := used and n != current and save.slot_broken(n)
		_mark_broken(button, broken)
		if parts:
			button.text = ""
			_fill_columns(button, _texts(n, current, used, broken), n == current, used, broken)
		else:
			button.text = _line(n, current, used, broken)
		button.disabled = n == current or (not used and not empty_enabled)


## A broken slot's text is red; any other slot has the usual button look.
func _mark_broken(button: Button, broken: bool) -> void:
	if broken:
		button.add_theme_color_override(&"font_color", UiStyle.ERROR_COLOR)
		button.add_theme_color_override(&"font_hover_color", UiStyle.ERROR_COLOR)
	else:
		button.add_theme_color_override(&"font_color", UiStyle.TEXT_COLOR)
		button.add_theme_color_override(&"font_hover_color", UiStyle.TITLE_COLOR)


## The row's one-line wording (what the button's text is outside parts mode).
func row_text(index: int) -> String:
	var n := index + 1
	var used := SaveGame.instance().slot_exists(n)
	var broken := used and n != _current and SaveGame.instance().slot_broken(n)
	return _line(n, _current, used, broken)


func _line(n: int, current: int, used: bool, broken: bool) -> String:
	var save := SaveGame.instance()
	if n == current:
		return Lang.t("Slot %d (current)") % n
	if broken:
		return Lang.t("Slot %d · can't be read") % n
	if used:
		return Lang.t("Slot %d · %s · saved %s") % [n, SaveGame.play_time_text(save.play_time_of(n)), save.saved_at(n).substr(0, 16)]
	return Lang.t("Slot %d · empty") % n


## The three parts of a row: name, middle, date ("" when it has none).
func _texts(n: int, current: int, used: bool, broken: bool) -> Array[String]:
	var save := SaveGame.instance()
	var name := Lang.t("Slot %d") % n
	if n == current:
		return [name, Lang.t("Current"), ""]
	if broken:
		return [name, Lang.t("Can't be read"), ""]
	if used:
		return [name, SaveGame.play_time_text(save.play_time_of(n)), save.saved_at(n).substr(0, 16)]
	return [name, Lang.t("Empty"), ""]


## Writes the three columns of a button, building them the first time.
func _fill_columns(button: Button, texts: Array[String], is_current: bool, used: bool, broken: bool) -> void:
	if not _columns.has(button):
		_columns[button] = _build_columns(button)
	var labels: Array = _columns[button]
	for i in 3:
		(labels[i] as Label).text = texts[i]
	var lit := button.is_hovered() and not button.disabled
	var base := UiStyle.TEXT_COLOR
	if broken:
		base = UiStyle.ERROR_COLOR
	elif not used or is_current:
		base = UiStyle.DISABLED_FONT
	labels[0].add_theme_color_override(&"font_color", base if not lit or broken else UiStyle.TITLE_COLOR)
	labels[1].add_theme_color_override(&"font_color", base)
	labels[2].add_theme_color_override(&"font_color", UiStyle.DIM_COLOR if used and not broken else base)
	button.set_meta(&"columns_base", base)


func _build_columns(button: Button) -> Array:
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = ROW_INSET
	row.offset_right = -ROW_INSET
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiStyle.GAP)
	button.add_child(row)
	var name := UiStyle.label("", UiStyle.FONT_ROW)
	name.custom_minimum_size.x = NAME_WIDTH
	var middle := UiStyle.label("", UiStyle.FONT_ROW)
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var date := UiStyle.label("", UiStyle.FONT_NOTE, UiStyle.DIM_COLOR)
	date.custom_minimum_size.x = DATE_WIDTH
	date.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for label: Label in [name, middle, date]:
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
	button.mouse_entered.connect(_light_name.bind(button, true))
	button.mouse_exited.connect(_light_name.bind(button, false))
	return [name, middle, date]


## The slot's name turns pale gold under the mouse, as a button's text does.
func _light_name(button: Button, on: bool) -> void:
	if not _columns.has(button) or button.disabled:
		return
	var base: Color = button.get_meta(&"columns_base", UiStyle.TEXT_COLOR)
	var broken := base == UiStyle.ERROR_COLOR
	_columns[button][0].add_theme_color_override(&"font_color", UiStyle.TITLE_COLOR if on and not broken else base)
