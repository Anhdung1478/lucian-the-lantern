class_name HudItemSlot
extends Control
## One inventory cell on the HUD: an equip slot or a potion cell (the item's
## icon, a potion stack's count, an active's cooldown and the cell's key; an
## empty potion cell shows its potion faded) or the boots (no key, nothing
## drawn while there are none). Locked slots are hidden. Hovering shows the
## item's card above it.

const SIZE := 40.0
const FILL := Color(0.09, 0.105, 0.14)
const FRAME_COLOR := Color(0.36, 0.4, 0.48)
const PLACEHOLDER := Color(1, 1, 1, 0.3)

var inventory: Inventory
var index := 0
## For item cooldowns; optional.
var lucian: Lucian


## `cell` is the inventory index: an equip slot, a potion cell or the boots.
func _init(target_inventory: Inventory, cell: int) -> void:
	inventory = target_inventory
	index = cell
	custom_minimum_size = Vector2(SIZE, SIZE)
	inventory.changed.connect(_refresh)
	_refresh()


## The active's range, shown around Lucian while hovered (equip slots only).
func hover_range() -> CastRange:
	return lucian.equip_range(index - Inventory.EQUIP_START) if lucian and Inventory.is_equip(index) else null


func tooltip_content() -> Control:
	var item := inventory.item_at(index)
	return TooltipCard.item(item, inventory.catalog) if item else null


## What an empty potion cell shows faded; null for the other cells.
func placeholder() -> ItemData:
	if inventory.catalog == null:
		return null
	for potion in inventory.catalog.potions():
		if Inventory.potion_cell(potion) == index:
			return potion
	return null


func tooltip_place() -> HoverTip.Place:
	return HoverTip.Place.ABOVE


func _process(_delta: float) -> void:
	var item := inventory.item_at(index)
	if item and lucian and lucian.item_cooldowns.has(item.id):
		queue_redraw()


func _draw_cooldown(rect: Rect2) -> void:
	var item := inventory.item_at(index)
	if item == null or lucian == null or not lucian.item_cooldowns.has(item.id):
		return
	var cooldown: Cooldown = lucian.item_cooldowns[item.id]
	if cooldown.is_ready():
		return
	draw_colored_polygon(SkillSlot.sweep_polygon(cooldown.fraction_remaining(), SIZE), Color(0, 0, 0, 0.65))
	var text := "%.1f" % cooldown.remaining if cooldown.remaining < 1.0 else str(ceili(cooldown.remaining))
	var font := ThemeDB.fallback_font
	var at := Vector2(0, rect.get_center().y + 6.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 16, 4, Color.BLACK)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 16, Color.WHITE)


func _refresh() -> void:
	visible = not inventory.is_locked(index)
	queue_redraw()


func _draw() -> void:
	var item := inventory.item_at(index)
	if index == Inventory.BOOTS_CELL and item == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, FILL)
	if item:
		ItemIcon.draw_item(self, item, rect.grow(-3.0))
	else:
		ItemIcon.draw_item(self, placeholder(), rect.grow(-3.0), PLACEHOLDER)
	ItemIcon.draw_count(self, inventory.count_at(index), rect, true)
	_draw_cooldown(rect)
	draw_rect(rect, FRAME_COLOR, false, 2.0)
	var action := Inventory.key_action(index)
	if action == &"":
		return
	var key := GameSettings.instance().key_label(action)
	var font := ThemeDB.fallback_font
	var at := Vector2(0, size.y - 3.0)
	draw_string_outline(font, at, key, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 3.0, 12, 4, Color.BLACK)
	draw_string(font, at, key, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 3.0, 12, Color.WHITE)
