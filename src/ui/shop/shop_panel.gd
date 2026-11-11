class_name ShopPanel
extends PanelContainer
## The merchant's shop, beside the backpack while it is open: a gold readout,
## the Items, Potions and Craft tabs, a hint line, the Undo sale button (every
## tab; it buys back the last sale) and the Refresh button (Items only) in
## the bottom-right corner. Refused purchases flash a red message; a full
## backpack and the one-penetration rule are told in a pop-up instead
## (BackpackScreen._report).
##
## The Craft tab: [input] + [input] -> [result], the fee and a Craft button.
## Two fragments make their legendary, for the legendary's cost minus the
## fragments'; the boots and a fragment make the upgraded boots, for their
## upgrade_cost. Its two inputs are filled by dragging from the backpack: an
## item in an input leaves the backpack view until it comes back (see
## CraftSlot), and changing tabs gives both back. The Craft button asks first
## (BackpackScreen.craft).

const SLOT_GAP := 12
const MESSAGE_TIME := 1.6
const TAB_NAMES: Array[String] = ["Items", "Potions", "Craft"]
const ITEMS_TAB := 0
const POTIONS_TAB := 1
const CRAFT_TAB := 2
## One hint line per tab; the Potions tab's names the potion keys (hint()).
const HINTS: Array[String] = [
	"Right-click or drag to buy.\nDrag an item onto the red slot to sell it.",
	"Right-click or drag to buy. Potions fill\nthe %s and %s cells first, then the backpack.",
	"Drag two fragments, or your boots and a\nfragment, into the slots, then pay the fee.",
]
const MESSAGES := {
	Shop.Result.NO_GOLD: "Not enough gold",
	Shop.Result.CELL_LOCKED: "That cell is locked",
	Shop.Result.SOLD_OUT: "Already sold",
	Shop.Result.NOTHING_TO_REFRESH: "Nothing left to refresh",
	Shop.Result.NO_RECIPE: "Those don't craft into anything",
	Shop.Result.WRONG_CELL: "That item can't go there",
	Shop.Result.NOTHING_TO_UNDO: "No sale to undo",
	Shop.Result.SLOT_LOCKED: "That slot is locked",
}

var screen: BackpackScreen

var _tab := 0
var _tab_buttons: Array[Button] = []
var _pages: Array[Control] = []
var _gold_label: Label
var _hint: Label
var _message: Label
var _refresh: Button
var _undo: Button
var _message_left := 0.0
var _first_input: CraftSlot
var _second_input: CraftSlot
var _result_slot: CraftSlot
var _fee_label: Label
var _craft_note: Label
var _craft_button: Button


func setup(owner_screen: BackpackScreen, potions: Array[ItemData]) -> void:
	screen = owner_screen
	add_theme_stylebox_override(&"panel", UiStyle.panel(UiStyle.PANEL_COLOR, UiStyle.BORDER_COLOR, 2, 20.0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 14)
	add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	var title := UiStyle.label("MERCHANT", 26, UiStyle.TITLE_COLOR)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var coin := TextureRect.new()
	coin.texture = ShopSlot.COIN
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.custom_minimum_size = Vector2(28, 28)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(coin)
	_gold_label = UiStyle.label("0", 24, UiStyle.GOLD_COLOR)
	header.add_child(_gold_label)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override(&"separation", 8)
	box.add_child(tabs)
	for i in TAB_NAMES.size():
		var button := Button.new()
		button.text = TAB_NAMES[i]
		button.custom_minimum_size = Vector2(116, 40)
		button.pressed.connect(show_tab.bind(i))
		tabs.add_child(button)
		_tab_buttons.append(button)

	var items := HBoxContainer.new()
	items.add_theme_constant_override(&"separation", SLOT_GAP)
	for slot in MerchantStock.SLOTS:
		items.add_child(ShopSlot.new(screen, slot))
	box.add_child(items)
	var potion_row := HBoxContainer.new()
	potion_row.add_theme_constant_override(&"separation", SLOT_GAP)
	for potion in potions:
		potion_row.add_child(ShopSlot.new(screen, -1, potion))
	box.add_child(potion_row)
	var craft_page := _build_craft_page()
	box.add_child(craft_page)
	_pages = [items, potion_row, craft_page]

	_hint = UiStyle.label(HINTS[0], 14, UiStyle.DIM_COLOR)
	box.add_child(_hint)
	GameSettings.instance().changed.connect(_on_setting_changed)
	var bottom := HBoxContainer.new()
	box.add_child(bottom)
	_message = UiStyle.label("", 16, UiStyle.ERROR_COLOR)
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_message)
	_undo = Button.new()
	_undo.text = "Undo sale"
	_undo.custom_minimum_size = Vector2(130, 40)
	UiStyle.style_button(_undo, 17)
	_undo.pressed.connect(func() -> void: screen.undo_sale())
	bottom.add_child(_undo)
	_refresh = Button.new()
	_refresh.text = "Refresh"
	_refresh.icon = ShopSlot.COIN
	_refresh.expand_icon = false
	_refresh.add_theme_constant_override(&"icon_max_width", 22)
	_refresh.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_refresh.custom_minimum_size = Vector2(160, 40)
	UiStyle.style_button(_refresh, 17)
	_refresh.pressed.connect(func() -> void: screen.refresh_shop())
	bottom.add_child(_refresh)
	screen.inventory.changed.connect(_recheck_inputs)
	show_tab(0)


