class_name ItemCatalog
extends Resource
## Every item in the game (fragments, legendaries, potions), listed by hand so
## exports never need to scan folders. Recipes come from the legendaries'
## components.

@export var items: Array[ItemData] = []


func find(id: StringName) -> ItemData:
	for item in items:
		if item.id == id:
			return item
	return null


## Every item by display name, A to Z (case ignored). The debug picker uses it.
func by_name() -> Array[ItemData]:
	var sorted: Array[ItemData] = items.duplicate()
	sorted.sort_custom(func(a: ItemData, b: ItemData) -> bool: return a.display_name.nocasecmp_to(b.display_name) < 0)
	return sorted


func fragments() -> Array[ItemData]:
	return _of_kind(ItemData.Kind.FRAGMENT)


func legendaries() -> Array[ItemData]:
	return _of_kind(ItemData.Kind.LEGENDARY)


func potions() -> Array[ItemData]:
	return _of_kind(ItemData.Kind.POTION)


## The legendary crafted from fragments `a` and `b` in either order, or null.
func combine(a: ItemData, b: ItemData) -> ItemData:
	if a == null or b == null or not a.is_fragment() or not b.is_fragment():
		return null
	for item in items:
		var parts := item.components
		if parts.size() == 2 and (
			(parts[0] == a.id and parts[1] == b.id) or (parts[0] == b.id and parts[1] == a.id)
		):
			return item
	return null


func _of_kind(kind: ItemData.Kind) -> Array[ItemData]:
	var found: Array[ItemData] = []
	for item in items:
		if item.kind == kind:
			found.append(item)
	return found
