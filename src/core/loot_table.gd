class_name LootTable
extends RefCounted
## Items a kill drops on the ground. A normal or elite enemy drops at most
## one: a legendary (rare), or else maybe a fragment. A boss or a mini boss
## always drops a fragment, and sometimes a legendary too.

## Kind -> [fragment chance, legendary chance]. A fragment chance of 1 is a
## fragment for sure, with or without the legendary.
const CHANCES := {
	&"normal": [0.04, 0.003],
	&"elite": [0.25, 0.03],
	&"mini_boss": [1.0, 0.08],
	&"boss": [1.0, 0.15],
}


static func roll(kind: StringName, catalog: ItemCatalog, rng: RandomNumberGenerator) -> Array[ItemData]:
	var drops: Array[ItemData] = []
	var chance: Array = CHANCES[kind]
	var legendary: bool = rng.randf() < chance[1]
	if legendary:
		drops.append(_pick(catalog.legendaries(), rng))
	if chance[0] >= 1.0 or (not legendary and rng.randf() < chance[0]):
		drops.append(_pick(catalog.fragments(), rng))
	return drops


static func _pick(items: Array[ItemData], rng: RandomNumberGenerator) -> ItemData:
	return items[rng.randi_range(0, items.size() - 1)]
