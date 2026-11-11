class_name Inventory
extends RefCounted
## Lucian's items in a stage: 54 backpack cells (a 9x6 grid), 6 equip slots,
## the two potion cells and the boots cell in one index space (0-53 backpack,
## 54-59 equip, 60 Health potion, 61 Mana potion, 62 boots). Only the unlocked
## backpack cells take items and only the unlocked equip slots give stats; the
## potion cells and the boots cell are never locked.
## Potions stack up to their max_stack in one cell; everything else is 1.
## Potions go only in the backpack and their potion cell, never in an equip
## slot. Boots live only in the boots cell: they never move by drag.
## Only one penetration item (ItemData.is_penetration) can be in the equip
## slots at a time: a put or drop that would equip a second one is refused
## (pen_blocker). Picked-up items, and bought ones not dropped on an equip
## slot, go only into the backpack (and a potion's own cell), never into an
## empty equip slot.

signal changed

## What dropping a dragged item on a cell does.
enum Drop { RETURN, MOVE, SWAP, STACK }

const BACKPACK_SIZE := 54
const EQUIP_SIZE := 6
const EQUIP_START := BACKPACK_SIZE
const EQUIP_END := EQUIP_START + EQUIP_SIZE
## Keys 7 and 8 drink from these (key_action).
const HP_POTION_CELL := EQUIP_END
const MP_POTION_CELL := EQUIP_END + 1
## The boots bought in the Evolution Tree; they count as equipped.
const BOOTS_CELL := EQUIP_END + 2
const SIZE := EQUIP_END + 3

var catalog: ItemCatalog
## Null for an empty cell.
var items: Array[ItemData] = []
## How many of the item each cell holds; 0 for an empty cell.
var counts: Array[int] = []
## Backpack cells 0..n-1 are usable. Lowering it moves items out of the cells
## that become locked into the first empty unlocked cell; when there is none
## they stay where they are.
var unlocked_backpack := BACKPACK_SIZE:
	set(value):
		unlocked_backpack = clampi(value, 1, BACKPACK_SIZE)
		for i in range(unlocked_backpack, BACKPACK_SIZE):
			var empty := _first_empty_backpack_cell()
			if items[i] and empty >= 0:
				_set_cell(empty, items[i], counts[i])
				_set_cell(i, null, 0)
		changed.emit()
## Equip slots 1..n are usable. Lowering it moves items out of the slots that
## become locked and back into the backpack.
var unlocked_equip := EQUIP_SIZE:
	set(value):
		unlocked_equip = clampi(value, 1, EQUIP_SIZE)
		for i in range(EQUIP_START + unlocked_equip, EQUIP_END):
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
	return index >= EQUIP_START and index < EQUIP_END


## The potion cells and the boots cell are never locked.
func is_locked(index: int) -> bool:
	if index < EQUIP_START:
		return index >= unlocked_backpack
	if index < EQUIP_END:
		return index >= EQUIP_START + unlocked_equip
	return false


## The input action whose key uses cell `index`: &"item_1".."item_6" for the
## equip slots, &"potion_hp" and &"potion_mp" for the potion cells, &"" for
## the rest.
static func key_action(index: int) -> StringName:
	if is_equip(index):
		return StringName("item_%d" % (index - EQUIP_START + 1))
	match index:
		HP_POTION_CELL:
			return &"potion_hp"
		MP_POTION_CELL:
			return &"potion_mp"
	return &""


## Whether cell `index` may hold `item` (null fits anywhere): the backpack
## takes anything but boots, the equip slots anything but potions and boots,
## each potion cell only its kind of potion, and the boots cell nothing (boots
## are put there with set_boots).
static func accepts(index: int, item: ItemData) -> bool:
	if item == null:
		return true
	if index < EQUIP_START:
		return not item.is_boots()
	if index < EQUIP_END:
		return not item.is_potion() and not item.is_boots()
	match index:
		HP_POTION_CELL:
			return item.is_potion() and item.restore_hp > 0.0
		MP_POTION_CELL:
			return item.is_potion() and item.restore_mana > 0.0
	return false


