class_name CraftSlot
extends Control
## One slot of the merchant's Craft tab: one of the two inputs (a fragment or
## the boots) or the item they would make. An input holds an inventory index,
## not the item, so nothing has to be given back when the shop closes; items
## are dragged in from the backpack and a right-click empties it. Mouse input
## outside that goes to nobody: the backpack screen finds the input under a
## drag itself.

enum Kind { INPUT, RESULT }

const SIZE := 64.0
const ICON_INSET := 5.0
const FILL := Color(0.09, 0.105, 0.14)
const BORDER := Color(0.36, 0.4, 0.48)
const TARGET_BORDER := Color("ffcf5a")
const RESULT_BORDER := Color("c9a45c")
const PLACEHOLDER := Color(1, 1, 1, 0.3)

var screen: BackpackScreen
var kind := Kind.INPUT
## The drop target the backpack screen gives this input
## (BackpackScreen.CRAFT_FIRST or CRAFT_SECOND); -1 for the result.
var drop_target := -1
## The inventory cell an input shows, or -1 while it is empty.
var index := -1


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


## Shows inventory cell `cell` when it holds what this input takes.
func load_cell(cell: int) -> bool:
	if cell < 0 or not takes(screen.inventory.item_at(cell)):
		return false
	index = cell
	queue_redraw()
	return true


func clear() -> void:
	index = -1
	queue_redraw()


## Empties the input once its cell no longer holds what it takes (the item
## was moved, sold or used up).
func recheck() -> void:
	if index >= 0 and not takes(item()):
		clear()


func tooltip_content() -> Control:
	if screen.is_dragging():
		return null
	var shown := item()
	if shown:
		return TooltipCard.item(shown, screen.inventory.catalog)
	if kind == Kind.INPUT:
		return TooltipCard.note("Drag a fragment or your boots here from the backpack screen")
	return null


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.pressed and button.button_index == MOUSE_BUTTON_RIGHT and kind != Kind.RESULT:
		clear()
		accept_event()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var over := kind != Kind.RESULT and screen.target_index() == target()
	var box := StyleBoxFlat.new()
	box.bg_color = FILL
	box.border_color = TARGET_BORDER if over else (RESULT_BORDER if kind == Kind.RESULT else BORDER)
	box.set_border_width_all(3 if over else 2)
	box.set_corner_radius_all(6)
	draw_style_box(box, rect)
	var shown := item()
	if shown and not (kind != Kind.RESULT and index == screen.dragged_index()):
		ItemIcon.draw_item(self, shown, rect.grow(-ICON_INSET))
		return
	if kind == Kind.INPUT:
		draw_string(ThemeDB.fallback_font, Vector2(0, rect.size.y * 0.5 + 4.0), "ITEM", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, PLACEHOLDER)
