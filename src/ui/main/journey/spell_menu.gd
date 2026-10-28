class_name SpellMenu
extends PanelContainer
## The small panel beside a D or F slot: one icon button for every bought
## spell, plus None. Closes itself on a pick.

signal picked(id: StringName)

const ICON_SIZE := 64.0

var slot := 0
var empty_label: Label
var _grid: GridContainer
var _buttons := {}


func _init() -> void:
	add_theme_stylebox_override(&"panel", UiStyle.panel(UiStyle.PANEL_COLOR, UiStyle.BORDER_COLOR, 2, 12.0))
	visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	empty_label = UiStyle.label("Buy spells in the Evolution Tree", 18, UiStyle.DIM_COLOR)
	column.add_child(empty_label)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override(&"h_separation", 8)
	_grid.add_theme_constant_override(&"v_separation", 8)
	column.add_child(_grid)
	var none := Button.new()
	none.text = "None"
	none.custom_minimum_size = Vector2(0, 40)
	UiStyle.style_button(none, 20)
	none.pressed.connect(pick.bind(&""))
	column.add_child(none)


## Opens for slot `index` (0 = D, 1 = F), listing the spells `tree` has
## bought. `current` is the spell already there and stays lit.
func open(index: int, tree: EvolutionTree, current: StringName) -> void:
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
		button.set_meta(&"hover_text", data.display_name)
		UiStyle.style_button(button, 16, id == current)
		button.pressed.connect(pick.bind(id))
		_grid.add_child(button)
		_buttons[id] = button
	empty_label.visible = _buttons.is_empty()
	_grid.visible = not _buttons.is_empty()
	reset_size()
	visible = true


## The spell ids listed, in order.
func spell_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in StageSetup.SPELL_IDS:
		if _buttons.has(id):
			ids.append(id)
	return ids


## Chooses `id` (&"" for None) and closes.
func pick(id: StringName) -> void:
	visible = false
	picked.emit(id)
