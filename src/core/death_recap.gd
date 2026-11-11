class_name DeathRecap
extends RefCounted
## The defeat screen's recap: what killed Lucian, what hurt him most and one
## plain tip, made from the stage's StageStats.

const SHARES := 3
const KILLED := "Killed by %s"
const KILLED_BY_BURN := "Killed by %s's burn"
const TREE_LINE := "You can afford an upgrade in the Evolution Tree."
const TIP_RANGED := "Ranged enemies: step sideways between their shots, or walk in and kill them first."
const TIP_MELEE := "Melee enemies: shoot, step back, shoot again. They can't hit what they can't reach."
const TIP_MARKS := "Red marks on the ground show where a hit will land. Step out before they fill."
const TIP_ELITE := "Elites hit hard. Kill the small ones around them first, then keep your distance."
const TIP_BOSS := "Watch the boss's red marks: each skill shows where it lands before it hits."
const TIP_BURN := "Burning ground keeps hurting while you stand on it. Walk out at once."
## The names of the sources that are no enemy, and how the killed-by line
## says them ("Killed by burning ground").
const SOURCE_NAMES := {&"burn": "Burning ground"}
const KILLED_NAMES := {&"burn": "burning ground"}
## Enemies whose behavior makes them ranged, and those that are red marks.
const RANGED := [&"ranged", &"spit"]
const MARKED := [&"siege"]


## The recap's parts, or {} when Lucian took no damage: "killed" (a line),
## "shares" (the top sources as "Name 40%"), "tip" and "tree" (a line, or ""
## when nothing in the Evolution Tree can be bought).
static func build(stats: StageStats, tree: EvolutionTree, essences: Essences) -> Dictionary:
	if stats.damage_by_source.is_empty():
		return {}
	var top := _ranked(stats.damage_by_source)
	return {
		"killed": _killed(stats),
		"shares": _shares(stats, top),
		"tip": _tip(top[0]),
		"tree": TREE_LINE if _can_buy_any(tree, essences) else "",
	}


## The source ids, most damage first.
static func _ranked(taken: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(taken.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		return taken[a] > taken[b] or (taken[a] == taken[b] and a < b))
	return ids


static func _killed(stats: StageStats) -> String:
	var who := _name(stats.last_hit_by)
	if stats.last_hit_with == DamageOverTime.SOURCE and _enemy(stats.last_hit_by):
		return KILLED_BY_BURN % who
	return KILLED % KILLED_NAMES.get(stats.last_hit_by, who)


static func _shares(stats: StageStats, top: Array[StringName]) -> Array[String]:
	var lines: Array[String] = []
	for id in top.slice(0, SHARES):
		lines.append("%s %d%%" % [_name(id), roundi(100.0 * stats.damage_by_source[id] / stats.damage_taken)])
	return lines


static func _tip(id: StringName) -> String:
	var data := _enemy(id)
	if data == null:
		return TIP_BURN
	if data.is_boss_kind():
		return TIP_BOSS
	if data.behavior in MARKED:
		return TIP_MARKS
	if data.kind == &"elite":
		return TIP_ELITE
	return TIP_RANGED if data.behavior in RANGED else TIP_MELEE


## Some open node the save can pay for: the tree's own can_buy, as the cost
## bar asks it.
static func _can_buy_any(tree: EvolutionTree, essences: Essences) -> bool:
	return tree.nodes().any(func(data: TreeNodeData) -> bool: return tree.can_buy(data.id, essences))


static func _name(id: StringName) -> String:
	var data := _enemy(id)
	if data:
		return data.display_name
	return SOURCE_NAMES.get(id, String(id).replace("_", " ").capitalize())


## The enemy with this id, or null when it is no enemy.
static func _enemy(id: StringName) -> EnemyData:
	var path := Stage.ENEMY_PATH % id
	return load(path) if ResourceLoader.exists(path) else null
