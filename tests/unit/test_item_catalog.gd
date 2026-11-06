extends GutTest

const Fixtures := preload("res://tests/unit/item_fixtures.gd")

var catalog: ItemCatalog


func before_each() -> void:
	catalog = Fixtures.catalog()


func test_find_by_id() -> void:
	assert_eq(catalog.find(&"rod").id, &"rod")
	assert_null(catalog.find(&"missing"))


func test_fragments_and_legendaries() -> void:
	assert_eq(catalog.fragments().size(), 3)
	assert_eq(catalog.legendaries().size(), 2)


func test_combine_same_fragment_twice() -> void:
	var sword := catalog.find(&"sword")
	assert_eq(catalog.combine(sword, sword).id, &"edge")


func test_combine_ignores_order() -> void:
	var sword := catalog.find(&"sword")
	var rod := catalog.find(&"rod")
	assert_eq(catalog.combine(sword, rod).id, &"gunblade")
	assert_eq(catalog.combine(rod, sword).id, &"gunblade")


func test_combine_without_recipe_is_null() -> void:
	assert_null(catalog.combine(catalog.find(&"rod"), catalog.find(&"belt")))
	assert_null(catalog.combine(catalog.find(&"sword"), null))


func test_legendaries_never_combine() -> void:
	assert_null(catalog.combine(catalog.find(&"edge"), catalog.find(&"sword")))


func test_by_name_sorts_a_to_z() -> void:
	var names: Array = (load("res://data/items/catalog.tres") as ItemCatalog).by_name().map(
		func(item: ItemData) -> String: return item.display_name)
	assert_eq(names[0], "Archangel's Staff")
	assert_eq(names[1], "Armored Advance")
	assert_eq(names[2], "B.F. Sword")
	for i in names.size() - 1:
		assert_true(names[i].nocasecmp_to(names[i + 1]) <= 0, "%s before %s" % [names[i], names[i + 1]])


func test_craft_makes_a_legendary_or_upgraded_boots_in_either_order() -> void:
	var real := load("res://data/items/catalog.tres") as ItemCatalog
	var bow := real.find(&"recurve_bow")
	var speed := real.find(&"boots_of_speed")
	var tear := real.find(&"tear_of_the_goddess")
	assert_eq(real.craft(tear, tear), real.find(&"muramana"))
	assert_eq(real.craft(speed, bow), real.find(&"berserkers_greaves"))
	assert_eq(real.craft(bow, speed), real.find(&"berserkers_greaves"), "the boots can come second")
	assert_null(real.craft(real.find(&"muramana"), tear), "a legendary is never crafted")
	assert_null(real.craft(speed, null))


func test_a_legendarys_fee_is_its_cost_minus_its_fragments() -> void:
	var real := load("res://data/items/catalog.tres") as ItemCatalog
	var tear := real.find(&"tear_of_the_goddess")
	assert_eq(real.craft_fee(tear, tear), 2900 - 400 - 400, "Muramana")
	for legendary in real.legendaries():
		var a := real.find(legendary.components[0])
		var b := real.find(legendary.components[1])
		var fee := real.craft_fee(a, b)
		assert_eq(fee, legendary.cost - a.cost - b.cost, String(legendary.id))
		assert_gt(fee, 0, "%s costs more than its fragments" % legendary.id)


func test_crafting_then_selling_never_beats_selling_the_fragments() -> void:
	var real := load("res://data/items/catalog.tres") as ItemCatalog
	for legendary in real.legendaries():
		var a := real.find(legendary.components[0])
		var b := real.find(legendary.components[1])
		var crafted := legendary.sell_price() - real.craft_fee(a, b)
		assert_lt(crafted, a.sell_price() + b.sell_price(), String(legendary.id))


func test_a_boots_fee_is_its_upgrade_cost_and_nothing_costs_nothing() -> void:
	var real := load("res://data/items/catalog.tres") as ItemCatalog
	var bow := real.find(&"recurve_bow")
	assert_eq(real.craft_fee(real.find(&"boots_of_speed"), bow), 300)
	assert_eq(real.craft_fee(bow, real.find(&"berserkers_greaves")), 500, "Gunmetal Greaves")
	assert_eq(real.craft_fee(real.find(&"giants_belt"), real.find(&"boots_of_speed")), 0, "no line: nothing made")
