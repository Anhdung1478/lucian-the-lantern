class_name UpgradeSlot
extends Control
## One slot of the merchant's Boots tab: the boots to upgrade, the fragment
## to upgrade them with, or the boots they would become. An input holds an
## inventory index, not the item, so nothing has to be given back when the
## shop closes; items are dragged in from the backpack and a right-click
## empties it. Mouse input outside that goes to nobody: the backpack screen
## finds the input under a drag itself.

enum Kind { BOOTS, FRAGMENT, RESULT }

const SIZE := 64.0
const ICON_INSET := 5.0
const FILL := Color(0.09, 0.105, 0.14)
const BORDER := Color(0.36, 0.4, 0.48)
const TARGET_BORDER := Color("ffcf5a")
const RESULT_BORDER := Color("c9a45c")
const PLACEHOLDER := Color(1, 1, 1, 0.3)

var screen: BackpackScreen
var kind := Kind.BOOTS
## The inventory cell an input shows, or -1 while it is empty.
var index := -1


func _init(owner_screen: BackpackScreen, slot_kind: Kind) -> void:
	screen = owner_screen
	kind = slot_kind
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = MOUSE_FILTER_STOP


## The drop target the backpack screen gives this input
## (BackpackScreen.UPGRADE_BOOTS or UPGRADE_FRAGMENT); -1 for the result.
func target() -> int:
	match kind:
		Kind.BOOTS:
			return BackpackScreen.UPGRADE_BOOTS
		Kind.FRAGMENT:
			return BackpackScreen.UPGRADE_FRAGMENT
	return -1


## What it shows: the item in its inventory cell, or for the result the
## boots the two inputs would make (null when they make none).
func item() -> ItemData:
	if kind == Kind.RESULT:
		return screen.shop_panel().upgrade_preview()
	return screen.inventory.item_at(index) if index >= 0 else null


## Whether `candidate` may go in: boots in the boots input, a fragment in the
## fragment input, nothing in the result.
func takes(candidate: ItemData) -> bool:
	if candidate == null or kind == Kind.RESULT:
		return false
	return candidate.is_boots() if kind == Kind.BOOTS else candidate.is_fragment()


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
	match kind:
		Kind.BOOTS:
			return TooltipCard.note("Drag your boots here from the backpack screen")
		Kind.FRAGMENT:
			return TooltipCard.note("Drag a fragment here: it picks the boots you get")
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
	if kind == Kind.BOOTS and screen.inventory.catalog:
		ItemIcon.draw_item(self, screen.inventory.catalog.find(&"boots_of_speed"), rect.grow(-ICON_INSET), PLACEHOLDER)
	elif kind == Kind.FRAGMENT:
		draw_string(ThemeDB.fallback_font, Vector2(0, rect.size.y * 0.5 + 4.0), "FRAGMENT", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, PLACEHOLDER)
