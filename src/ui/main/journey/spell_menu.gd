class_name SpellMenu
extends PanelContainer
## The small panel over the D and F slots: one icon button for every bought
## spell, plus None. Closes itself on a pick. It comes in rising toward its
## place from the slots (UiMotion, FAST) and leaves the same way; is_open()
## flips at once.

signal picked(id: StringName)

const ICON_SIZE := 64.0

var slot := 0
var empty_label: Label
var _open := false
var _grid: GridContainer
var _buttons := {}


func _init() -> void:
	add_theme_stylebox_override(&"panel", UiStyle.panel(UiStyle.PANEL_COLOR, UiStyle.BORDER_COLOR, 2, 12.0))
	visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	empty_label = UiStyle.label(Lang.t("Buy spells in the Evolution Tree"), 18, UiStyle.DIM_COLOR)
	column.add_child(empty_label)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override(&"h_separation", 8)
	_grid.add_theme_constant_override(&"v_separation", 8)
	column.add_child(_grid)
	var none := Button.new()
	none.text = Lang.t("None")
	none.custom_minimum_size = Vector2(0, 40)
	UiStyle.style_button(none, 20)
	none.pressed.connect(pick.bind(&""))
	column.add_child(none)


## Opens for slot `index` (0 = D, 1 = F) where it is, listing the spells
## `tree` has bought. `current` is the spell already there and stays lit.
func open(index: int, tree: EvolutionTree, current: StringName) -> void:
	fill(index, tree, current)
	place(position)


## True from open() or place() until a pick or close() (even while it fades).
func is_open() -> bool:
	return _open


## Lists the spells for slot `index` and sizes the menu, without showing it
## (place() shows it once its spot is known).
func fill(index: int, tree: EvolutionTree, current: StringName) -> void:
	UiMotion.finish(self)
	slot = index
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.free()
	_buttons.clear()
	for id in StageSetup.SPELL_IDS:
		if tree.level(id) <= 0:
			continue
		var data := SummonerSpells.find(id)
		var button := Button.new()
		button.icon = data.icon
		button.expand_icon = true
		button.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		button.set_meta(&"hover_text", Lang.t(data.display_name))
		UiStyle.style_button(button, 16, id == current)
		button.pressed.connect(pick.bind(id))
		_grid.add_child(button)
		_buttons[id] = button
	empty_label.visible = _buttons.is_empty()
	_grid.visible = not _buttons.is_empty()
	reset_size()


## Shows the filled menu with its top-left at `at` (screen coordinates): it
## rises into place from the slots below it.
func place(at: Vector2) -> void:
	UiMotion.finish(self)
	global_position = at
	_open = true
	UiMotion.enter(self, UiMotion.DROP, UiMotion.FAST)


## Hides it (fading back toward the slots).
func close() -> void:
	if not _open:
		return
	_open = false
	UiMotion.exit(self)


## The spell ids listed, in order.
func spell_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in StageSetup.SPELL_IDS:
		if _buttons.has(id):
			ids.append(id)
	return ids


## Chooses `id` (&"" for None) and closes.
func pick(id: StringName) -> void:
	close()
	picked.emit(id)
