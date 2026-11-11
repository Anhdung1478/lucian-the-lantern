class_name RecipeTable
extends Plate
## The crafting recipes shown beside the backpack, shop or not (they are
## crafted at the merchant's Craft tab, for a fee), on a plate headed
## RECIPES: one scrollable line per legendary, "[fragment] + [fragment] =
## [legendary] name" (RecipeRow). The recipes whose two fragments Lucian
## holds right now are lit gold and come first, so what can be crafted shows
## without scrolling. Every icon has its card.

const WIDTH := 320.0
const MAX_HEIGHT := 820.0
const PAD := 14.0
const ROW_GAP := 2
const HEADING_FONT := 18
const NOTE := "Lit gold: you hold both fragments."
const NOTE_FONT := 13

var inventory: Inventory

## One per legendary, in the catalog's order.
var _rows: Array[RecipeRow] = []
var _list: VBoxContainer
var _scroll: ScrollContainer


func _init() -> void:
	super(PAD, false)


## `held` is the inventory whose fragments light the recipes (none: no
## recipe is ever lit).
func setup(catalog: ItemCatalog, held: Inventory = null) -> void:
	inventory = held
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 10)
	add_child(box)
	box.add_child(BagHeading.new("RECIPES", HEADING_FONT))

	_scroll = ScrollContainer.new()
	_scroll.theme = UiStyle.theme()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(WIDTH, MAX_HEIGHT)
	box.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override(&"separation", ROW_GAP)
	_scroll.add_child(_list)
	for legendary in catalog.legendaries():
		var row := RecipeRow.new(legendary, catalog)
		_list.add_child(row)
		_rows.append(row)
	box.add_child(UiStyle.label(NOTE, NOTE_FONT, UiStyle.DIM_COLOR))
	if inventory:
		inventory.changed.connect(refresh)
	refresh()


## The lines in the order shown: the lit ones first.
func rows() -> Array[RecipeRow]:
	var shown: Array[RecipeRow] = []
	shown.assign(_list.get_children())
	return shown


## Lights each line for what the inventory holds now and brings the lit ones
## to the top, the others after them in the catalog's order. A change in
## what can be crafted scrolls back to the top, where it shows.
func refresh() -> void:
	var before := _lit()
	for row in _rows:
		row.refresh(inventory)
	var ordered := _lit() + _rows.filter(func(row: RecipeRow) -> bool: return not row.lit)
	for i in ordered.size():
		_list.move_child(ordered[i], i)
	if _lit() != before:
		_scroll.scroll_vertical = 0


## How many of the fragment `id` the inventory holds in its open cells, the
## equip slots included.
static func held(from: Inventory, id: StringName) -> int:
	var count := 0
	for cell in Inventory.SIZE:
		var item := from.item_at(cell)
		if item != null and item.id == id and not from.is_locked(cell):
			count += from.count_at(cell)
	return count


## Whether the inventory holds fragment number `part` (0 or 1) of
## `legendary`'s recipe. A recipe that takes one fragment twice needs two of
## it for the second.
static func holds_part(legendary: ItemData, part: int, from: Inventory) -> bool:
	var id := legendary.components[part]
	var needed := 2 if part == 1 and legendary.components[0] == id else 1
	return held(from, id) >= needed


## Whether Lucian holds both fragments of `legendary` right now, so the
## merchant's Craft tab would make it: the recipe is lit gold.
static func can_craft(legendary: ItemData, from: Inventory) -> bool:
	return from != null and legendary.components.size() == 2 \
		and holds_part(legendary, 0, from) and holds_part(legendary, 1, from)


func _lit() -> Array[RecipeRow]:
	return _rows.filter(func(row: RecipeRow) -> bool: return row.lit)
