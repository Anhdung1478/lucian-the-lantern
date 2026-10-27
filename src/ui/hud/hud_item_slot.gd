class_name HudItemSlot
extends Control
## One equip slot on the HUD: the item's icon and the slot's key. Locked slots
## are hidden. Hovering shows the item's card above it.

const SIZE := 40.0
const FILL := Color(0.09, 0.105, 0.14)
const FRAME_COLOR := Color(0.36, 0.4, 0.48)

var inventory: Inventory
var index := 0


func _init(target_inventory: Inventory, slot: int) -> void:
	inventory = target_inventory
	index = Inventory.EQUIP_START + slot
	custom_minimum_size = Vector2(SIZE, SIZE)
	inventory.changed.connect(_refresh)
	_refresh()


func tooltip_content() -> Control:
	var item := inventory.item_at(index)
	return TooltipCard.item(item, inventory.catalog) if item else null


func tooltip_place() -> HoverTip.Place:
	return HoverTip.Place.ABOVE


func _refresh() -> void:
	visible = not inventory.is_locked(index)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, FILL)
	ItemIcon.draw_item(self, inventory.item_at(index), rect.grow(-3.0))
	ItemIcon.draw_count(self, inventory.count_at(index), rect, true)
	draw_rect(rect, FRAME_COLOR, false, 2.0)
	var key := str(index - Inventory.EQUIP_START + 1)
	var font := ThemeDB.fallback_font
	var at := Vector2(0, size.y - 3.0)
	draw_string_outline(font, at, key, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 3.0, 12, 4, Color.BLACK)
	draw_string(font, at, key, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 3.0, 12, Color.WHITE)
