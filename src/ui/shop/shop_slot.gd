class_name ShopSlot
extends Control
## One item for sale in the merchant's shop, with its price under it: a slot
## of the Items tab (chained while locked, SOLD once bought) or a potion of the
## Potions tab. Mouse input goes to the backpack screen, which runs the drag.

const SIZE := 64.0
const PRICE_HEIGHT := 26.0
const FILL := Color(0.09, 0.105, 0.14)
const BORDER := Color(0.36, 0.4, 0.48)
const HOVER_BORDER := Color("ffcf5a")
const PRICE_COLOR := Color("ffcf5a")
const TOO_EXPENSIVE := Color("ff6a5a")
const CHAIN := preload("res://assets/art/ui/chain.svg")
const COIN := preload("res://assets/art/ui/gold.svg")

var screen: BackpackScreen
## Items tab slot, or -1 for a potion.
var stock_slot := -1
var potion: ItemData
## Seconds left of the red flash after a refused purchase.
var flash_left := 0.0


func _init(owner_screen: BackpackScreen, slot := -1, potion_item: ItemData = null) -> void:
	screen = owner_screen
	stock_slot = slot
	potion = potion_item
	custom_minimum_size = Vector2(SIZE, SIZE + PRICE_HEIGHT)
	mouse_filter = MOUSE_FILTER_STOP


## What this slot sells right now, or null (locked, sold or no shop open).
func item() -> ItemData:
	if potion:
		return potion
	if screen.shop == null:
		return null
	return screen.shop.stock.item_at(stock_slot)


func is_locked() -> bool:
	return stock_slot >= 0 and screen.shop != null and screen.shop.stock.is_locked(stock_slot)


func is_sold() -> bool:
	return stock_slot >= 0 and screen.shop != null and screen.shop.stock.is_sold(stock_slot) and not is_locked()


func tooltip_content() -> Control:
	var shown := item()
	return TooltipCard.item(shown, screen.inventory.catalog) if shown and not screen.is_dragging() else null


func _gui_input(event: InputEvent) -> void:
	screen.on_shop_slot_input(self, event)


func _process(delta: float) -> void:
	if flash_left > 0.0:
		flash_left = maxf(flash_left - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(SIZE, SIZE))
	var box := StyleBoxFlat.new()
	box.bg_color = FILL
	var hovered := get_global_rect().has_point(get_global_mouse_position()) and item() != null
	box.border_color = HOVER_BORDER if hovered else BORDER
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	draw_style_box(box, rect)
	var font := ThemeDB.fallback_font
	if is_locked():
		draw_texture_rect(CHAIN, rect.grow(-8.0), false, Color(1, 1, 1, 0.85))
		return
	if is_sold():
		draw_string(font, Vector2(0, SIZE * 0.5 + 6.0), "SOLD", HORIZONTAL_ALIGNMENT_CENTER, SIZE, 16, Color(0.55, 0.58, 0.65))
		return
	var shown := item()
	if shown == null:
		return
	if not (screen.is_dragging() and screen.dragged_shop_slot() == self):
		ItemIcon.draw_item(self, shown, rect.grow(-5.0))
	var affordable := screen.shop != null and screen.shop.wallet.can_afford(shown.cost)
	var color := PRICE_COLOR if affordable and flash_left <= 0.0 else TOO_EXPENSIVE
	draw_texture_rect(COIN, Rect2(2.0, SIZE + 5.0, 18.0, 18.0), false)
	draw_string(font, Vector2(20.0, SIZE + 20.0), str(shown.cost), HORIZONTAL_ALIGNMENT_CENTER, SIZE - 20.0, 15, color)
