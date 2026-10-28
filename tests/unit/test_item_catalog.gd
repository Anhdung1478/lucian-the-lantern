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
	assert_eq(names[1], "B.F. Sword")
	for i in names.size() - 1:
		assert_true(names[i].nocasecmp_to(names[i + 1]) <= 0, "%s before %s" % [names[i], names[i + 1]])
