extends RefCounted
## Small in-memory catalog for item tests: 3 fragments and 2 recipes.


static func fragment(id: StringName, stats: Dictionary) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.display_name = String(id)
	item.kind = ItemData.Kind.FRAGMENT
	item.stats.assign(stats)
	return item


static func legendary(id: StringName, a: StringName, b: StringName, stats: Dictionary) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.display_name = String(id)
	item.kind = ItemData.Kind.LEGENDARY
	item.components.assign([a, b])
	item.stats.assign(stats)
	return item


static func catalog() -> ItemCatalog:
	var result := ItemCatalog.new()
	result.items.assign([
		fragment(&"sword", {&"ad": 35.0}),
		fragment(&"rod", {&"ap": 60.0}),
		fragment(&"belt", {&"max_hp": 350.0}),
		legendary(&"edge", &"sword", &"sword", {&"ad": 65.0, &"crit_chance": 0.25}),
		legendary(&"gunblade", &"sword", &"rod", {&"ad": 40.0, &"ap": 80.0}),
	])
	return result
