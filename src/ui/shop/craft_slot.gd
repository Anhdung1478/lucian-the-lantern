class_name CraftSlot
extends Control
## One slot of the merchant's Craft tab: one of the two inputs (a fragment or
## the boots) or the item they would make. A dark well like the backpack's
## cells: its rim follows the item, and an input turns gold under the mouse
## and under a dragged item it takes. The result is gold once the craft can
## be paid for, shows a red cross when the two inputs make nothing and a
## faint "?" until both are in.
##
## An item dragged into an input leaves the backpack view: the input keeps
## its inventory index, and while it does the backpack screen draws that cell
## empty and keeps it out of drags, drops, sales and purchases
## (BackpackScreen.in_craft). The item stays in its cell in the Inventory, so
## a save or a crash loses nothing. It comes back when it is dragged out of
## the input, on a right-click on the input, when the merchant's tab changes
## and when the shop closes. A craft empties both inputs, so what it made
## shows in its cell. An input's mouse input goes to the backpack screen,
## which runs the drags.

enum Kind { INPUT, RESULT }

const SIZE := 64.0
const ICON_INSET := 5.0
const PLACEHOLDER := Color(1, 1, 1, 0.3)
const PLACEHOLDER_FONT := 11
## The result's "?" and the cross over two inputs that make nothing.
const MARK_FONT := 26
const CROSS_REACH := 10.0
const CROSS_WIDTH := 3.0

var screen: BackpackScreen
var kind := Kind.INPUT
## The drop target the backpack screen gives this input
## (BackpackScreen.CRAFT_FIRST or CRAFT_SECOND); -1 for the result.
var drop_target := -1
## The inventory cell whose item an input holds, or -1 while it is empty. The
## backpack redraws its cells when it changes, since that cell draws empty.
var index := -1:
	set(value):
		index = value
		queue_redraw()
		screen.redraw_cells()


func _init(owner_screen: BackpackScreen, slot_kind: Kind, target := -1) -> void:
	screen = owner_screen
	kind = slot_kind
	drop_target = target
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = MOUSE_FILTER_STOP


func target() -> int:
	return drop_target


## What it shows: the item in its inventory cell, or for the result what the
## two inputs would make (null when they make nothing).
func item() -> ItemData:
	if kind == Kind.RESULT:
		return screen.shop_panel().craft_preview()
	return screen.inventory.item_at(index) if index >= 0 else null


## Whether `candidate` may go in: an input takes a fragment or the boots, the
## result nothing.
func takes(candidate: ItemData) -> bool:
	if candidate == null or kind == Kind.RESULT:
		return false
	return candidate.is_fragment() or candidate.is_boots()


## Holds the item in inventory cell `cell` when it is what this input takes.
func load_cell(cell: int) -> bool:
	if cell < 0 or not takes(screen.inventory.item_at(cell)):
		return false
	index = cell
	return true


## Empties the input: its item comes back to the backpack.
func clear() -> void:
	index = -1


## Empties the input once its cell no longer holds what it takes (the debug
## table cleared the backpack).
func recheck() -> void:
	if index >= 0 and not takes(item()):
		clear()


## The rim's colour: the kind of the item shown; red for a result the two
## inputs don't make; the frame's gold for the input still to fill once the
## other one is.
func rim() -> Color:
	var shown := item()
	if shown:
		return UiStyle.item_rim(shown)
	var state := screen.shop_panel().craft_state()
	if kind == Kind.RESULT and state == ShopPanel.CraftState.NO_RECIPE:
		return UiStyle.BAD_COLOR
	if kind == Kind.INPUT and state == ShopPanel.CraftState.ONE:
		return UiStyle.BORDER_COLOR
	return UiStyle.CELL_BORDER


## Whether the rim is gold: for an input, the mouse rests on its item or the
## dragged item is over it and may go in; for the result, the craft is ready.
func is_lit() -> bool:
	if kind == Kind.RESULT:
		return screen.shop_panel().craft_state() == ShopPanel.CraftState.READY
	if screen.is_dragging():
		return screen.target_index() == target() and takes(screen.dragged_item())
	return item() != null and get_global_rect().has_point(Pointer.in_world(self))


func tooltip_content() -> Control:
	if screen.is_dragging():
		return null
	var shown := item()
	if shown:
		return TooltipCard.item(shown, screen.inventory.catalog)
	if kind == Kind.INPUT:
		return TooltipCard.note(Lang.t("Drag a fragment or your boots here from the backpack screen"))
	return null


func _gui_input(event: InputEvent) -> void:
	if kind == Kind.INPUT:
		screen.on_craft_input(self, event)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var lit := is_lit()
	draw_style_box(UiStyle.cell_style(rim(), lit, ItemCell.RADIUS), rect)
	if lit and screen.is_dragging():
		var wash := StyleBoxFlat.new()
		wash.bg_color = ItemCell.DROP_WASH
		wash.set_corner_radius_all(ItemCell.RADIUS)
		draw_style_box(wash, rect)
	var shown := item()
	if shown and screen.dragged_input() != self:
		ItemIcon.draw_item(self, shown, rect.grow(-ICON_INSET))
		return
	var font := ThemeDB.fallback_font
	var middle := rect.get_center()
	if kind == Kind.INPUT:
		draw_string(font, Vector2(0, middle.y + 4.0), Lang.t("ITEM"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, PLACEHOLDER_FONT, PLACEHOLDER)
	elif screen.shop_panel().craft_state() == ShopPanel.CraftState.NO_RECIPE:
		for side: float in [-1.0, 1.0]:
			draw_line(middle + Vector2(-CROSS_REACH, -CROSS_REACH * side), middle + Vector2(CROSS_REACH, CROSS_REACH * side), UiStyle.BAD_COLOR, CROSS_WIDTH, true)
	else:
		draw_string(font, Vector2(0, middle.y + 9.0), "?", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, MARK_FONT, PLACEHOLDER)
