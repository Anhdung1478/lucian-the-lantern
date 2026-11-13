class_name LoadoutPanel
extends PanelContainer
## The summoner spells on D and F, compact at the foot of the Journey's side
## panel (over Start) for every pick. A slot opens the SpellMenu upward, over
## the panel's rows and inside the panel; a pick goes to
## SaveGame.set_loadout(), which swaps when the spell was on the other key. F
## stays chained until the 2nd slot is bought.

const WIDTH := 400.0
const PICK_SIZE := 64.0
## The panel's inner margin, and the gap between the words and the keys.
const MARGIN := 12.0
const SPACING := 14
## The spell menu's gap over this box (8 px on screen), and the side panel's
## padding it stays inside.
const MENU_GAP := 10.0
const PANEL_PAD := JourneyPanel.PAD
const CHAIN := preload("res://assets/art/ui/chain.svg")
const KEYS: Array[StringName] = [&"summoner_d", &"summoner_f"]

## The D and F buttons.
var picks: Array[Button] = []
var menu := SpellMenu.new()

var _key_labels: Array[Label] = []
var _chains: Array[TextureRect] = []
## The menu's plain holder, placed on the screen (top level), so the menu can
## rise into place (a Container would pin it).
var _menu_holder := Control.new()


func _ready() -> void:
	custom_minimum_size.x = WIDTH
	add_theme_stylebox_override(&"panel", UiStyle.panel(Color(0.035, 0.042, 0.056), Color(UiStyle.BORDER_COLOR, 0.5), 1, MARGIN, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", SPACING)
	add_child(row)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override(&"separation", 4)
	row.add_child(words)
	words.add_child(UiStyle.label(Lang.t("SUMMONER SPELLS"), 18, UiStyle.TITLE_COLOR))
	# One line; where spells are bought is on the empty menu and F's chain.
	# The words take what the two keys leave.
	var hint := UiStyle.note(Lang.t("Click a key to choose its spell."), UiStyle.DIM_COLOR,
		WIDTH - MARGIN * 2.0 - (SPACING + PICK_SIZE) * 2.0)
	words.add_child(hint)
	for i in 2:
		var holder := VBoxContainer.new()
		holder.add_theme_constant_override(&"separation", 2)
		row.add_child(holder)
		var key := UiStyle.label("", 18, UiStyle.GOLD_COLOR)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		holder.add_child(key)
		_key_labels.append(key)
		var pick_button := Button.new()
		pick_button.custom_minimum_size = Vector2(PICK_SIZE, PICK_SIZE)
		pick_button.expand_icon = true
		pick_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pick_button.pressed.connect(open_menu.bind(i))
		UiStyle.style_button(pick_button, 16)
		# An empty cell's word is a small tag, never edge to edge.
		pick_button.add_theme_font_size_override(&"font_size", UiStyle.FONT_TAG)
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
	_menu_holder.top_level = true
	_menu_holder.z_index = 10
	_menu_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_menu_holder)
	menu.picked.connect(_on_picked)
	_menu_holder.add_child(menu)
	var save := SaveGame.instance()
	save.changed.connect(refresh)
	save.tree.changed.connect(refresh)
	GameSettings.instance().changed.connect(_on_setting_changed)
	refresh()


## Opens the spell menu for slot `index`; the same slot again closes it. It
## opens upward: its bottom MENU_GAP over this box, its right edge on the
## panel's right padding (this box's right edge), never out of the panel.
func open_menu(index: int) -> void:
	if picks[index].disabled:
		return
	if menu.is_open() and menu.slot == index:
		close_menu()
		return
	var save := SaveGame.instance()
	menu.fill(index, save.tree, save.loadout[index])
	var box := get_global_rect()
	var top := box.position.y - MENU_GAP - menu.size.y
	var panel := get_parent() as Control
	if panel:
		top = maxf(top, panel.get_global_rect().position.y + PANEL_PAD)
	menu.place(Vector2(box.end.x - menu.size.x, top))


## Closes the menu; true when one was open.
func close_menu() -> bool:
	var was_open := menu.is_open()
	menu.close()
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
		picks[i].text = "" if data or locked else Lang.t("None")
		picks[i].disabled = locked
		_chains[i].visible = locked
		if locked:
			picks[i].set_meta(&"hover_text", Lang.t("Buy the 2nd summoner slot in the Evolution Tree"))
		elif data:
			picks[i].set_meta(&"hover_text", Lang.t(data.display_name))
		elif picks[i].has_meta(&"hover_text"):
			picks[i].remove_meta(&"hover_text")
	if menu.is_open() and picks[menu.slot].disabled:
		close_menu()


## A rebound D or F key shows its new label.
func _on_setting_changed(key: StringName) -> void:
	if key == &"bindings":
		refresh()


func _on_picked(id: StringName) -> void:
	SaveGame.instance().set_loadout(menu.slot, id)


func _input(event: InputEvent) -> void:
	if not menu.is_open() or not event is InputEventMouseButton:
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
