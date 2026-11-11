extends GutTest
## The recipe table beside the backpack: which recipes are lit (Lucian holds
## both fragments) and where they sit.

const Fixtures := preload("res://tests/unit/item_fixtures.gd")

var catalog: ItemCatalog
var inventory: Inventory
var table: RecipeTable


func before_each() -> void:
	catalog = Fixtures.catalog()
	inventory = Inventory.new(catalog)
	table = RecipeTable.new()
	add_child_autofree(table)
	table.setup(catalog, inventory)


func give(id: StringName) -> void:
	inventory.add(catalog.find(id))


func ids(rows: Array[RecipeRow]) -> Array:
	return rows.map(func(row: RecipeRow) -> StringName: return row.legendary.id)


func test_held_counts_a_fragment_in_the_backpack_and_in_the_equip_slots() -> void:
	assert_eq(RecipeTable.held(inventory, &"sword"), 0)
	give(&"sword")
	give(&"sword")
	give(&"rod")
	inventory.apply_drop(0, Inventory.EQUIP_START)
	assert_eq(RecipeTable.held(inventory, &"sword"), 2, "one equipped, one in the backpack")
	assert_eq(RecipeTable.held(inventory, &"rod"), 1)
	assert_eq(RecipeTable.held(inventory, &"belt"), 0)


func test_a_recipe_can_be_crafted_once_both_fragments_are_held() -> void:
	var gunblade := catalog.find(&"gunblade")
	assert_false(RecipeTable.can_craft(gunblade, inventory))
	give(&"sword")
	assert_false(RecipeTable.can_craft(gunblade, inventory), "the rod is missing")
	assert_true(RecipeTable.holds_part(gunblade, 0, inventory))
	assert_false(RecipeTable.holds_part(gunblade, 1, inventory))
	give(&"rod")
	assert_true(RecipeTable.can_craft(gunblade, inventory))
	assert_false(RecipeTable.can_craft(gunblade, null), "nothing is held without an inventory")


func test_a_recipe_taking_one_fragment_twice_needs_two_of_it() -> void:
	var edge := catalog.find(&"edge")
	give(&"sword")
	assert_true(RecipeTable.holds_part(edge, 0, inventory))
	assert_false(RecipeTable.holds_part(edge, 1, inventory), "the same sword is not the second one")
	assert_false(RecipeTable.can_craft(edge, inventory))
	give(&"sword")
	assert_true(RecipeTable.can_craft(edge, inventory))


func test_the_table_is_a_plate_headed_recipes_with_a_line_per_legendary() -> void:
	assert_is(table, Plate)
	var heading: BagHeading = table.find_children("*", "HBoxContainer", true, false).filter(
		func(node: Node) -> bool: return node is BagHeading)[0]
	assert_eq(heading.label.text, "RECIPES")
	assert_eq(ids(table.rows()), [&"edge", &"gunblade"], "the catalog's order")
	assert_false(table.rows()[0].lit)
	assert_false(table.rows()[1].lit)


func test_a_lit_recipe_comes_first_and_follows_the_inventory() -> void:
	give(&"sword")
	give(&"rod")
	assert_eq(ids(table.rows()), [&"gunblade", &"edge"], "the one that can be crafted leads")
	assert_true(table.rows()[0].lit)
	assert_false(table.rows()[1].lit)
	give(&"sword")
	assert_eq(ids(table.rows()), [&"edge", &"gunblade"], "both lit: the catalog's order again")
	assert_true(table.rows()[0].lit)
	inventory.remove(1)
	assert_eq(ids(table.rows()), [&"edge", &"gunblade"])
	assert_false(table.rows()[1].lit, "the rod is gone")


func test_a_line_marks_each_fragment_that_is_held() -> void:
	give(&"rod")
	var gunblade: RecipeRow = table.rows()[1]
	assert_false(gunblade._parts[0].lit, "no sword")
	assert_true(gunblade._parts[1].lit, "the rod")
	assert_false(gunblade._made.lit)
	assert_eq(gunblade._name.text, "gunblade", "the legendary is named")
	give(&"sword")
	assert_true(gunblade._parts[0].lit)
	assert_true(gunblade._made.lit, "the legendary lights with the line")


func test_a_table_without_an_inventory_lights_nothing() -> void:
	var plain := RecipeTable.new()
	add_child_autofree(plain)
	plain.setup(catalog)
	assert_eq(plain.rows().size(), 2)
	assert_false(plain.rows()[0].lit)


func test_the_backpack_gives_the_table_its_inventory() -> void:
	give(&"sword")
	give(&"rod")
	var screen := BackpackScreen.new()
	add_child_autofree(screen)
	screen.setup(inventory)
	assert_eq(screen._recipes.inventory, inventory)
	assert_eq(screen._recipes.rows()[0].legendary.id, &"gunblade")
	assert_true(screen._recipes.rows()[0].lit)


func test_only_a_recipe_line_frames_its_icons() -> void:
	var icon := ItemIcon.new(catalog.find(&"sword"))
	assert_false(icon.framed, "an icon is plain unless asked: the item cards' are")
	icon.free()
	var row: RecipeRow = table.rows()[0]
	assert_true(row._made.framed)
	assert_true(row._parts[0].framed and row._parts[1].framed)
