class_name ShopSlot
extends Control
## One item for sale in the merchant's shop, as a row: its icon in a well
## whose rim follows the item, its name, a line with its stats (a potion's
## effect) and, on the right, its price with the coin. It is a slot of the
## Items tab (chained while locked, with a note naming the Evolution Tree
## node that opens it; SOLD once bought) or a potion of the Potions tab,
## with its key in the well's corner. Mouse input goes to the backpack
## screen, which runs the drag.

## Narrow enough for an item's card to open on the row's right, clear of
## the backpack, on a 16:9 screen.
const WIDTH := 392.0
const HEIGHT := 68.0
## The well with the icon, the room around it and between it and the text.
const WELL := 56.0
const PAD := 6.0
const ICON_INSET := 4.0
const TEXT_GAP := 12.0
const RADIUS := 6
## The row behind an item for sale; fainter once sold or while locked.
const ROW_FILL := Color(0.02, 0.03, 0.05, 0.55)
const ROW_RIM := Color(0.36, 0.4, 0.48, 0.45)
const ROW_HOVER := Color(1.0, 0.81, 0.35, 0.07)
const CLOSED_FILL := Color(0.02, 0.03, 0.05, 0.28)
const CLOSED_RIM := Color(0.36, 0.4, 0.48, 0.22)
const CLOSED_TEXT := Color(0.55, 0.58, 0.65)
const NAME_FONT := 17
const LINE_FONT := 13
const LINE_ICON := 16.0
## Between two words of the line, and more before the next stat's icon.
const LINE_SPACE := 4.0
const LINE_GAP := 6.0
const PRICE_FONT := 18
const COIN_SIZE := 20.0
const PRICE_COLOR := Color("ffcf5a")
const TOO_EXPENSIVE := Color("ff6a5a")
const KEY_COLOR := ItemCell.KEY_COLOR
const CHAIN := preload("res://assets/art/ui/chain.svg")
const COIN := preload("res://assets/art/ui/gold.svg")
## A chained slot's note (in the row and on hover): the Evolution Tree node
## that opens it.
const LOCKED_NOTE := "Buy Merchant Stock in the Evolution Tree"

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
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
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


## The row's first line: the item's name, SOLD or Locked ("" with no shop).
func title() -> String:
	if is_locked():
		return "Locked"
	if is_sold():
		return "SOLD"
	var shown := item()
	return shown.display_name if shown else ""


## The key that drinks the potion this row sells, as bound now ("" for an
## item).
func key_text() -> String:
	if potion == null:
		return ""
	return GameSettings.instance().short_key_label(Inventory.key_action(Inventory.potion_cell(potion)))


## The line under an item's name, as parts drawn left to right, each
## {icon, text, color}: every stat's icon and amount in the stat's colour
## ("+40", "+10%"), with the stat's name after a lone one ("+30 Attack
## Damage"); a potion's "Restores 200 HP over 5 s"; the item's kind when it
## has no stats.
static func line_parts(shown: ItemData) -> Array[Dictionary]:
	var parts: Array[Dictionary] = []
	if shown.is_potion():
		parts.append(_part("Restores", UiStyle.DIM_COLOR))
		if shown.restore_hp > 0.0:
			parts.append(_part("%s HP" % TooltipText.number(shown.restore_hp), StatStyle.color(&"max_hp")))
		if shown.restore_mana > 0.0:
			parts.append(_part("%s mana" % TooltipText.number(shown.restore_mana), StatStyle.color(&"max_mana")))
		parts.append(_part("over %s s" % TooltipText.number(shown.restore_time), UiStyle.DIM_COLOR))
		return parts
	for key: StringName in shown.stats:
		parts.append(_part(ItemStats.amount(key, shown.stats[key]), StatStyle.color(key), StatStyle.icon(key)))
	if shown.stats.size() == 1:
		parts.append(_part(ItemStats.NAMES[shown.stats.keys()[0]], UiStyle.DIM_COLOR))
	elif shown.stats.is_empty():
		parts.append(_part(TooltipCard.KIND_NAMES[shown.kind], UiStyle.DIM_COLOR))
	return parts


## The text of line_parts, parts joined by spaces.
static func line_text(shown: ItemData) -> String:
	return " ".join(line_parts(shown).map(func(part: Dictionary) -> String: return part.text))


static func _part(text: String, color: Color, icon: Texture2D = null) -> Dictionary:
	return {"icon": icon, "text": text, "color": color}


func tooltip_content() -> Control:
	if is_locked() and not screen.is_dragging():
		return TooltipCard.note(LOCKED_NOTE)
	var shown := item()
	return TooltipCard.item(shown, screen.inventory.catalog, screen.inventory) if shown and not screen.is_dragging() else null