## Shows what the open shop charges for a refresh.
func show_refresh_cost(cost: int) -> void:
	_refresh.text = "Refresh  %d" % cost


## Switching tabs gives the Craft inputs' items back to the backpack.
func show_tab(tab: int) -> void:
	if tab != _tab:
		clear_craft()
	_tab = tab
	for i in _pages.size():
		_pages[i].visible = i == tab
		UiStyle.style_button(_tab_buttons[i], 18, i == tab)
	_refresh.visible = tab == ITEMS_TAB
	_hint.text = hint(tab)


## Tab `tab`'s hint line. The Potions tab's names the potion keys as bound
## now, in full ("Mouse 4"): it is a sentence, not a slot label.
static func hint(tab: int) -> String:
	if tab != POTIONS_TAB:
		return HINTS[tab]
	var settings := GameSettings.instance()
	return HINTS[tab] % [
		settings.key_label(Inventory.key_action(Inventory.HP_POTION_CELL)),
		settings.key_label(Inventory.key_action(Inventory.MP_POTION_CELL)),
	]


## A rebound potion key shows in the hint at once.
func _on_setting_changed(key: StringName) -> void:
	if key == &"bindings":
		_hint.text = hint(_tab)


func undo_button() -> Button:
	return _undo


func current_tab() -> int:
	return _tab


## Shows why a purchase, refresh or craft failed, and flashes the slot's
## price red.
func refuse(result: Shop.Result, slot: ShopSlot = null) -> void:
	show_message(MESSAGES.get(result, ""))
	if slot:
		slot.flash_left = MESSAGE_TIME


## A red message for MESSAGE_TIME seconds.
func show_message(text: String) -> void:
	_message.text = text
	_message_left = MESSAGE_TIME


## The shop slots on `tab` (none on the Craft tab).
func slots(tab: int) -> Array[ShopSlot]:
	var found: Array[ShopSlot] = []
	for child in _pages[tab].get_children():
		if child is ShopSlot:
			found.append(child)
	return found


func first_input() -> CraftSlot:
	return _first_input


func second_input() -> CraftSlot:
	return _second_input


func result_slot() -> CraftSlot:
	return _result_slot


func craft_button() -> Button:
	return _craft_button


## The Craft tab input under `point` while that tab shows, or null.
func craft_input_at(point: Vector2) -> CraftSlot:
	if not visible or _tab != CRAFT_TAB:
		return null
	for input in [_first_input, _second_input]:
		if input.get_global_rect().has_point(point):
			return input
	return null


## The input `target` names: BackpackScreen.CRAFT_FIRST or CRAFT_SECOND.
func input_for(target: int) -> CraftSlot:
	return _first_input if target == BackpackScreen.CRAFT_FIRST else _second_input


## Whether a Craft input holds the item in inventory cell `cell`.
func holds(cell: int) -> bool:
	return cell >= 0 and (_first_input.index == cell or _second_input.index == cell)


## Puts the item in inventory cell `cell` into the input `target` names; what
## that input held comes back to the backpack. One cell is never in both
## inputs: the other input lets go of it. False, with a message, when the item
## is never crafted (a legendary or a potion).
func load_input(target: int, cell: int) -> bool:
	var input := input_for(target)
	if not input.load_cell(cell):
		show_message("Only fragments and boots are crafted")
		return false
	var other := _second_input if input == _first_input else _first_input
	if other.index == cell:
		other.clear()
	return true


## Moves what input `from` holds into the input `target` names; what that
## one held goes the other way.
func move_input(from: CraftSlot, target: int) -> void:
	var to := input_for(target)
	if to == from:
		return
	var held := to.index
	to.index = from.index
	from.index = held


## Empties both inputs: their items come back to the backpack (the tab
## changed or the shop closed), or a craft used them up.
func clear_craft() -> void:
	_first_input.clear()
	_second_input.clear()


## What the two inputs would make, or null.
func craft_preview() -> ItemData:
	if screen.shop == null:
		return null
	return screen.shop.craft_result(_first_input.index, _second_input.index)


## The fee for what is in the two inputs (0 when they make nothing).
func craft_fee() -> int:
	if screen.shop == null:
		return 0
	return screen.shop.craft_fee(_first_input.index, _second_input.index)