## The potion cell `item` goes in (Health for a potion restoring both), or -1
## when it is not a potion.
static func potion_cell(item: ItemData) -> int:
	if item == null or not item.is_potion():
		return -1
	if item.restore_hp > 0.0:
		return HP_POTION_CELL
	return MP_POTION_CELL if item.restore_mana > 0.0 else -1


func item_at(index: int) -> ItemData:
	return items[index]


func count_at(index: int) -> int:
	return counts[index]


## How many more of `item` fit: room in a potion's own potion cell, then in
## the backpack's stacks and empty cells (unlocked cells only). Empty equip
## slots don't count: a full backpack takes nothing. Boots never fit.
func space_for(item: ItemData) -> int:
	if item.is_boots():
		return 0
	var room := 0
	var cell := potion_cell(item)
	if cell >= 0:
		room += _room_in(cell, item)
	for i in unlocked_backpack:
		room += _room_in(i, item)
	return room


## Puts `amount` of `item` away: a potion fills its potion cell first; then
## the backpack's stacks with room, then its first empty cells. Never an
## equip slot. All or nothing: false when it doesn't fit.
func add(item: ItemData, amount := 1) -> bool:
	if space_for(item) < amount:
		return false
	var cell := potion_cell(item)
	if cell >= 0:
		amount = _fill(cell, item, amount)
	for pass_empty in [false, true]:
		for i in unlocked_backpack:
			if amount == 0:
				break
			if (items[i] == null) == pass_empty:
				amount = _fill(i, item, amount)
	changed.emit()
	return true


## True when one `item` fits in cell `index`: an empty unlocked cell that
## accepts it, or a stack of the same item with room. An equip slot also
## needs the one-penetration rule to allow it (pen_blocker).
func can_put(index: int, item: ItemData) -> bool:
	if index < 0 or index >= SIZE or is_locked(index) or not accepts(index, item):
		return false
	if items[index] != null and (items[index] != item or counts[index] >= item.max_stack):
		return false
	return pen_blocker(index, item) == null


## The equipped penetration item that keeps `item` out of equip slot `index`:
## only one penetration item can be equipped (ItemData.is_penetration). Null
## when `index` isn't an equip slot, `item` isn't a penetration item, or the
## only one equipped is in `index` itself (it would be swapped out). Only the
## unlocked slots count, as only they give stats.
func pen_blocker(index: int, item: ItemData) -> ItemData:
	if not is_equip(index) or item == null or not item.is_penetration():
		return null
	for i in range(EQUIP_START, EQUIP_START + unlocked_equip):
		if i != index and items[i] and items[i].is_penetration():
			return items[i]
	return null


## Puts one `item` into cell `index` when it fits there (see can_put).
func put(index: int, item: ItemData) -> bool:
	if not can_put(index, item):
		return false
	_set_cell(index, item, counts[index] + 1)
	changed.emit()
	return true


## Whether any backpack, equip, potion or boots cell holds the item `id`.
func has_item(id: StringName) -> bool:
	return items.any(func(item: ItemData) -> bool: return item != null and item.id == id)


## Puts `count` of `item` back into cell `index` when it is empty, unlocked and
## accepts the item (equip cells too), and `count` fits one stack. Changes
## nothing and returns false otherwise. Emits `changed` once.
func put_stack(index: int, item: ItemData, count: int) -> bool:
	if count < 1 or count > item.max_stack or not can_put(index, item) or items[index] != null:
		return false
	_set_cell(index, item, count)
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


## Empties every cell but the boots cell: the boots stay for the stage.
func clear() -> void:
	var kept := boots()
	items.fill(null)
	counts.fill(0)
	_set_cell(BOOTS_CELL, kept, 1)
	changed.emit()


## The boots in the boots cell, or null.
func boots() -> ItemData:
	return items[BOOTS_CELL]


