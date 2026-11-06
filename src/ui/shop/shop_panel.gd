class_name ShopPanel
extends PanelContainer
## The merchant's shop, beside the backpack while it is open: a gold readout,
## the Items, Potions and Boots tabs, a hint line and the Refresh button in
## the bottom-right corner (Items only). Refused purchases flash a red
## message.
##
## The Boots tab upgrades the boots: [boots] + [fragment] -> [new boots], the
## fee and an Upgrade button. Its two inputs are filled by dragging from the
## backpack; they hold inventory indexes, are emptied when the shop closes and
## re-checked whenever the inventory changes.

const SLOT_GAP := 12
const MESSAGE_TIME := 1.6
const TAB_NAMES: Array[String] = ["Items", "Potions", "Boots"]
const ITEMS_TAB := 0
const BOOTS_TAB := 2
const HINTS: Array[String] = [
	"Right-click or drag to buy.\nDrag an item onto the red slot to sell it.",
	"Right-click or drag to buy. Potions fill\ncells 7 and 8 first, then the backpack.",
	"Drag your boots and a fragment into the\nslots, then pay the fee to upgrade them.",
]
const MESSAGES := {
	Shop.Result.NO_GOLD: "Not enough gold",
	Shop.Result.NO_ROOM: "No room in the backpack",
	Shop.Result.CELL_LOCKED: "That cell is locked",
	Shop.Result.CELL_TAKEN: "That cell is taken",
	Shop.Result.SOLD_OUT: "Already sold",
	Shop.Result.NOTHING_TO_REFRESH: "Nothing left to refresh",
	Shop.Result.NOT_UPGRADABLE: "That fragment doesn't upgrade these boots",
	Shop.Result.NO_BOOTS: "Put your boots in first",
	Shop.Result.WRONG_CELL: "That item can't go there",
}
const NO_BOOTS := "No boots: buy them in the Evolution Tree"

var screen: BackpackScreen

var _tab := 0
var _tab_buttons: Array[Button] = []
var _pages: Array[Control] = []
var _gold_label: Label
var _hint: Label
var _message: Label
var _refresh: Button
var _message_left := 0.0
var _boots_input: UpgradeSlot
var _fragment_input: UpgradeSlot
var _result_slot: UpgradeSlot
var _fee_label: Label
var _boots_note: Label
var _upgrade: Button


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
	var boots_page := _build_boots_page()
	box.add_child(boots_page)
	_pages = [items, potion_row, boots_page]

	_hint = UiStyle.label(HINTS[0], 14, UiStyle.DIM_COLOR)
	box.add_child(_hint)
	var bottom := HBoxContainer.new()
	box.add_child(bottom)
	_message = UiStyle.label("", 16, UiStyle.ERROR_COLOR)
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_message)
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


func show_tab(tab: int) -> void:
	_tab = tab
	for i in _pages.size():
		_pages[i].visible = i == tab
		UiStyle.style_button(_tab_buttons[i], 18, i == tab)
	_refresh.visible = tab == ITEMS_TAB
	_hint.text = HINTS[tab]


func current_tab() -> int:
	return _tab


## Shows why a purchase, refresh or upgrade failed, and flashes the slot's
## price red.
func refuse(result: Shop.Result, slot: ShopSlot = null) -> void:
	show_message(MESSAGES.get(result, ""))
	if slot:
		slot.flash_left = MESSAGE_TIME


## A red message for MESSAGE_TIME seconds.
func show_message(text: String) -> void:
	_message.text = text
	_message_left = MESSAGE_TIME


## The shop slots on `tab` (none on the Boots tab).
func slots(tab: int) -> Array[ShopSlot]:
	var found: Array[ShopSlot] = []
	for child in _pages[tab].get_children():
		if child is ShopSlot:
			found.append(child)
	return found


func boots_input() -> UpgradeSlot:
	return _boots_input


func fragment_input() -> UpgradeSlot:
	return _fragment_input


