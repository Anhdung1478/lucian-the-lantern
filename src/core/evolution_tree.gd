class_name EvolutionTree
extends RefCounted
## Levels bought in the Evolution Tree and the rules for buying them. Each
## level has its own rules: enough acts cleared, enough of the node's
## requirements at level 1, and enough levels in the nodes of its level sum
## (R needs Q + W + E ranks). Reset costs 5 purple and gives back every blue
## and orange spent. `changed` fires on the acts setter, buy, reset, max_all,
## clear and from_dict.

signal changed

const CATALOG: TreeCatalog = preload("res://data/tree/catalog.tres")
const RESET_COST := 5
## The groves, in tab order.
const BRANCHES: Array[StringName] = [&"skills", &"stats", &"backpack", &"economy", &"summoners"]

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


## The nodes of one grove.
func branch_nodes(branch: StringName) -> Array[TreeNodeData]:
	var out: Array[TreeNodeData] = []
	for data in CATALOG.nodes:
		if data.branch == branch:
			out.append(data)
	return out


func level(id: StringName) -> int:
	return _levels.get(id, 0)


## The node's value at its current level.
func value(id: StringName) -> float:
	return node(id).value(level(id))


## The total of the levels in the node's `level_sum_ids`.
func level_sum(id: StringName) -> int:
	var total := 0
	for summed in node(id).level_sum_ids:
		total += level(summed)
	return total


## Whether the rules for buying the level after `at_level` are met: acts
## cleared, requirements and level sum. Cost and max level are not looked at.
func is_level_open(id: StringName, at_level: int) -> bool:
	var data := node(id)
	if acts_cleared < _act_needed(data, at_level):
		return false
	return _requires_met(data) and level_sum(id) >= data.sum_needed(at_level)


## The first level's rules are met.
func is_open(id: StringName) -> bool:
	return is_level_open(id, 0)


## Not maxed, and the rules for the next level are met.
func next_level_open(id: StringName) -> bool:
	return not is_maxed(id) and is_level_open(id, level(id))


## "Requires: ..." for what is still missing to buy the level after
## `at_level`: nodes ("A, B or C", "any 2 of ...", "A, B and C"), "Clear Act 2"
## and "9 levels in Q + W + E (now 7)", joined with "and". "" when all is met.
func requirement_text(id: StringName, at_level: int) -> String:
	var data := node(id)
	var parts: PackedStringArray = []
	if not _requires_met(data):
		var names: PackedStringArray = []
		for required in data.requires:
			names.append(node(required).display_name)
		if data.requires_count == 0 or data.requires_count >= names.size():
			parts.append(_join(names, "and"))
		elif data.requires_count == 1:
			parts.append(_join(names, "or"))
		else:
			parts.append("any %d of %s" % [data.requires_count, _join(names, "or")])
	var act := _act_needed(data, at_level)
	if acts_cleared < act:
		parts.append("Clear Act %d" % act)
	var needed := data.sum_needed(at_level)
	if level_sum(id) < needed:
		var names: PackedStringArray = []
		for summed in data.level_sum_ids:
			names.append(node(summed).short_name())
		parts.append("%d level%s in %s (now %d)" % [needed, "" if needed == 1 else "s", " + ".join(names), level_sum(id)])
	if parts.is_empty():
		return ""
	return "Requires: " + " and ".join(parts)


## What the next level still needs; "" when maxed or when it is open.
func next_requirement_text(id: StringName) -> String:
	if is_maxed(id) or next_level_open(id):
		return ""
	return requirement_text(id, level(id))


## The next level is open and costs nothing: a free upgrade to claim.
func is_free(id: StringName) -> bool:
	return next_level_open(id) and cost(id) == Vector2i.ZERO


## The ids of the free upgrades, in catalog order; of one grove, or of all.
func free_ids(branch := &"") -> Array[StringName]:
	var out: Array[StringName] = []
	for data in CATALOG.nodes:
		if (branch == &"" or data.branch == branch) and is_free(data.id):
			out.append(data.id)
	return out


func has_free(branch := &"") -> bool:
	return not free_ids(branch).is_empty()


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
	return next_level_open(id) and essences.can_afford(price.x, price.y)


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


func _act_needed(data: TreeNodeData, at_level: int) -> int:
	return maxi(data.requires_act, data.act_needed(at_level))


func _requires_met(data: TreeNodeData) -> bool:
	var met := data.requires.filter(func(required: StringName) -> bool: return level(required) > 0).size()
	return met >= (data.requires.size() if data.requires_count == 0 else data.requires_count)


## "A, B or C" with `word` before the last name.
static func _join(names: PackedStringArray, word: String) -> String:
	if names.size() == 1:
		return names[0]
	return "%s %s %s" % [", ".join(names.slice(0, -1)), word, names[-1]]
