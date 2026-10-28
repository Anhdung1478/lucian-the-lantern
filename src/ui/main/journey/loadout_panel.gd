class_name LoadoutPanel
extends PanelContainer
## The summoner spells on D and F, on every Journey tab. A slot opens the
## SpellMenu; a pick goes to SaveGame.set_loadout(), which swaps when the
## spell was on the other key. F stays chained until the 2nd slot is bought.

const WIDTH := 380.0
const PICK_SIZE := 72.0
const CHAIN := preload("res://assets/art/ui/chain.svg")
const KEYS: Array[StringName] = [&"summoner_d", &"summoner_f"]

## The D and F buttons.
var picks: Array[Button] = []
var menu := SpellMenu.new()

var _key_labels: Array[Label] = []
var _chains: Array[TextureRect] = []


func _ready() -> void:
	custom_minimum_size.x = WIDTH
	add_theme_stylebox_override(&"panel", UiStyle.panel(UiStyle.PANEL_COLOR, UiStyle.BORDER_COLOR, 2, 20.0))
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 16)
	add_child(column)
	column.add_child(UiStyle.label("SUMMONER SPELLS", 24, UiStyle.TITLE_COLOR))
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 24)
	column.add_child(row)
	for i in 2:
		var holder := VBoxContainer.new()
		holder.add_theme_constant_override(&"separation", 6)
		row.add_child(holder)
		var key := UiStyle.label("", 22, UiStyle.GOLD_COLOR)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		holder.add_child(key)
		_key_labels.append(key)
		var pick_button := Button.new()
		pick_button.custom_minimum_size = Vector2(PICK_SIZE, PICK_SIZE)
		pick_button.expand_icon = true
		pick_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pick_button.pressed.connect(open_menu.bind(i))
		UiStyle.style_button(pick_button, 18)
		holder.add_child(pick_button)
		picks.append(pick_button)
		var chain := TextureRect.new()
		chain.texture = CHAIN
		chain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chain.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chain.set_anchors_preset(Control.PRESET_FULL_RECT)
		chain.offset_left = 8.0
		chain.offset_top = 8.0
		chain.offset_right = -8.0
		chain.offset_bottom = -8.0
		chain.modulate = Color(1, 1, 1, 0.85)
		chain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chain.visible = false
		pick_button.add_child(chain)
		_chains.append(chain)
	var hint := UiStyle.label("Click a key to choose its spell. Spells are bought in the Evolution Tree.", 16, UiStyle.DIM_COLOR)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = WIDTH - 40.0
	column.add_child(hint)
	menu.top_level = true
	menu.z_index = 10
	menu.picked.connect(_on_picked)
	add_child(menu)
	var save := SaveGame.instance()
	save.changed.connect(refresh)
	save.tree.changed.connect(refresh)
	GameSettings.instance().changed.connect(_on_setting_changed)
	refresh()


## Opens the spell menu beside slot `index`; the same slot again closes it.
func open_menu(index: int) -> void:
	if picks[index].disabled:
		return
	if menu.visible and menu.slot == index:
		close_menu()
		return
	var save := SaveGame.instance()
	menu.open(index, save.tree, save.loadout[index])
	# Beside the slot, to the left of the panel so it never covers it.
	var anchor := picks[index].get_global_rect()
	menu.global_position = Vector2(get_global_rect().position.x - menu.size.x - 12.0, anchor.position.y)


## Closes the menu; true when one was open.
func close_menu() -> bool:
	var was_open := menu.visible
	menu.visible = false
	return was_open


## Redraws the keys, the spell icons and F's chain from the save.
func refresh() -> void:
	var save := SaveGame.instance()
	var second_open := save.tree.level(&"summoner_slot_2") > 0
	for i in 2:
		_key_labels[i].text = GameSettings.instance().key_label(KEYS[i])
		var id := save.loadout[i]
		# A spell the tree no longer has (after a reset) shows as empty.
		var data := SummonerSpells.find(id) if id != &"" and save.tree.level(id) > 0 else null
		picks[i].icon = data.icon if data else null
		var locked := i == 1 and not second_open
		picks[i].text = "" if data or locked else "None"
		picks[i].disabled = locked
		_chains[i].visible = locked
		if locked:
			picks[i].set_meta(&"hover_text", "Buy the 2nd summoner slot in the Evolution Tree")
		elif data:
			picks[i].set_meta(&"hover_text", data.display_name)
		elif picks[i].has_meta(&"hover_text"):
			picks[i].remove_meta(&"hover_text")
	if menu.visible and picks[menu.slot].disabled:
		close_menu()


## A rebound D or F key shows its new label.
func _on_setting_changed(key: StringName) -> void:
	if key == &"bindings":
		refresh()


func _on_picked(id: StringName) -> void:
	SaveGame.instance().set_loadout(menu.slot, id)


func _input(event: InputEvent) -> void:
	if not menu.visible or not event is InputEventMouseButton:
		return
	var click := event as InputEventMouseButton
	if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if menu.get_global_rect().has_point(click.global_position):
		return
	# A click on a slot is that slot's own business (it re-opens or closes).
	for pick_button in picks:
		if pick_button.get_global_rect().has_point(click.global_position):
			return
	close_menu()
