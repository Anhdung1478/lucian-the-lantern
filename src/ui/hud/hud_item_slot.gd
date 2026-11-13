class_name HudItemSlot
extends Control
## One inventory cell on the HUD, a dark well with a rim by what it holds
## (UiStyle.item_rim): an equip slot or a potion cell (the item's icon, a
## potion stack's count in a tab top left, an active's cooldown and the
## cell's key in the tab bottom right; an empty potion cell shows its potion
## faded) or the boots (no key, nothing drawn while there are none). Locked
## slots are hidden. The rim eases to gold while the mouse is on the cell;
## hovering shows the item's card above the bar.

## 44 px on screen.
const SIZE := 53.0
const PLACEHOLDER := Color(1, 1, 1, 0.3)
const SWEEP_COLOR := Color(0, 0, 0, 0.65)
## The room between the cell's edge and the item's icon.
const ICON_INSET := 3.0
const KEY_FONT := UiStyle.FONT_TAG
const COOLDOWN_FONT := 18

var inventory: Inventory
var index := 0
## For item cooldowns; optional.
var lucian: Lucian
## How far the rim has eased to gold (UiMotion.lit).
var lit_t := 0.0

## The mouse is on the cell: its rim eases to gold.
var _hovered := false:
	set(value):
		_hovered = value
		UiMotion.lit(self, value)


## `cell` is the inventory index: an equip slot, a potion cell or the boots.
func _init(target_inventory: Inventory, cell: int) -> void:
	inventory = target_inventory
	index = cell
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_entered.connect(func() -> void: _hovered = true)
	mouse_exited.connect(func() -> void: _hovered = false)
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


## The card hangs above the bar, over this cell.
func tooltip_anchor() -> Rect2:
	return HudCell.tip_anchor(self)


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
	var inner := rect.grow(-HudCell.INSET)
	draw_set_transform(inner.position)
	draw_colored_polygon(SkillSlot.sweep_polygon(cooldown.fraction_remaining(), inner.size.x), SWEEP_COLOR)
	draw_set_transform(Vector2.ZERO)
	var at := Vector2(0, rect.get_center().y + 7.0)
	HudCell.draw_text(self, at, HudCell.seconds_text(cooldown.remaining), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, COOLDOWN_FONT)


func _refresh() -> void:
	visible = not inventory.is_locked(index)
	queue_redraw()


func _draw() -> void:
	var item := inventory.item_at(index)
	if index == Inventory.BOOTS_CELL and item == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	HudCell.draw_box(self, rect, UiStyle.item_rim(item), lit_t)
	if item:
		ItemIcon.draw_item(self, item, rect.grow(-ICON_INSET))
	else:
		ItemIcon.draw_item(self, placeholder(), rect.grow(-ICON_INSET), PLACEHOLDER)
	var count := inventory.count_at(index)
	if count > 1:
		HudCell.draw_tab(self, rect, str(count), CORNER_TOP_LEFT, Color.WHITE)
	_draw_cooldown(rect)
	var action := Inventory.key_action(index)
	if action != &"":
		HudCell.draw_key(self, rect, GameSettings.instance().short_key_label(action), KEY_FONT)