func _gui_input(event: InputEvent) -> void:
	screen.on_shop_slot_input(self, event)


func _process(delta: float) -> void:
	if flash_left > 0.0:
		flash_left = maxf(flash_left - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var well := Rect2(PAD, (size.y - WELL) * 0.5, WELL, WELL)
	var shown := item()
	var font := ThemeDB.fallback_font
	var text_x := well.end.x + TEXT_GAP
	var middle := size.y * 0.5
	if shown == null:
		_draw_row(rect, CLOSED_FILL, CLOSED_RIM)
		var closed := UiStyle.cell_style(ItemCell.LOCKED_RIM, false, ItemCell.RADIUS)
		closed.bg_color = ItemCell.LOCKED_FILL
		draw_style_box(closed, well)
		if is_locked():
			draw_texture_rect(CHAIN, well.grow(-ItemCell.CHAIN_INSET + 2.0), false, Color(1, 1, 1, ItemCell.CHAIN_ALPHA))
			draw_string(font, Vector2(text_x, middle - 4.0), title(), HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT, CLOSED_TEXT)
			draw_string(font, Vector2(text_x, middle + 16.0), LOCKED_NOTE, HORIZONTAL_ALIGNMENT_LEFT, size.x - text_x - PAD, LINE_FONT, UiStyle.DISABLED_FONT)
		else:
			draw_string(font, Vector2(text_x, middle + 6.0), title(), HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT, CLOSED_TEXT)
		return
	var hovered := get_global_rect().has_point(Pointer.in_world(self))
	_draw_row(rect, ROW_FILL, UiStyle.GOLD_COLOR if hovered else ROW_RIM)
	if hovered:
		_draw_row(rect, ROW_HOVER, Color.TRANSPARENT)
	draw_style_box(UiStyle.cell_style(UiStyle.item_rim(shown), hovered, ItemCell.RADIUS), well)
	if not (screen.is_dragging() and screen.dragged_shop_slot() == self):
		ItemIcon.draw_item(self, shown, well.grow(-ICON_INSET))
	ItemIcon.draw_tag(self, key_text(), well.grow(-2.0 if hovered else -1.0), CORNER_TOP_LEFT, KEY_COLOR, ItemCell.RADIUS - 1)
	var affordable := screen.shop != null and screen.shop.wallet.can_afford(shown.cost)
	var price_color := PRICE_COLOR if affordable and flash_left <= 0.0 else TOO_EXPENSIVE
	var price := str(shown.cost)
	var price_width := font.get_string_size(price, HORIZONTAL_ALIGNMENT_LEFT, -1, PRICE_FONT).x
	var price_x := size.x - PAD - 6.0 - price_width
	draw_string(font, Vector2(price_x, middle + 6.5), price, HORIZONTAL_ALIGNMENT_LEFT, -1, PRICE_FONT, price_color)
	draw_texture_rect(COIN, Rect2(price_x - COIN_SIZE - 5.0, middle - COIN_SIZE * 0.5, COIN_SIZE, COIN_SIZE), false)
	var text_width := price_x - COIN_SIZE - 5.0 - TEXT_GAP - text_x
	var name_color := UiStyle.TEXT_COLOR if shown.is_fragment() or shown.is_potion() else UiStyle.TITLE_COLOR
	draw_string(font, Vector2(text_x, middle - 4.0), title(), HORIZONTAL_ALIGNMENT_LEFT, text_width, NAME_FONT, name_color)
	_draw_line(shown, Vector2(text_x, middle + 17.0))


## The row's box: a dark strip with a thin rim.
func _draw_row(rect: Rect2, fill: Color, rim: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = rim
	box.set_border_width_all(1)
	box.set_corner_radius_all(RADIUS)
	draw_style_box(box, rect)


## The line under the name (line_parts), its baseline at `at`: a stat's icon
## sits before its amount, and the next stat a little further off.
func _draw_line(shown: ItemData, at: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var x := at.x
	for part: Dictionary in line_parts(shown):
		if part.icon:
			if x > at.x:
				x += LINE_GAP
			draw_texture_rect(part.icon, Rect2(x, at.y - LINE_ICON + 3.0, LINE_ICON, LINE_ICON), false)
			x += LINE_ICON + 2.0
		draw_string(font, Vector2(x, at.y), part.text, HORIZONTAL_ALIGNMENT_LEFT, -1, LINE_FONT, part.color)
		x += font.get_string_size(part.text, HORIZONTAL_ALIGNMENT_LEFT, -1, LINE_FONT).x + LINE_SPACE
