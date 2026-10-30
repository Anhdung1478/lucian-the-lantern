class_name ShopPanel
extends PanelContainer
## The merchant's shop, beside the backpack while it is open: a gold readout,
## the Items and Potions tabs, a hint line and the Refresh button in the
## bottom-right corner. Refused purchases flash a red message.

const SLOT_GAP := 12
const MESSAGE_TIME := 1.6
const MESSAGES := {
	Shop.Result.NO_GOLD: "Not enough gold",
	Shop.Result.NO_ROOM: "No room in the backpack",
	Shop.Result.CELL_LOCKED: "That cell is locked",
	Shop.Result.CELL_TAKEN: "That cell is taken",
	Shop.Result.SOLD_OUT: "Already sold",
}

var screen: BackpackScreen

var _tab := 0
var _tab_buttons: Array[Button] = []
var _pages: Array[Control] = []
var _gold_label: Label
var _message: Label
var _refresh: Button
var _message_left := 0.0


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
	for i in 2:
		var button := Button.new()
		button.text = ["Items", "Potions"][i]
		button.custom_minimum_size = Vector2(130, 40)
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
	_pages = [items, potion_row]

	var hint := UiStyle.label("Right-click or drag to buy.\nDrag an item onto the red slot to sell it.", 14, UiStyle.DIM_COLOR)
	box.add_child(hint)
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
	show_tab(0)


## Shows what the open shop charges for a refresh.
func show_refresh_cost(cost: int) -> void:
	_refresh.text = "Refresh  %d" % cost


func show_tab(tab: int) -> void:
	_tab = tab
	for i in _pages.size():
		_pages[i].visible = i == tab
		UiStyle.style_button(_tab_buttons[i], 18, i == tab)
	_refresh.visible = tab == 0


## Shows why a purchase or refresh failed, and flashes the slot's price red.
func refuse(result: Shop.Result, slot: ShopSlot = null) -> void:
	_message.text = MESSAGES.get(result, "")
	_message_left = MESSAGE_TIME
	if slot:
		slot.flash_left = MESSAGE_TIME


func slots(tab: int) -> Array[ShopSlot]:
	var found: Array[ShopSlot] = []
	found.assign(_pages[tab].get_children())
	return found


func _process(delta: float) -> void:
	if screen == null or screen.shop == null:
		return
	_gold_label.text = str(screen.shop.wallet.gold)
	# The dragged icon covers the sell slot, so its price shows here too.
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
