class_name Inventory
extends RefCounted
## Lucian's items in a stage: 49 backpack cells and 6 equip slots in one index
## space (0-48 backpack, 49-54 equip). Only unlocked equip slots give stats.
## Potions stack up to their max_stack in one cell; everything else is 1.

signal changed

## What dropping a dragged item on a cell does.
enum Drop { RETURN, MOVE, SWAP, CRAFT, STACK }

const BACKPACK_SIZE := 49
const EQUIP_SIZE := 6
const EQUIP_START := BACKPACK_SIZE
const SIZE := BACKPACK_SIZE + EQUIP_SIZE

var catalog: ItemCatalog
## Null for an empty cell.
var items: Array[ItemData] = []
## How many of the item each cell holds; 0 for an empty cell.
var counts: Array[int] = []
## Equip slots 1..n are usable. Lowering it moves items out of the slots that
## become locked and back into the backpack.
var unlocked_equip := EQUIP_SIZE:
	set(value):
		unlocked_equip = clampi(value, 1, EQUIP_SIZE)
		for i in range(EQUIP_START + unlocked_equip, SIZE):
			var empty := _first_empty_backpack_cell()
			if items[i] and empty >= 0:
				_set_cell(empty, items[i], counts[i])
				_set_cell(i, null, 0)
		changed.emit()


func _init(item_catalog: ItemCatalog = null) -> void:
	catalog = item_catalog
	items.resize(SIZE)
	counts.resize(SIZE)


static func is_equip(index: int) -> bool:
	return index >= EQUIP_START and index < SIZE


func is_locked(index: int) -> bool:
	return index >= EQUIP_START + unlocked_equip


func item_at(index: int) -> ItemData:
	return items[index]


func count_at(index: int) -> int:
	return counts[index]


## How many more of `item` the backpack takes: room left in its stacks plus
## empty cells.
func space_for(item: ItemData) -> int:
	var room := 0
	for i in BACKPACK_SIZE:
		if items[i] == null:
			room += item.max_stack
		elif items[i] == item:
			room += item.max_stack - counts[i]
	return room


## Puts `amount` of `item` in the backpack: first into its stacks with room,
## then into the first empty cells. All or nothing: false when it doesn't fit.
func add(item: ItemData, amount := 1) -> bool:
	if space_for(item) < amount:
		return false
	for pass_empty in [false, true]:
		for i in BACKPACK_SIZE:
			if amount == 0:
				break
			var fits := items[i] == item if not pass_empty else items[i] == null
			if fits:
				var moved := mini(amount, item.max_stack - counts[i])
				_set_cell(i, item, counts[i] + moved)
				amount -= moved
	changed.emit()
	return true


## Puts one `item` into cell `index`: an empty unlocked cell, or a stack of the
## same item with room. False otherwise.
func put(index: int, item: ItemData) -> bool:
	if is_locked(index):
		return false
	if items[index] == null:
		_set_cell(index, item, 1)
	elif items[index] == item and counts[index] < item.max_stack:
		counts[index] += 1
	else:
		return false
	changed.emit()
	return true


## Empties the cell and returns what it held (its count is lost).
func remove(index: int) -> ItemData:
	var item := items[index]
	_set_cell(index, null, 0)
	changed.emit()
	return item


## Takes one item out of the cell, e.g. a potion being drunk.
func take_one(index: int) -> ItemData:
	var item := items[index]
	if item == null:
		return null
	if counts[index] > 1:
		counts[index] -= 1
	else:
		_set_cell(index, null, 0)
	changed.emit()
	return item


func clear() -> void:
	items.fill(null)
	counts.fill(0)
	changed.emit()


## The legendary that the items in `from` and `to` craft into, or null. One
## item never crafts with itself, even when its recipe uses two of it.
func craft_result(from: int, to: int) -> ItemData:
	if catalog == null or from == to:
		return null
	return catalog.combine(items[from], items[to])


## What dropping the item from `from` onto `to` does. `to` is -1 outside any
## cell. `craft_ready` is true once the craft pop-up's line has gone around.
func drop_outcome(from: int, to: int, craft_ready: bool) -> Drop:
	if to < 0 or to >= SIZE or to == from or items[from] == null or is_locked(to):
		return Drop.RETURN
	if items[to] == null:
		return Drop.MOVE
	if items[to] == items[from] and counts[to] < items[to].max_stack:
		return Drop.STACK
	if craft_ready and craft_result(from, to) != null:
		return Drop.CRAFT
	return Drop.SWAP


## Carries out the drop and returns what happened. A crafted legendary lands
## in `to` and `from` is emptied. Stacking moves what fits; the rest stays.
func apply_drop(from: int, to: int, craft_ready: bool) -> Drop:
	var outcome := drop_outcome(from, to, craft_ready)
	match outcome:
		Drop.RETURN:
			return outcome
		Drop.CRAFT:
			_set_cell(to, craft_result(from, to), 1)
			_set_cell(from, null, 0)
		Drop.STACK:
			var moved := mini(counts[from], items[to].max_stack - counts[to])
			counts[to] += moved
			_set_cell(from, items[from] if counts[from] > moved else null, counts[from] - moved)
		_:
			var moved := items[from]
			var moved_count := counts[from]
			_set_cell(from, items[to], counts[to])
			_set_cell(to, moved, moved_count)
	changed.emit()
	return outcome


## Stats from the unlocked equip slots, summed by ItemStats key.
func equipped_bonus() -> Dictionary:
	var bonus := {}
	for item in equipped():
		for key: StringName in item.stats:
			bonus[key] = bonus.get(key, 0.0) + item.stats[key]
	return bonus


## The items in the unlocked equip slots, duplicates included.
func equipped() -> Array[ItemData]:
	var found: Array[ItemData] = []
	for i in range(EQUIP_START, EQUIP_START + unlocked_equip):
		if items[i]:
			found.append(items[i])
	return found


func _set_cell(index: int, item: ItemData, count: int) -> void:
	items[index] = item
	counts[index] = count if item else 0


func _first_empty_backpack_cell() -> int:
	for i in BACKPACK_SIZE:
		if items[i] == null:
			return i
	return -1
