extends GutTest


func test_a_plate_keeps_its_pad_around_what_it_holds() -> void:
	var plate := Plate.new(20.0)
	add_child_autofree(plate)
	var child := Control.new()
	child.custom_minimum_size = Vector2(100, 40)
	plate.add_child(child)
	await wait_process_frames(2)
	assert_eq(plate.get_combined_minimum_size(), Vector2(140, 80))
	assert_eq(child.position, Vector2(20, 20))
	plate.pad = 6.0
	await wait_process_frames(2)
	assert_eq(plate.get_combined_minimum_size(), Vector2(112, 52), "the pad can change later")


func test_a_plate_is_ornate_unless_told() -> void:
	var ornate := Plate.new()
	assert_true(ornate.ornate)
	ornate.free()
	var plain := Plate.new(8.0, false)
	assert_false(plain.ornate)
	plain.free()


func test_a_plate_draws_at_any_size() -> void:
	# Smaller than its corners too: no polygon with crossed points.
	for size: Vector2 in [Vector2(300, 120), Vector2(12, 12), Vector2(4, 40)]:
		var plate := Plate.new()
		plate.custom_minimum_size = size
		add_child_autofree(plate)
		plate.queue_redraw()
	await wait_process_frames(2)
	assert_no_new_orphans()
	pass_test("three sizes drew")


func test_a_diamond_has_four_points_around_its_center() -> void:
	var points := Plate.diamond(Vector2(10, 10), 4.0)
	assert_eq(points.size(), 4)
	assert_eq(points[0], Vector2(10, 6))
	assert_eq(points[2], Vector2(10, 14))


func test_a_cell_rim_follows_the_item_in_it() -> void:
	var catalog: ItemCatalog = load("res://data/items/catalog.tres")
	assert_eq(UiStyle.item_rim(null), UiStyle.CELL_BORDER)
	assert_eq(UiStyle.item_rim(catalog.find(&"bf_sword")), UiStyle.RIM_FRAGMENT)
	assert_eq(UiStyle.item_rim(catalog.find(&"infinity_edge")), UiStyle.RIM_LEGENDARY)
	assert_eq(UiStyle.item_rim(catalog.find(&"hp_potion")), UiStyle.RIM_POTION)
	assert_eq(UiStyle.item_rim(catalog.find(&"boots_of_speed")), UiStyle.RIM_BOOTS)


func test_a_lit_cell_has_a_gold_rim() -> void:
	assert_eq(UiStyle.cell_style().border_color, UiStyle.CELL_BORDER)
	assert_eq(UiStyle.cell_style(UiStyle.RIM_LEGENDARY).border_color, UiStyle.RIM_LEGENDARY)
	assert_eq(UiStyle.cell_style(UiStyle.RIM_LEGENDARY, true).border_color, UiStyle.GOLD_COLOR)
