class_name ItemCell
extends Control
## One cell of the backpack screen: a tan backpack cell, a dark equip slot
## (with its key number, or a chain when locked), a potion cell (its key; its
## potion faded while empty), the boots cell (Boots of Speed faded while
## empty) or the sell slot (red while the shop is open). Draws the item from
## the inventory and passes mouse input to the screen.

enum Style { BACKPACK, EQUIP, SELL, POTION, BOOTS }

const SIZE := 64.0
const ICON_INSET := 5.0
const FILLS := {
	Style.BACKPACK: Color("d9c59b"), Style.EQUIP: Color("2a221a"), Style.SELL: Color("1e1a16"),
	Style.POTION: Color("231d1d"), Style.BOOTS: Color("1d2023"),
}
const BORDERS := {
	Style.BACKPACK: Color("8c6e45"), Style.EQUIP: Color("8c6e45"), Style.SELL: Color("5a4a38"),
	Style.POTION: Color("9a6a52"), Style.BOOTS: Color("7d8794"),
}
## How strongly an empty potion or boots cell shows what goes in it.
const PLACEHOLDER_ALPHA := 0.3
const TARGET_BORDER := Color("ffcf5a")
const SELL_FILL := Color("7a1f1a")
const SELL_BORDER := Color("d04a3a")
const SELL_TEXT := Color("ffd8c8")
const KEY_COLOR := Color("c9b48a")
const CHAIN := preload("res://assets/art/ui/chain.svg")

## Inventory index; -1 for the sell slot.
var index := -1
var style := Style.BACKPACK
var screen: BackpackScreen


func _init(cell_index: int, cell_style: Style, owner_screen: BackpackScreen) -> void:
	index = cell_index
	style = cell_style
	screen = owner_screen
	custom_minimum_size = Vector2(SIZE, SIZE)


func item() -> ItemData:
	return screen.inventory.item_at(index) if index >= 0 else null


func is_locked() -> bool:
	return index >= 0 and screen.inventory.is_locked(index)


func tooltip_content() -> Control:
	if style == Style.SELL and screen.is_shopping() and not screen.is_dragging():
		return TooltipCard.note("Drop an item here to sell it for 70% of its cost (Guardian Angel: 40%).")
	if is_locked() and style == Style.BACKPACK:
		return TooltipCard.note("Buy Backpack Slots in the Evolution Tree")
	var shown := item()
	if shown == null and not screen.is_dragging():
		match style:
			Style.BOOTS:
				return TooltipCard.note("Buy Boots in the Evolution Tree")
			Style.POTION:
				var key := GameSettings.instance().key_label(Inventory.key_action(index))
				var kind := "Health" if index == Inventory.HP_POTION_CELL else "Mana"
				return TooltipCard.note("%s potions go here: press %s to drink one" % [kind, key])
	return TooltipCard.item(shown, screen.inventory.catalog) if shown and not screen.is_dragging() else null


## What an empty potion or boots cell shows faded: its potion, or Boots of
## Speed. Null for the other cells.
func placeholder() -> ItemData:
	var catalog := screen.inventory.catalog
	if catalog == null:
		return null
	if style == Style.BOOTS:
		return catalog.find(&"boots_of_speed")
	if style == Style.POTION:
		for potion in catalog.potions():
			if Inventory.potion_cell(potion) == index:
				return potion
	return null


func _gui_input(event: InputEvent) -> void:
	screen.on_cell_input(self, event)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if style == Style.SELL and screen.is_shopping():
		_draw_sell(rect)
		return
	var fill := StyleBoxFlat.new()
	fill.bg_color = FILLS[style]
	fill.border_color = TARGET_BORDER if screen.target_index() == index and index >= 0 else BORDERS[style]
	fill.set_border_width_all(3 if fill.border_color == TARGET_BORDER else 2)
	fill.set_corner_radius_all(6)
	draw_style_box(fill, rect)
	if is_locked():
		draw_texture_rect(CHAIN, rect.grow(-8.0), false, Color(1, 1, 1, 0.85))
		return
	if index != screen.dragged_index() and item():
		ItemIcon.draw_item(self, item(), rect.grow(-ICON_INSET))
		if index >= 0:
			ItemIcon.draw_count(self, screen.inventory.count_at(index), rect.grow(-2.0))
	elif style == Style.POTION or style == Style.BOOTS:
		ItemIcon.draw_item(self, placeholder(), rect.grow(-ICON_INSET), Color(1, 1, 1, PLACEHOLDER_ALPHA))
	var action := Inventory.key_action(index) if index >= 0 else &""
	if action != &"":
		var font := ThemeDB.fallback_font
		var key := GameSettings.instance().short_key_label(action)
		draw_string_outline(font, Vector2(5, 15), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color.BLACK)
		draw_string(font, Vector2(5, 15), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, KEY_COLOR)


## The red sell slot: "SELL", or the gold the dragged item would bring.
func _draw_sell(rect: Rect2) -> void:
	var over := screen.target_index() == BackpackScreen.SELL
	var fill := StyleBoxFlat.new()
	fill.bg_color = SELL_FILL.lightened(0.15) if over else SELL_FILL
	fill.border_color = TARGET_BORDER if over else SELL_BORDER
	fill.set_border_width_all(3 if over else 2)
	fill.set_corner_radius_all(6)
	draw_style_box(fill, rect)
	var font := ThemeDB.fallback_font
	var text := "SELL"
	if over:
		text = "NO" if screen.sell_refused() else "+%d" % screen.sell_preview()
	draw_string_outline(font, Vector2(0, rect.size.y * 0.5 + 6.0), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 16, 4, Color.BLACK)
	draw_string(font, Vector2(0, rect.size.y * 0.5 + 6.0), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 16, TARGET_BORDER if over else SELL_TEXT)
