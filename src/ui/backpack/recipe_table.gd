class_name RecipeTable
extends Plate
## The crafting recipes shown beside the backpack, shop or not (they are
## crafted at the merchant's Craft tab, for a fee), on a plate headed
## RECIPES: one scrollable line per legendary, "[fragment] + [fragment] =
## [legendary] name", then under BOOTS one per upgraded pair of boots,
## "[boots] + [fragment] = [boots] name" (RecipeRow), each second tier with
## its third tier under it. The lines Lucian has both parts of right now are
## lit gold and come first, so what can be crafted shows without scrolling.
## Every icon has its card.

const WIDTH := 320.0
const MAX_HEIGHT := 820.0
const PAD := 14.0
const ROW_GAP := 2
const HEADING_FONT := 18
const BOOTS_HEADING := "BOOTS"
const BOOTS_FONT := 15
const NOTE := "Lit gold: you hold both parts."
const NOTE_FONT := 13

var inventory: Inventory

## One per legendary in the catalog's order, then one per upgraded pair of
## boots.
var _rows: Array[RecipeRow] = []
## The heading over the boots' lines; null when the catalog has none.
var _boots_heading: BagHeading
var _list: VBoxContainer
var _scroll: ScrollContainer


func _init() -> void:
	super(PAD, false)


## `held` is the inventory whose items light the recipes (none: no recipe is
## ever lit).
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
	var makes := catalog.legendaries()
	makes.append_array(upgraded_boots(catalog))
	for made in makes:
		if made.is_boots() and _boots_heading == null:
			_boots_heading = BagHeading.new(BOOTS_HEADING, BOOTS_FONT)
			_list.add_child(_boots_heading)
		var row := RecipeRow.new(made, catalog)
		_list.add_child(row)
		_rows.append(row)
	box.add_child(UiStyle.label(NOTE, NOTE_FONT, UiStyle.DIM_COLOR))
	if inventory:
		inventory.changed.connect(refresh)
	refresh()


## The lines in the order shown: the lit ones first.
func rows() -> Array[RecipeRow]:
	var shown: Array[RecipeRow] = []
	shown.assign(_list.get_children().filter(func(node: Node) -> bool: return node is RecipeRow))
	return shown


## Lights each line for what the inventory has now and brings the lit ones
## to the top; the others follow in their order, the boots' under their
## heading. A change in what can be crafted scrolls back to the top, where
## it shows.
func refresh() -> void:
	var before := _lit()
	for row in _rows:
		row.refresh(inventory)
	var ordered: Array[Control] = []
	ordered.assign(_lit())
	for row in _rows:
		if row.lit:
			continue
		if row.made.is_boots() and not ordered.has(_boots_heading):
			ordered.append(_boots_heading)
		ordered.append(row)
	if _boots_heading and not ordered.has(_boots_heading):
		ordered.append(_boots_heading)
	for i in ordered.size():
		_list.move_child(ordered[i], i)
	if _lit() != before:
		_scroll.scroll_vertical = 0


## The boots the Craft tab makes, in the order of their lines: each second
## tier in the catalog's order, with its third tier after it.
static func upgraded_boots(catalog: ItemCatalog) -> Array[ItemData]:
	var all := catalog.boots()
	var lines: Array[ItemData] = []
	for second in all:
		if second.boots_tier != 2:
			continue
		lines.append(second)
		for third in all:
			if third.upgrade_from == second.id:
				lines.append(third)
	return lines


## What `made` is crafted from, as two parts, each the items that part can
## be: a legendary's two fragments; for boots, the boots they are upgraded
## from (every starting pair for a second tier) and their fragment.
static func parts(made: ItemData, catalog: ItemCatalog) -> Array:
	var from: Array[ItemData] = []
	var with: Array[ItemData] = []
	if made.is_boots():
		if made.boots_tier == 2:
			for boots in catalog.boots():
				if boots.boots_tier == 1:
					from.append(boots)
		else:
			from.append(catalog.find(made.upgrade_from))
		with.append(catalog.find(made.upgrade_fragment))
	else:
		from.append(catalog.find(made.components[0]))
		with.append(catalog.find(made.components[1]))
	return [from, with]


## How many of the fragment `id` the inventory holds in its open cells, the
## equip slots included.
static func held(from: Inventory, id: StringName) -> int:
	var count := 0
	for cell in Inventory.SIZE:
		var item := from.item_at(cell)
		if item != null and item.id == id and not from.is_locked(cell):
			count += from.count_at(cell)
	return count


## Whether the inventory has part number `part` (0 or 1) of `made`'s recipe.
## A legendary that takes one fragment twice needs two of it for the second.
## Boots' first part is the pair Lucian wears: any starting pair for a
## second tier, the second tier itself for its third.
static func holds_part(made: ItemData, part: int, from: Inventory) -> bool:
	if made.is_boots():
		if part == 1:
			return held(from, made.upgrade_fragment) >= 1
		var worn := from.boots()
		if worn == null:
			return false
		return worn.boots_tier == 1 if made.boots_tier == 2 else worn.id == made.upgrade_from
	var id := made.components[part]
	var needed := 2 if part == 1 and made.components[0] == id else 1
	return held(from, id) >= needed


## Whether Lucian has both parts of `made` right now, so the merchant's
## Craft tab would make it: the recipe is lit gold.
static func can_craft(made: ItemData, from: Inventory) -> bool:
	if from == null or not (made.is_boots() or made.components.size() == 2):
		return false
	return holds_part(made, 0, from) and holds_part(made, 1, from)


func _lit() -> Array[RecipeRow]:
	return _rows.filter(func(row: RecipeRow) -> bool: return row.lit)
