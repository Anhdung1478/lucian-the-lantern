class_name HudItemSlot
extends Control
## One equip slot on the HUD: the item's icon, a potion stack's count, an
## active's cooldown and the slot's key. Locked slots are hidden. Hovering
## shows the item's card above it.

const SIZE := 40.0
const FILL := Color(0.09, 0.105, 0.14)
const FRAME_COLOR := Color(0.36, 0.4, 0.48)

var inventory: Inventory
var index := 0
## For item cooldowns; optional.
var lucian: Lucian


func _init(target_inventory: Inventory, slot: int) -> void:
	inventory = target_inventory
	index = Inventory.EQUIP_START + slot
	custom_minimum_size = Vector2(SIZE, SIZE)
	inventory.changed.connect(_refresh)
	_refresh()


## The active's range, shown around Lucian while hovered.
func hover_range() -> CastRange:
	return lucian.equip_range(index - Inventory.EQUIP_START) if lucian else null


func tooltip_content() -> Control:
	var item := inventory.item_at(index)
	return TooltipCard.item(item, inventory.catalog) if item else null


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
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, FILL)
	ItemIcon.draw_item(self, inventory.item_at(index), rect.grow(-3.0))
	ItemIcon.draw_count(self, inventory.count_at(index), rect, true)
	_draw_cooldown(rect)
	draw_rect(rect, FRAME_COLOR, false, 2.0)
	var key := GameSettings.instance().key_label(StringName("item_%d" % (index - Inventory.EQUIP_START + 1)))
	var font := ThemeDB.fallback_font
	var at := Vector2(0, size.y - 3.0)
	draw_string_outline(font, at, key, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 3.0, 12, 4, Color.BLACK)
	draw_string(font, at, key, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 3.0, 12, Color.WHITE)
