class_name ItemCell
extends Control
## One cell of the backpack screen: a dark well whose rim follows the item in
## it (UiStyle.item_rim) and turns gold under the mouse, and under a dragged
## item it would take; the gold eases in and out (UiMotion.lit). It is a
## backpack cell (a fainter, empty well when locked), an equip slot (fainter,
## under a chain, when locked: there are few and each is a goal), a potion
## cell (its potion faded while empty), the boots cell (Boots of Speed faded
## while empty) or the sell slot (in the merchant's foot: a dark well with a
## red rim, filling red while an item is over it). An equip slot and a potion
## cell carry their key in a bottom-right tab, a stack its count top-left.
## Draws the item from the inventory, or nothing while that item sits in a
## Craft input, and passes mouse input to the screen. A cell that just got an
## item (bought or crafted) lands it: the icon settles from a little bigger.

enum Style { BACKPACK, EQUIP, SELL, POTION, BOOTS }

const SIZE := 64.0
const ICON_INSET := 5.0
const RADIUS := 5
## How strongly an empty potion or boots cell shows what goes in it, and how
## strongly its rim shows that item's kind.
const PLACEHOLDER_ALPHA := 0.3
const EMPTY_RIM_ALPHA := 0.6
## A locked cell: a fainter well and rim (a locked equip slot under a dim
## chain; a locked backpack cell's rim fainter still, and no chain).
const LOCKED_FILL := Color(0.02, 0.028, 0.045, 0.55)
const LOCKED_RIM := Color(0.36, 0.4, 0.48, 0.3)
const LOCKED_PACK_RIM := Color(0.36, 0.4, 0.48, 0.18)
const CHAIN_INSET := 14.0
const CHAIN_ALPHA := 0.45
## The gold wash over a cell that would take the dragged item.
const DROP_WASH := Color(1.0, 0.81, 0.35, 0.14)
## The sell slot: a dark well with a red rim and a coin over its word; it
## fills red while an item is over it.
const SELL_OVER := Color("8a2a22")
const SELL_TEXT := Color("ffd8c8")
const SELL_FONT := UiStyle.FONT_TAG
const SELL_COIN := 20.0
## A landed item's icon starts this much bigger and settles over LAND_TIME.
const LAND_SCALE := 0.15
const LAND_TIME := 0.2
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
		refresh_lit()
## The gold look, 0 to 1 (UiMotion.lit), and the landing, 1 to 0.
var lit_t := 0.0
var land_t := 0.0

## What refresh_lit() last eased to, and whether that was a drop's wash.
var _lit_on := false
var _washed := false
var _land: Tween


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


## Eases the gold look toward what is_lit() says now (the sell slot: an item
## held over it), and redraws.
func refresh_lit() -> void:
	var on := is_lit()
	if style == Style.SELL:
		on = screen.is_shopping() and screen.target_index() == BackpackScreen.SELL
	if on != _lit_on:
		_lit_on = on
		if on:
			_washed = screen.is_dragging()
		UiMotion.lit(self, on)
	queue_redraw()


## The item just put in the cell lands: its icon settles from a little
## bigger over LAND_TIME (nothing to see while UiMotion.off()).
func land() -> void:
	if _land and _land.is_valid():
		_land.kill()
	_land = null
	land_t = 0.0
	if UiMotion.off() or not is_inside_tree():
		queue_redraw()
		return
	land_t = 1.0
	_land = UiMotion.tween(self)
	_land.tween_method(_set_land, 1.0, 0.0, LAND_TIME)


func _set_land(t: float) -> void:
	land_t = t
	queue_redraw()


## Whether this is an empty cell of the strip under the backpack: its note
## opens above the strip, clear of the cells beside it.
func _strip_note() -> bool:
	return style in [Style.EQUIP, Style.POTION, Style.BOOTS] and item() == null and not screen.is_dragging()


func tooltip_place() -> HoverTip.Place:
	return HoverTip.Place.ABOVE if _strip_note() else HoverTip.Place.BESIDE


## Cards open 8 px beside the cell; a strip cell's note above the whole strip.
func tooltip_anchor() -> Rect2:
	# The cell's row is in the strip's plate.
	var strip := get_parent().get_parent() as Control if get_parent() else null
	if _strip_note() and strip:
		return strip.get_global_rect()
	return get_global_rect().grow_individual(2.0, 0.0, 2.0, 0.0)


