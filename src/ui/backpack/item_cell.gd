class_name ItemCell
extends Control
## One cell of the backpack screen: a dark well whose rim follows the item in
## it (UiStyle.item_rim) and turns gold under the mouse, and under a dragged
## item it would take. It is a backpack cell or an equip slot (fainter, under
## a chain, when locked), a potion cell (its potion faded while empty), the
## boots cell (Boots of Speed faded while empty) or the sell slot (red while
## the shop is open, a blank well otherwise). An equip slot and a potion cell
## carry their key in a corner tab. Draws the item from the inventory, or
## nothing while that item sits in a Craft input, and passes mouse input to
## the screen.

enum Style { BACKPACK, EQUIP, SELL, POTION, BOOTS }

const SIZE := 64.0
const ICON_INSET := 5.0
const RADIUS := 5
## How strongly an empty potion or boots cell shows what goes in it, and how
## strongly its rim shows that item's kind.
const PLACEHOLDER_ALPHA := 0.3
const EMPTY_RIM_ALPHA := 0.6
## A locked cell: a fainter well and rim under a dim chain.
const LOCKED_FILL := Color(0.02, 0.028, 0.045, 0.55)
const LOCKED_RIM := Color(0.36, 0.4, 0.48, 0.3)
const CHAIN_INSET := 14.0
const CHAIN_ALPHA := 0.45
## The gold wash over a cell that would take the dragged item.
const DROP_WASH := Color(1.0, 0.81, 0.35, 0.14)
## The sell slot: red, lighter under an item, with a coin over its word.
const SELL_FILL := Color("5e1714")
const SELL_OVER := Color("8a2a22")
const SELL_TEXT := Color("ffd8c8")
const SELL_FONT := 15
const SELL_COIN := 20.0
const KEY_COLOR := Color("e6d3a3")
const CHAIN := preload("res://assets/art/ui/chain.svg")
const COIN := preload("res://assets/art/ui/gold.svg")

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


## The rim's colour: the kind of the item it shows (UiStyle.item_rim), or,
## fainter, of the item an empty potion or boots cell waits for.
func rim() -> Color:
	var shown := _shown()
	if shown == null and placeholder() != null:
		return Color(UiStyle.item_rim(placeholder()), EMPTY_RIM_ALPHA)
	return UiStyle.item_rim(shown)


## The key in the cell's corner tab, as bound now ("" for a cell with no key).
func key_text() -> String:
	var action := Inventory.key_action(index) if index >= 0 else &""
	return GameSettings.instance().short_key_label(action) if action != &"" else ""


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
	if is_locked() or style == Style.SELL:
		_draw_closed(rect)
		return
	var lit := is_lit()
	draw_style_box(UiStyle.cell_style(rim(), lit, RADIUS), rect)
	if lit and screen.is_dragging():
		var wash := StyleBoxFlat.new()
		wash.bg_color = DROP_WASH
		wash.set_corner_radius_all(RADIUS)
		draw_style_box(wash, rect)
	# The tags sit inside the rim, which is thicker while lit.
	var inside := rect.grow(-2.0 if lit else -1.0)
	var shown := _shown()
	if shown:
		ItemIcon.draw_item(self, shown, rect.grow(-ICON_INSET))
		var count := screen.inventory.count_at(index)
		ItemIcon.draw_tag(self, str(count) if count > 1 else "", inside, CORNER_BOTTOM_RIGHT, Color.WHITE, RADIUS - 1)
	else:
		ItemIcon.draw_item(self, placeholder(), rect.grow(-ICON_INSET), Color(1, 1, 1, PLACEHOLDER_ALPHA))
	ItemIcon.draw_tag(self, key_text(), inside, CORNER_TOP_LEFT, KEY_COLOR, RADIUS - 1)


## A cell that takes nothing: a fainter well, under a dim chain when it is
## locked (the sell slot outside the shop has none).
func _draw_closed(rect: Rect2) -> void:
	var box := UiStyle.cell_style(LOCKED_RIM, false, RADIUS)
	box.bg_color = LOCKED_FILL
	draw_style_box(box, rect)
	if is_locked():
		draw_texture_rect(CHAIN, rect.grow(-CHAIN_INSET), false, Color(1, 1, 1, CHAIN_ALPHA))


## The red sell slot: a coin over "SELL", or over the gold the dragged item
## would bring ("NO" for one that can't be sold).
func _draw_sell(rect: Rect2) -> void:
	var over := screen.target_index() == BackpackScreen.SELL
	var box := UiStyle.cell_style(UiStyle.BAD_COLOR, over, RADIUS)
	box.bg_color = SELL_OVER if over else SELL_FILL
	box.set_border_width_all(2)
	draw_style_box(box, rect)
	var font := ThemeDB.fallback_font
	var text := "SELL"
	if over:
		text = "NO" if screen.sell_refused() else "+%d" % screen.sell_preview()
	var middle := rect.get_center()
	draw_texture_rect(COIN, Rect2(middle.x - SELL_COIN * 0.5, middle.y - SELL_COIN - 1.0, SELL_COIN, SELL_COIN), false)
	var baseline := middle.y + SELL_FONT + 2.0
	draw_string_outline(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, SELL_FONT, 4, Color.BLACK)
	draw_string(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, SELL_FONT, UiStyle.GOLD_COLOR if over else SELL_TEXT)