## Puts `item` in the boots cell, replacing what was there (null empties it).
## Only the stage setup, the merchant's Craft tab and the debug table call it.
func set_boots(item: ItemData) -> void:
	_set_cell(BOOTS_CELL, item, 1)
	changed.emit()


## A craft at the merchant: cell `keep` now holds `made` and cell `use_up`
## is emptied (the boots cell can be `keep`, for upgraded boots).
func craft_into(keep: int, use_up: int, made: ItemData) -> void:
	_set_cell(keep, made, 1)
	_set_cell(use_up, null, 0)
	changed.emit()


## What dropping the item from `from` onto `to` does. `to` is -1 outside any
## cell. Boots never move, and a cell that doesn't accept the item moving in
## (or, on a swap, the item coming back) sends it back, as does a drop that
## would equip a second penetration item (drop_pen_blocker). Crafting happens
## only at the merchant (Shop.craft), never by dropping.
func drop_outcome(from: int, to: int) -> Drop:
	if drop_pen_blocker(from, to) != null:
		return Drop.RETURN
	return _drop_outcome_without_pen_rule(from, to)


## The equipped penetration item that sends back the drop of `from` onto
## `to`, which would otherwise go through: the item it brings into the equip
## row (into `to`, or on a swap into `from`) is a penetration item while
## another one stays equipped. Null when the rule allows it; a move or swap
## within the equip row always is allowed.
func drop_pen_blocker(from: int, to: int) -> ItemData:
	if _drop_outcome_without_pen_rule(from, to) == Drop.RETURN or is_equip(from) == is_equip(to):
		return null
	if is_equip(to):
		return pen_blocker(to, items[from])
	return pen_blocker(from, items[to])


func _drop_outcome_without_pen_rule(from: int, to: int) -> Drop:
	if to < 0 or to >= SIZE or to == from or items[from] == null or is_locked(to) or is_locked(from):
		return Drop.RETURN
	if from == BOOTS_CELL or to == BOOTS_CELL or not accepts(to, items[from]):
		return Drop.RETURN
	if items[to] == null:
		return Drop.MOVE
	if items[to] == items[from] and counts[to] < items[to].max_stack:
		return Drop.STACK
	if not accepts(from, items[to]):
		return Drop.RETURN
	return Drop.SWAP


## Carries out the drop and returns what happened. Stacking moves what fits;
## the rest stays.
func apply_drop(from: int, to: int) -> Drop:
	var outcome := drop_outcome(from, to)
	match outcome:
		Drop.RETURN:
			return outcome
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


## Stats from the unlocked equip slots and the boots, summed by ItemStats key.
func equipped_bonus() -> Dictionary:
	var bonus := {}
	for item in equipped():
		for key: StringName in item.stats:
			bonus[key] = bonus.get(key, 0.0) + item.stats[key]
	return bonus


## The items in the unlocked equip slots, duplicates included, then the boots.
func equipped() -> Array[ItemData]:
	var found: Array[ItemData] = []
	for i in range(EQUIP_START, EQUIP_START + unlocked_equip):
		if items[i]:
			found.append(items[i])
	if boots():
		found.append(boots())
	return found


func _set_cell(index: int, item: ItemData, count: int) -> void:
	items[index] = item
	counts[index] = count if item else 0


## How many more of `item` cell `index` takes: a full stack when empty, the
## rest of its stack, or 0 when it holds another item.
func _room_in(index: int, item: ItemData) -> int:
	if items[index] == null:
		return item.max_stack
	return item.max_stack - counts[index] if items[index] == item else 0


## Puts up to `amount` of `item` in cell `index` (empty or the same item);
## returns how many are left over.
func _fill(index: int, item: ItemData, amount: int) -> int:
	var moved := mini(amount, _room_in(index, item))
	if moved > 0:
		_set_cell(index, item, counts[index] + moved)
	return amount - moved


func _first_empty_backpack_cell() -> int:
	for i in unlocked_backpack:
		if items[i] == null:
			return i
	return -1