## The item drawn in the cell: none while it is the one being dragged.
func _shown() -> ItemData:
	return null if index == screen.dragged_index() else item()


func tooltip_content() -> Control:
	if style == Style.SELL and screen.is_shopping() and not screen.is_dragging():
		return TooltipCard.note(Lang.t("Drop an item here to sell it for 70% of its cost (Guardian Angel: 40%)."))
	if screen.in_craft(index):
		return null if screen.is_dragging() else TooltipCard.note(Lang.t("In the Craft tab: drag it back here, or right-click its input"))
	if is_locked() and style == Style.BACKPACK:
		return TooltipCard.note(Lang.t("Buy Backpack Slots in the Evolution Tree"))
	var shown := item()
	if shown == null and not screen.is_dragging():
		match style:
			Style.BOOTS:
				return TooltipCard.note(Lang.t("Buy Boots in the Evolution Tree"))
			Style.POTION:
				var key := GameSettings.instance().key_label(Inventory.key_action(index))
				var kind := "Health" if index == Inventory.HP_POTION_CELL else "Mana"
				return TooltipCard.note(Lang.t("%s potions go here: press %s to drink one") % [Lang.t(kind), key])
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
	if style == Style.SELL:
		_draw_sell(rect)
		return
	if is_locked():
		_draw_closed(rect)
		return
	var t := lit_t
	draw_style_box(UiStyle.cell_style_t(rim(), t, RADIUS), rect)
	if t > 0.0 and _washed:
		var wash := StyleBoxFlat.new()
		wash.bg_color = Color(DROP_WASH, DROP_WASH.a * t)
		wash.set_corner_radius_all(RADIUS)
		draw_style_box(wash, rect)
	# The tags sit inside the rim, which is thicker while lit.
	var inside := rect.grow(-2.0 if t >= 0.5 else -1.0)
	var shown := _shown()
	var icon := rect.grow(-ICON_INSET)
	if shown:
		ItemIcon.draw_item(self, shown, icon.grow(icon.size.x * 0.5 * LAND_SCALE * land_t))
		var count := screen.inventory.count_at(index)
		ItemIcon.draw_tag(self, str(count) if count > 1 else "", inside, CORNER_TOP_LEFT, Color.WHITE, RADIUS - 1)
	else:
		ItemIcon.draw_item(self, placeholder(), icon, Color(1, 1, 1, PLACEHOLDER_ALPHA))
	ItemIcon.draw_tag(self, key_text(), inside, CORNER_BOTTOM_RIGHT, KEY_COLOR, RADIUS - 1)


## A cell that takes nothing: a fainter well. A locked equip slot shows a
## dim chain; a locked backpack cell shows nothing more (the line under the
## grid says how to open them), and its rim is fainter still.
func _draw_closed(rect: Rect2) -> void:
	var pack := style == Style.BACKPACK
	var box := UiStyle.cell_style(LOCKED_PACK_RIM if pack else LOCKED_RIM, false, RADIUS)
	box.bg_color = LOCKED_FILL
	draw_style_box(box, rect)
	if not pack:
		draw_texture_rect(CHAIN, rect.grow(-CHAIN_INSET), false, Color(1, 1, 1, CHAIN_ALPHA))


## The sell slot: a dark well with a red rim and a coin over "Sell"; an item
## held over it fills it red (eased) and shows the gold it would bring ("NO"
## for one that can't be sold).
func _draw_sell(rect: Rect2) -> void:
	var t := lit_t
	var box := UiStyle.cell_style(UiStyle.BAD_COLOR, false, RADIUS)
	box.bg_color = UiStyle.CELL_COLOR.lerp(SELL_OVER, t)
	box.set_border_width_all(2 if t >= 0.5 else 1)
	draw_style_box(box, rect)
	var font := ThemeDB.fallback_font
	var over := screen.target_index() == BackpackScreen.SELL
	var text := Lang.t("Sell")
	if over:
		text = Lang.t("NO") if screen.sell_refused() else "+%d" % screen.sell_preview()
	var middle := rect.get_center()
	draw_texture_rect(COIN, Rect2(middle.x - SELL_COIN * 0.5, middle.y - SELL_COIN - 1.0, SELL_COIN, SELL_COIN), false)
	var baseline := middle.y + SELL_FONT + 3.0
	draw_string_outline(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, SELL_FONT, 4, Color.BLACK)
	draw_string(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, SELL_FONT, UiStyle.GOLD_COLOR if over else SELL_TEXT)
