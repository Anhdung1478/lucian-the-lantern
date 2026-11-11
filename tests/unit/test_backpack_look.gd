extends GutTest
## The backpack screen in the Lantern look: its plates and headings, the
## cells' rims and what lights them.

const Fixtures := preload("res://tests/unit/item_fixtures.gd")

var inventory: Inventory
var screen: BackpackScreen


func before_each() -> void:
	inventory = Inventory.new(Fixtures.catalog())
	for id in [&"sword", &"sword", &"rod", &"edge"]:
		inventory.add(inventory.catalog.find(id))
	inventory.add(inventory.catalog.find(&"red"), 12)
	screen = BackpackScreen.new()
	add_child_autofree(screen)
	screen.setup(inventory)
	screen.open()
	await wait_physics_frames(3)


func cell(index: int) -> ItemCell:
	return screen._cells[index]


func center(index: int) -> Vector2:
	return cell(index).get_global_rect().get_center()


func send(index: int, event: InputEventMouse, at: Vector2) -> void:
	event.global_position = at
	screen.on_cell_input(cell(index), event)


## Picks the item in `from` up and holds it over `over`.
func hold(from: int, over: int) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	send(from, press, center(from))
	send(from, InputEventMouseMotion.new(), center(over))
	screen._process(0.0)


func test_the_backpack_sits_on_an_ornate_plate_under_a_spaced_heading() -> void:
	var grid := cell(0).get_parent()
	var plate := grid.get_parent().get_parent() as Plate
	assert_not_null(plate, "the cells sit on a Plate")
	assert_true(plate.ornate)
	var heading := grid.get_parent().get_child(0) as BagHeading
	assert_not_null(heading, "the heading comes first")
	assert_eq(heading.label.text, "BACKPACK")
	assert_eq(heading.label.get_theme_color(&"font_color"), UiStyle.TITLE_COLOR)
	var font := heading.label.get_theme_font(&"font") as FontVariation
	assert_not_null(font, "its letters are spaced")
	assert_eq(font.spacing_glyph, BagHeading.SPACING)


func test_a_cell_rim_follows_the_item_in_it() -> void:
	assert_eq(cell(0).rim(), UiStyle.RIM_FRAGMENT)
	assert_eq(cell(3).rim(), UiStyle.RIM_LEGENDARY)
	assert_eq(cell(4).rim(), UiStyle.RIM_POTION, "the potions that did not fit their cell")
	assert_eq(cell(20).rim(), UiStyle.CELL_BORDER, "an empty cell")


func test_a_cell_lights_up_under_the_mouse_when_it_holds_an_item() -> void:
	assert_false(cell(0).is_lit())
	cell(0).hovered = true
	assert_true(cell(0).is_lit())
	cell(20).hovered = true
	assert_false(cell(20).is_lit(), "an empty cell stays dark")
	cell(0).hovered = false
	assert_false(cell(0).is_lit())


func test_closing_leaves_no_cell_lit() -> void:
	cell(0).hovered = true
	screen.close()
	screen.open()
	assert_false(cell(0).is_lit())


func test_a_dragged_item_lights_only_a_cell_that_would_take_it() -> void:
	inventory.unlocked_backpack = 30
	hold(0, 20)
	assert_true(screen.takes_drop(20), "an empty cell")
	assert_true(cell(20).is_lit())
	assert_false(cell(21).is_lit(), "only the cell under the item")
	assert_true(screen.takes_drop(2), "a swap")
	assert_false(screen.takes_drop(0), "its own cell")
	assert_false(screen.takes_drop(40), "a locked cell")
	assert_false(screen.takes_drop(Inventory.HP_POTION_CELL), "a potion cell takes no fragment")
	assert_false(screen.takes_drop(Inventory.BOOTS_CELL))
	assert_false(screen.takes_drop(-1))
	hold(0, 40)
	assert_false(cell(40).is_lit(), "over a locked cell")
	hold(0, 0)
	assert_false(cell(0).is_lit(), "over its own cell")


