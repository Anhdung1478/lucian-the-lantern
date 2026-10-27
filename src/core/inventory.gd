class_name Inventory
extends RefCounted
## Lucian's items in a stage: 49 backpack cells and 6 equip slots in one index
## space (0-48 backpack, 49-54 equip). Only unlocked equip slots give stats.

signal changed

## What dropping a dragged item on a cell does.
enum Drop { RETURN, MOVE, SWAP, CRAFT }

const BACKPACK_SIZE := 49
const EQUIP_SIZE := 6
const EQUIP_START := BACKPACK_SIZE
const SIZE := BACKPACK_SIZE + EQUIP_SIZE

var catalog: ItemCatalog
## Null for an empty cell.
var items: Array[ItemData] = []
## Equip slots 1..n are usable. Lowering it moves items out of the slots that
## become locked and back into the backpack.
var unlocked_equip := EQUIP_SIZE:
	set(value):
		unlocked_equip = clampi(value, 1, EQUIP_SIZE)
		for i in range(EQUIP_START + unlocked_equip, SIZE):
			var empty := _first_empty_backpack_cell()
			if items[i] and empty >= 0:
				items[empty] = items[i]
				items[i] = null
		changed.emit()


func _init(item_catalog: ItemCatalog = null) -> void:
	catalog = item_catalog
	items.resize(SIZE)


static func is_equip(index: int) -> bool:
	return index >= EQUIP_START and index < SIZE


func is_locked(index: int) -> bool:
	return index >= EQUIP_START + unlocked_equip


func item_at(index: int) -> ItemData:
	return items[index]


## Puts `item` in the first empty backpack cell. False when the backpack is full.
func add(item: ItemData) -> bool:
	var empty := _first_empty_backpack_cell()
	if empty < 0:
		return false
	items[empty] = item
	changed.emit()
	return true


func remove(index: int) -> ItemData:
	var item := items[index]
	items[index] = null
	changed.emit()
	return item


func clear() -> void:
	items.fill(null)
	changed.emit()


## The legendary that the items in `from` and `to` craft into, or null.
func craft_result(from: int, to: int) -> ItemData:
	if catalog == null:
		return null
	return catalog.combine(items[from], items[to])


## What dropping the item from `from` onto `to` does. `to` is -1 outside any
## cell. `craft_ready` is true once the craft pop-up's line has gone around.
func drop_outcome(from: int, to: int, craft_ready: bool) -> Drop:
	if to < 0 or to >= SIZE or to == from or items[from] == null or is_locked(to):
		return Drop.RETURN
	if items[to] == null:
		return Drop.MOVE
	if craft_ready and craft_result(from, to) != null:
		return Drop.CRAFT
	return Drop.SWAP


## Carries out the drop and returns what happened. A crafted legendary lands
## in `to` and `from` is emptied.
func apply_drop(from: int, to: int, craft_ready: bool) -> Drop:
	var outcome := drop_outcome(from, to, craft_ready)
	match outcome:
		Drop.RETURN:
			return outcome
		Drop.CRAFT:
			items[to] = craft_result(from, to)
			items[from] = null
		_:
			var moved := items[from]
			items[from] = items[to]
			items[to] = moved
	changed.emit()
	return outcome


## Stats from the unlocked equip slots, summed by ItemStats key.
func equipped_bonus() -> Dictionary:
	var bonus := {}
	for i in range(EQUIP_START, EQUIP_START + unlocked_equip):
		if items[i] == null:
			continue
		for key: StringName in items[i].stats:
			bonus[key] = bonus.get(key, 0.0) + items[i].stats[key]
	return bonus


func _first_empty_backpack_cell() -> int:
	for i in BACKPACK_SIZE:
		if items[i] == null:
			return i
	return -1
