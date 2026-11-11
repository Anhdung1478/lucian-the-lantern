class_name ItemCell
extends Control
## One cell of the backpack screen: a dark well whose rim follows the item in
## it (UiStyle.item_rim) and turns gold under the mouse, and under a dragged
## item it would take. It is a backpack cell (a chain when locked), an equip
## slot (with its key number, or a chain when locked), a potion cell (its
## key; its potion faded while empty), the boots cell (Boots of Speed faded
## while empty) or the sell slot (red while the shop is open). Draws the item
## from the inventory, or nothing while that item sits in a Craft input, and
## passes mouse input to the screen.

enum Style { BACKPACK, EQUIP, SELL, POTION, BOOTS }

const SIZE := 64.0
const ICON_INSET := 5.0
const RADIUS := 5
const FILLS := {
	Style.EQUIP: Color("2a221a"), Style.SELL: Color("1e1a16"),
	Style.POTION: Color("231d1d"), Style.BOOTS: Color("1d2023"),
}
const BORDERS := {
	Style.EQUIP: Color("8c6e45"), Style.SELL: Color("5a4a38"),
	Style.POTION: Color("9a6a52"), Style.BOOTS: Color("7d8794"),
}
## How strongly an empty potion or boots cell shows what goes in it.
const PLACEHOLDER_ALPHA := 0.3
## A locked cell: a fainter well and rim under a dim chain.
const LOCKED_FILL := Color(0.02, 0.028, 0.045, 0.55)
const LOCKED_RIM := Color(0.36, 0.4, 0.48, 0.3)
const CHAIN_INSET := 14.0
const CHAIN_ALPHA := 0.45
## The gold wash over a cell that would take the dragged item.
const DROP_WASH := Color(1.0, 0.81, 0.35, 0.14)
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
## The mouse is over the cell.
var hovered := false:
	set(value):
		hovered = value
		queue_redraw()


func _init(cell_index: int, cell_style: Style, owner_screen: BackpackScreen) -> void:
	index = cell_index
	style = cell_style
	screen = owner_screen
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_entered.connect(set.bind(&"hovered", true))
	mouse_exited.connect(set.bind(&"hovered", false))


## The item the cell shows: null while it sits in a Craft input
## (BackpackScreen.in_craft), so the cell looks empty and can't be picked up.
func item() -> ItemData:
	if index < 0 or screen.in_craft(index):
		return null
	return screen.inventory.item_at(index)


func is_locked() -> bool:
	return index >= 0 and screen.inventory.is_locked(index)


## The rim's colour: the kind of the item it shows (UiStyle.item_rim).
func rim() -> Color:
	return UiStyle.item_rim(_shown())


## Whether the rim is gold: the mouse rests on the cell's item, or the
## dragged item is over the cell and would land in it
## (BackpackScreen.takes_drop).
func is_lit() -> bool:
	if screen.is_dragging():
		return index >= 0 and screen.target_index() == index and screen.takes_drop(index)
	return hovered and item() != null


## The item drawn in the cell: none while it is the one being dragged.
func _shown() -> ItemData:
	return null if index == screen.dragged_index() else item()


func tooltip_content() -> Control:
	if style == Style.SELL and screen.is_shopping() and not screen.is_dragging():
		return TooltipCard.note("Drop an item here to sell it for 70% of its cost (Guardian Angel: 40%).")
	if screen.in_craft(index):
		return null if screen.is_dragging() else TooltipCard.note("In the Craft tab: drag it back here, or right-click its input")
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
	if style == Style.BACKPACK:
		_draw_well(rect)
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


## The dark well: a locked one is fainter under its chain; an open one has
## its item, with a stack's count in a corner tag.
func _draw_well(rect: Rect2) -> void:
	if is_locked():
		var locked := UiStyle.cell_style(LOCKED_RIM, false, RADIUS)
		locked.bg_color = LOCKED_FILL
		draw_style_box(locked, rect)
		draw_texture_rect(CHAIN, rect.grow(-CHAIN_INSET), false, Color(1, 1, 1, CHAIN_ALPHA))
		return
	var lit := is_lit()
	draw_style_box(UiStyle.cell_style(rim(), lit, RADIUS), rect)
	if lit and screen.is_dragging():
		var wash := StyleBoxFlat.new()
		wash.bg_color = DROP_WASH
		wash.set_corner_radius_all(RADIUS)
		draw_style_box(wash, rect)
	var shown := _shown()
	if shown == null:
		return
	ItemIcon.draw_item(self, shown, rect.grow(-ICON_INSET))
	var count := screen.inventory.count_at(index)
	ItemIcon.draw_tag(self, str(count) if count > 1 else "", rect.grow(-2.0), CORNER_BOTTOM_RIGHT, Color.WHITE, RADIUS - 2)


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