func _process(delta: float) -> void:
	if screen == null or screen.shop == null:
		return
	_gold_label.text = str(screen.shop.wallet.gold)
	# Greyed once every open slot is sold: a refresh would change nothing.
	_refresh.disabled = not screen.shop.can_refresh()
	_show_undo()
	if _tab == CRAFT_TAB:
		_show_craft()
	# The dragged icon covers the sell slot, so its price shows here too.
	if screen.sell_refused():
		_message.text = "Boots can't be sold"
		_message.add_theme_color_override(&"font_color", UiStyle.ERROR_COLOR)
		_message_left = MESSAGE_TIME
		return
	var preview := screen.sell_preview()
	if preview > 0:
		_message.text = "Sells for %d gold" % preview
		_message.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR)
		_message_left = 0.0
		return
	_message.add_theme_color_override(&"font_color", UiStyle.ERROR_COLOR)
	if _message_left > 0.0:
		_message_left -= delta
		if _message_left <= 0.0:
			_message.text = ""
	elif _message.text.begins_with("Sells"):
		_message.text = ""


## Undo sale is greyed with nothing sold; its hover text names the item and
## what buying it back costs.
func _show_undo() -> void:
	var sale := screen.shop.last_sale()
	_undo.disabled = sale.is_empty()
	if sale.is_empty():
		_undo.remove_meta(&"hover_text")
	else:
		_undo.set_meta(&"hover_text", "Buy back %s for %d gold" % [sale.item.display_name, sale.price])


## The Craft tab's fee, note and Craft button for what is in the inputs.
func _show_craft() -> void:
	var result := craft_preview()
	var fee := craft_fee()
	_fee_label.text = str(fee) if result else "–"
	var affordable := result != null and screen.shop.wallet.can_afford(fee)
	_fee_label.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if affordable or result == null else UiStyle.ERROR_COLOR)
	_craft_button.disabled = result == null
	_craft_note.text = craft_note()


## The Craft button's question: "Craft Muramana from Tear of the Goddess and
## Tear of the Goddess for 2100 gold?" Only asked when the inputs make
## something.
func craft_question() -> String:
	return "Craft %s from %s and %s for %d gold?" % [craft_preview().display_name,
		_first_input.item().display_name, _second_input.item().display_name, craft_fee()]


## The Craft tab's note line for what is in the inputs.
func craft_note() -> String:
	var first := _first_input.item()
	var second := _second_input.item()
	if first == null and second == null:
		return "Drag in two fragments, or your boots and a fragment."
	if first == null or second == null:
		var one := first if first else second
		if one.is_boots() and one.boots_tier >= 3:
			return "%s are fully upgraded." % one.display_name
		return "Now drag in a fragment."
	var result := craft_preview()
	if result:
		return "%s + %s → %s" % [first.display_name, second.display_name, result.display_name]
	if first.is_boots() or second.is_boots():
		var boots := first if first.is_boots() else second
		if boots.boots_tier >= 3:
			return "%s are fully upgraded." % boots.display_name
		var other := second if boots == first else first
		return "%s doesn't upgrade %s." % [other.display_name, boots.display_name]
	return "No legendary is made from %s and %s." % [first.display_name, second.display_name]


func _build_craft_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	page.add_child(row)
	_first_input = CraftSlot.new(screen, CraftSlot.Kind.INPUT, BackpackScreen.CRAFT_FIRST)
	_second_input = CraftSlot.new(screen, CraftSlot.Kind.INPUT, BackpackScreen.CRAFT_SECOND)
	_result_slot = CraftSlot.new(screen, CraftSlot.Kind.RESULT)
	row.add_child(_first_input)
	row.add_child(_sign("+"))
	row.add_child(_second_input)
	row.add_child(_sign("→"))
	row.add_child(_result_slot)

	var fee_row := HBoxContainer.new()
	fee_row.add_theme_constant_override(&"separation", 6)
	page.add_child(fee_row)
	fee_row.add_child(UiStyle.label("Fee", 16, UiStyle.DIM_COLOR))
	var coin := TextureRect.new()
	coin.texture = ShopSlot.COIN
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.custom_minimum_size = Vector2(20, 20)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fee_row.add_child(coin)
	_fee_label = UiStyle.label("–", 18, UiStyle.GOLD_COLOR)
	_fee_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fee_row.add_child(_fee_label)
	_craft_button = Button.new()
	_craft_button.text = "Craft"
	_craft_button.custom_minimum_size = Vector2(140, 38)
	UiStyle.style_button(_craft_button, 17)
	_craft_button.pressed.connect(func() -> void: screen.craft())
	fee_row.add_child(_craft_button)

	_craft_note = UiStyle.label("", 15, UiStyle.TEXT_COLOR)
	# Long item names wrap instead of widening the shop.
	_craft_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_craft_note.custom_minimum_size = Vector2(0, 40)
	page.add_child(_craft_note)
	return page


func _sign(text: String) -> Label:
	var sign := UiStyle.label(text, 26, UiStyle.DIM_COLOR)
	sign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return sign


func _recheck_inputs() -> void:
	_first_input.recheck()
	_second_input.recheck()
