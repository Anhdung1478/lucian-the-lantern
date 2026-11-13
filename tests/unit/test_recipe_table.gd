extends GutTest
## The recipe table beside the backpack: which recipes are lit (Lucian holds
## both fragments, or wears the boots and holds their fragment) and where
## they sit; the boots' lines under their own heading.

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
	return rows.map(func(row: RecipeRow) -> StringName: return row.made.id)


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
	assert_false(gunblade._result.lit)
	assert_eq(gunblade._name.text, "gunblade", "the legendary is named")
	give(&"sword")
	assert_true(gunblade._parts[0].lit)
	assert_true(gunblade._result.lit, "the legendary lights with the line")


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
	assert_eq(screen._recipes.rows()[0].made.id, &"gunblade")
	assert_true(screen._recipes.rows()[0].lit)


func test_only_a_recipe_line_frames_its_icons() -> void:
	var icon := ItemIcon.new(catalog.find(&"sword"))
	assert_false(icon.framed, "an icon is plain unless asked: the item cards' are")
	icon.free()
	var row: RecipeRow = table.rows()[0]
	assert_true(row._result.framed)
	assert_true(row._parts[0].framed and row._parts[1].framed)


# --- Boots ---------------------------------------------------------------------


## The table again over a catalog that also has two starting boots, a second
## tier made with a sword and its third tier, and a second tier made with a
## rod.
func _with_boots() -> void:
	catalog = Fixtures.catalog()
	catalog.items.append_array([
		Fixtures.boots(&"walkers", 1), Fixtures.boots(&"charmed", 1),
		Fixtures.boots(&"greaves", 2, &"sword", &"", 300),
		Fixtures.boots(&"treads", 2, &"rod", &"", 550),
		Fixtures.boots(&"gunmetal", 3, &"sword", &"greaves", 500),
	])
	inventory = Inventory.new(catalog)
	table = RecipeTable.new()
	add_child_autofree(table)
	table.setup(catalog, inventory)


func _headings(of: RecipeTable) -> Array:
	return of.find_children("*", "HBoxContainer", true, false).filter(
		func(node: Node) -> bool: return node is BagHeading).map(func(node: BagHeading) -> String: return node.label.text)


func _row(id: StringName) -> RecipeRow:
	return table.rows().filter(func(row: RecipeRow) -> bool: return row.made.id == id)[0]


func test_the_boots_lines_follow_the_legendaries_under_their_own_heading() -> void:
	assert_eq(_headings(table), ["RECIPES"], "no boots in the catalog: no heading for them")
	_with_boots()
	assert_eq(_headings(table), ["RECIPES", "BOOTS"])
	assert_eq(ids(table.rows()), [&"edge", &"gunblade", &"greaves", &"gunmetal", &"treads"],
		"the legendaries, then each second tier with its third tier under it")
	var heading: Node = table._boots_heading
	assert_eq(heading.get_index(), 2, "the heading stands between the two kinds")
	assert_eq(table.NOTE, "Lit gold: you hold both parts.")


func test_the_two_starting_boots_share_the_first_cell_of_a_second_tier_line() -> void:
	_with_boots()
	var greaves := _row(&"greaves")
	assert_is(greaves._parts[0], RecipeChoice, "either pair gives the same boots: one line, one cell")
	var choice: RecipeChoice = greaves._parts[0]
	assert_eq(choice.icons.map(func(icon: ItemIcon) -> StringName: return icon.item.id), [&"walkers", &"charmed"])
	for icon: ItemIcon in choice.icons:
		var card := icon.tooltip_content()
		assert_not_null(card, "each pair has its own card")
		card.free()
	assert_eq((greaves._parts[1] as ItemIcon).item.id, &"sword", "then the fragment")
	assert_eq(greaves._result.item.id, &"greaves")
	assert_eq(greaves._name.text, "greaves")
	var gunmetal := _row(&"gunmetal")
	assert_is(gunmetal._parts[0], ItemIcon, "a third tier comes from one pair")
	assert_eq((gunmetal._parts[0] as ItemIcon).item.id, &"greaves")
	assert_eq((gunmetal._parts[1] as ItemIcon).item.id, &"sword")


