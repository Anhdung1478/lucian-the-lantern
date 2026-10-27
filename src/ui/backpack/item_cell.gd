class_name ItemCell
extends Control
## One cell of the backpack screen: a tan backpack cell, a dark equip slot
## (with its key number, or a chain when locked) or the sell slot. Draws the
## item from the inventory and passes mouse input to the screen.

enum Style { BACKPACK, EQUIP, SELL }

const SIZE := 64.0
const ICON_INSET := 5.0
const FILLS := {Style.BACKPACK: Color("d9c59b"), Style.EQUIP: Color("2a221a"), Style.SELL: Color("1e1a16")}
const BORDERS := {Style.BACKPACK: Color("8c6e45"), Style.EQUIP: Color("8c6e45"), Style.SELL: Color("5a4a38")}
const TARGET_BORDER := Color("ffcf5a")
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
	var shown := item()
	return TooltipCard.item(shown, screen.inventory.catalog) if shown and not screen.is_dragging() else null


func _gui_input(event: InputEvent) -> void:
	screen.on_cell_input(self, event)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var fill := StyleBoxFlat.new()
	fill.bg_color = FILLS[style]
	fill.border_color = TARGET_BORDER if screen.target_index() == index and index >= 0 else BORDERS[style]
	fill.set_border_width_all(3 if fill.border_color == TARGET_BORDER else 2)
	fill.set_corner_radius_all(6)
	draw_style_box(fill, rect)
	if is_locked():
		draw_texture_rect(CHAIN, rect.grow(-8.0), false, Color(1, 1, 1, 0.85))
		return
	if index != screen.dragged_index():
		ItemIcon.draw_item(self, item(), rect.grow(-ICON_INSET))
	if style == Style.EQUIP:
		var font := ThemeDB.fallback_font
		draw_string_outline(font, Vector2(5, 15), str(index - Inventory.EQUIP_START + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color.BLACK)
		draw_string(font, Vector2(5, 15), str(index - Inventory.EQUIP_START + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, KEY_COLOR)
