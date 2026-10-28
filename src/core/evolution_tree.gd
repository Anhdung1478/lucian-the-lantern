class_name EvolutionTree
extends RefCounted
## Levels bought in the Evolution Tree and the rules for buying them. A node
## opens once enough of its requirements have level 1 (and, for E, once
## Act 1 is cleared). Reset costs 5 purple and gives back every blue and
## orange spent.

signal changed

const CATALOG: TreeCatalog = preload("res://data/tree/catalog.tres")
const RESET_COST := 5

## Acts cleared, kept in step by SaveGame.
var acts_cleared := 0:
	set(value):
		acts_cleared = value
		changed.emit()

## Node id -> level, for nodes above 0.
var _levels := {}


func nodes() -> Array[TreeNodeData]:
	return CATALOG.nodes


func node(id: StringName) -> TreeNodeData:
	for data in CATALOG.nodes:
		if data.id == id:
			return data
	return null


func level(id: StringName) -> int:
	return _levels.get(id, 0)


## The node's value at its current level.
func value(id: StringName) -> float:
	return node(id).value(level(id))


func is_open(id: StringName) -> bool:
	var data := node(id)
	if acts_cleared < data.requires_act:
		return false
	var met := data.requires.filter(func(required: StringName) -> bool: return level(required) > 0).size()
	return met >= (data.requires.size() if data.requires_count == 0 else data.requires_count)


func is_maxed(id: StringName) -> bool:
	return level(id) >= node(id).max_level


## Blue and orange for the next level; zero when maxed.
func cost(id: StringName) -> Vector2i:
	if is_maxed(id):
		return Vector2i.ZERO
	var data := node(id)
	return Vector2i(data.blue[level(id)], data.orange[level(id)])


func can_buy(id: StringName, essences: Essences) -> bool:
	var price := cost(id)
	return is_open(id) and not is_maxed(id) and essences.can_afford(price.x, price.y)


## Pays for the next level of `id`; false when it is closed, maxed or too dear.
func buy(id: StringName, essences: Essences) -> bool:
	if not can_buy(id, essences):
		return false
	var price := cost(id)
	essences.spend(price.x, price.y)
	_levels[id] = level(id) + 1
	changed.emit()
	return true


## Blue and orange spent on every bought level.
func spent() -> Vector2i:
	var total := Vector2i.ZERO
	for data in CATALOG.nodes:
		for i in level(data.id):
			total += Vector2i(data.blue[i], data.orange[i])
	return total


func has_bought() -> bool:
	return not _levels.is_empty()


func can_reset(essences: Essences) -> bool:
	return has_bought() and essences.can_afford(0, 0, RESET_COST)


## Pays RESET_COST purple, gives back everything spent and empties the tree.
func reset(essences: Essences) -> bool:
	if not can_reset(essences):
		return false
	var refund := spent()
	essences.spend(0, 0, RESET_COST)
	essences.add(Essences.BLUE, refund.x)
	essences.add(Essences.ORANGE, refund.y)
	_levels.clear()
	changed.emit()
	return true


## Debug: every node at its top level.
func max_all() -> void:
	for data in CATALOG.nodes:
		_levels[data.id] = data.max_level
	changed.emit()


## Debug: every node back to level 0, free.
func clear() -> void:
	_levels.clear()
	changed.emit()


func to_dict() -> Dictionary:
	var out := {}
	for id: StringName in _levels:
		out[String(id)] = _levels[id]
	return out


## Keeps known ids only, clamps levels to 0..max_level and drops zeros.
func from_dict(data: Dictionary) -> void:
	_levels.clear()
	for key: Variant in data:
		var value: Variant = data[key]
		if not key is String or not (value is int or value is float):
			continue
		var node_data := node(StringName(key))
		if node_data == null:
			continue
		var clamped := clampi(int(value), 0, node_data.max_level)
		if clamped > 0:
			_levels[node_data.id] = clamped
	changed.emit()