func test_the_shared_cell_holds_both_pairs_inside_it() -> void:
	_with_boots()
	await wait_process_frames(2)
	var choice: RecipeChoice = _row(&"greaves")._parts[0]
	assert_eq(choice.size, Vector2(RecipeRow.ICON_SIZE, RecipeRow.ICON_SIZE), "as large as any other cell")
	var cell := Rect2(Vector2.ZERO, choice.size)
	for icon: ItemIcon in choice.icons:
		assert_true(cell.encloses(Rect2(icon.position, icon.size)), "%s inside the cell" % icon.item.id)
		assert_gt(icon.size.x, choice.size.x * 0.5, "each pair is more than half the cell")
	assert_ne(choice.icons[0].position, choice.icons[1].position, "side by side down the diagonal")


func test_a_boots_line_is_lit_while_lucian_wears_the_boots_and_holds_the_fragment() -> void:
	_with_boots()
	inventory.set_boots(catalog.find(&"walkers"))
	var greaves := _row(&"greaves")
	assert_true(greaves._parts[0].lit, "he wears a starting pair")
	assert_false(greaves._parts[1].lit, "no sword")
	assert_false(greaves.lit)
	assert_false(RecipeTable.can_craft(greaves.made, inventory))
	give(&"sword")
	assert_true(greaves.lit, "the Craft tab would make them")
	assert_true(RecipeTable.can_craft(greaves.made, inventory))
	assert_eq(table.rows()[0], greaves, "a lit line leads")
	assert_false(_row(&"treads").lit, "no rod")
	assert_true(_row(&"treads")._parts[0].lit)
	assert_false(_row(&"gunmetal").lit, "he does not wear the greaves yet")
	inventory.set_boots(catalog.find(&"charmed"))
	assert_true(greaves.lit, "the other starting pair makes the same boots")
	inventory.set_boots(catalog.find(&"greaves"))
	assert_false(greaves.lit, "the starting boots are gone")
	assert_false(greaves._parts[0].lit)
	assert_true(_row(&"gunmetal").lit, "the same fragment again makes the third tier")
	inventory.set_boots(null)
	assert_false(_row(&"gunmetal").lit, "no boots: no boots line is lit")


func test_the_real_catalog_has_a_line_for_every_upgraded_pair() -> void:
	var real: ItemCatalog = load("res://data/items/catalog.tres")
	var full := RecipeTable.new()
	add_child_autofree(full)
	full.setup(real)
	var upgraded := real.boots().filter(func(item: ItemData) -> bool: return item.boots_tier >= 2)
	assert_eq(upgraded.size(), 14)
	assert_eq(full.rows().size(), real.legendaries().size() + 14)
	var starting := real.boots().filter(func(item: ItemData) -> bool: return item.boots_tier == 1).map(
		func(item: ItemData) -> StringName: return item.id)
	assert_eq(starting, [&"boots_of_speed", &"slightly_magical_boots"])
	for row in full.rows():
		if not row.made.is_boots():
			continue
		assert_eq(real.boots_upgrade(real.find(_first_id(row)), real.find(row.made.upgrade_fragment)), row.made,
			"%s is what the Craft tab makes from its line" % row.made.id)
		if row.made.boots_tier == 2:
			assert_eq((row._parts[0] as RecipeChoice).icons.map(func(icon: ItemIcon) -> StringName: return icon.item.id), starting)


## The first boots a line takes.
func _first_id(row: RecipeRow) -> StringName:
	var part: Control = row._parts[0]
	return (part as RecipeChoice).icons[0].item.id if part is RecipeChoice else (part as ItemIcon).item.id



func test_a_lit_line_is_raised_with_a_gold_name_and_keeps_its_rims() -> void:
	give(&"sword")
	give(&"rod")
	var gunblade: RecipeRow = table.rows()[0]
	var box := gunblade.get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_eq(box.bg_color, UiStyle.SURFACE_RAISED, "a raised fill")
	assert_eq(box.border_width_left, 0, "no frame")
	assert_eq(gunblade._name.get_theme_color(&"font_color"), UiStyle.GOLD_COLOR)
	assert_false(gunblade._result.show_lit, "the cells keep their kind's rim")
	assert_eq(box.content_margin_right, RecipeRow.NAME_INSET, "the name keeps its inset")
	var plain: RecipeRow = table.rows()[1]
	assert_eq((plain.get_theme_stylebox(&"panel") as StyleBoxFlat).bg_color.a, 0.0)