func result_slot() -> UpgradeSlot:
	return _result_slot


## The Boots tab input under `point` while that tab shows, or null.
func upgrade_input_at(point: Vector2) -> UpgradeSlot:
	if not visible or _tab != BOOTS_TAB:
		return null
	for input in [_boots_input, _fragment_input]:
		if input.get_global_rect().has_point(point):
			return input
	return null


## Puts inventory cell `cell` into the input `target` names
## (BackpackScreen.UPGRADE_BOOTS or UPGRADE_FRAGMENT). False, with a message,
## when the input doesn't take that item.
func load_input(target: int, cell: int) -> bool:
	var input := _boots_input if target == BackpackScreen.UPGRADE_BOOTS else _fragment_input
	if input.load_cell(cell):
		return true
	show_message("Only boots go there" if input.kind == UpgradeSlot.Kind.BOOTS else "Only a fragment goes there")
	return false


## Empties both inputs (the shop closed).
func clear_upgrade() -> void:
	_boots_input.clear()
	_fragment_input.clear()


## The boots the two inputs would make, or null.
func upgrade_preview() -> ItemData:
	if screen.shop == null:
		return null
	return screen.shop.upgrade_result(_boots_input.index, _fragment_input.index)


func _process(delta: float) -> void:
	if screen == null or screen.shop == null:
		return
	_gold_label.text = str(screen.shop.wallet.gold)
	# Greyed once every open slot is sold: a refresh would change nothing.
	_refresh.disabled = not screen.shop.can_refresh()
	if _tab == BOOTS_TAB:
		_show_upgrade()
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


## The Boots tab's fee, note and Upgrade button for what is in the inputs.
func _show_upgrade() -> void:
	var result := upgrade_preview()
	var boots := _boots_input.item()
	_fee_label.text = str(result.upgrade_cost) if result else "–"
	var affordable := result != null and screen.shop.wallet.can_afford(result.upgrade_cost)
	_fee_label.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if affordable or result == null else UiStyle.ERROR_COLOR)
	_upgrade.disabled = result == null
	if screen.inventory.boots() == null:
		_boots_note.text = NO_BOOTS
	elif boots == null:
		_boots_note.text = "Drag your boots into the first slot."
	elif boots.boots_tier >= 3:
		_boots_note.text = "%s are fully upgraded." % boots.display_name
	elif _fragment_input.index < 0:
		_boots_note.text = "Now drag in a fragment."
	elif result == null:
		_boots_note.text = "That fragment doesn't upgrade %s." % boots.display_name
	else:
		_boots_note.text = "%s → %s" % [boots.display_name, result.display_name]


func _build_boots_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	page.add_child(row)
	_boots_input = UpgradeSlot.new(screen, UpgradeSlot.Kind.BOOTS)
	_fragment_input = UpgradeSlot.new(screen, UpgradeSlot.Kind.FRAGMENT)
	_result_slot = UpgradeSlot.new(screen, UpgradeSlot.Kind.RESULT)
	row.add_child(_boots_input)
	row.add_child(_sign("+"))
	row.add_child(_fragment_input)
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
	_upgrade = Button.new()
	_upgrade.text = "Upgrade"
	_upgrade.custom_minimum_size = Vector2(140, 38)
	UiStyle.style_button(_upgrade, 17)
	_upgrade.pressed.connect(func() -> void: screen.upgrade_boots())
	fee_row.add_child(_upgrade)

	_boots_note = UiStyle.label("", 15, UiStyle.TEXT_COLOR)
	# Long boot names wrap instead of widening the shop.
	_boots_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_boots_note.custom_minimum_size = Vector2(0, 40)
	page.add_child(_boots_note)
	return page


func _sign(text: String) -> Label:
	var sign := UiStyle.label(text, 26, UiStyle.DIM_COLOR)
	sign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return sign


func _recheck_inputs() -> void:
	_boots_input.recheck()
	_fragment_input.recheck()