func test_the_mouse_lights_nothing_during_a_drag() -> void:
	cell(1).hovered = true
	hold(0, 20)
	assert_false(cell(1).is_lit())


func test_nothing_takes_a_drop_with_nothing_dragged() -> void:
	assert_false(screen.takes_drop(20))


func test_the_dragged_item_leaves_its_cell_empty() -> void:
	hold(0, 20)
	assert_eq(cell(0).rim(), UiStyle.CELL_BORDER)


func test_a_corner_tag_sits_flush_in_its_corner() -> void:
	var rect := Rect2(10, 20, 64, 64)
	var count := ItemIcon.tag_rect("9", rect, CORNER_BOTTOM_RIGHT)
	assert_eq(count.end, rect.end)
	assert_eq(count.size.y, ItemIcon.TAG_HEIGHT)
	var key := ItemIcon.tag_rect("7", rect, CORNER_TOP_LEFT)
	assert_eq(key.position, rect.position)
	var wide := ItemIcon.tag_rect("M4", rect, CORNER_TOP_LEFT)
	assert_gt(wide.size.x, key.size.x, "it grows with its text")
	assert_true(rect.encloses(wide))


func test_the_equip_row_and_the_gear_row_sit_on_plain_plates() -> void:
	for index: int in [Inventory.EQUIP_START, Inventory.BOOTS_CELL]:
		var plate := cell(index).get_parent().get_parent() as Plate
		assert_not_null(plate, "cell %d's row sits on a Plate" % index)
		assert_false(plate.ornate, "only the backpack is ornate")
	assert_eq(cell(Inventory.EQUIP_START).get_parent(), screen._cells.back().get_parent(), "the sell slot ends the equip row")


func test_equip_slots_and_potion_cells_carry_their_key() -> void:
	assert_eq(cell(Inventory.EQUIP_START).key_text(), "1")
	assert_eq(cell(Inventory.EQUIP_START + 5).key_text(), "6")
	assert_eq(cell(Inventory.HP_POTION_CELL).key_text(), "7")
	assert_eq(cell(Inventory.MP_POTION_CELL).key_text(), "8")
	assert_eq(cell(0).key_text(), "", "a backpack cell has no key")
	assert_eq(cell(Inventory.BOOTS_CELL).key_text(), "")
	assert_eq(screen._cells.back().key_text(), "", "nor has the sell slot")


func test_an_empty_potion_cell_has_a_fainter_rim_of_its_potion() -> void:
	assert_eq(cell(Inventory.HP_POTION_CELL).rim(), UiStyle.RIM_POTION, "nine of the potions went in")
	var empty := cell(Inventory.MP_POTION_CELL).rim()
	assert_eq(empty, Color(UiStyle.RIM_POTION, ItemCell.EMPTY_RIM_ALPHA))
	inventory.set_boots(Fixtures.boots(&"speed", 1))
	assert_eq(cell(Inventory.BOOTS_CELL).rim(), UiStyle.RIM_BOOTS)


func test_opening_fades_the_backpack_in_at_once_visible() -> void:
	screen.close()
	screen.open()
	assert_true(screen.visible, "visible flips at once")
	assert_eq(screen._backdrop.modulate.a, 0.0, "the fade starts clear")
	await wait_seconds(BackpackScreen.FADE_TIME + 0.15)
	assert_eq(screen._backdrop.modulate.a, 1.0, "and ends solid")


func test_low_effects_open_without_a_fade() -> void:
	var settings := GameSettings.instance()
	var quality: Variant = settings.get_value(&"quality")
	settings.set_value(&"quality", "low", false)
	screen.close()
	screen.open()
	settings.set_value(&"quality", quality, false)
	assert_true(screen.visible)
	assert_eq(screen._backdrop.modulate.a, 1.0)
