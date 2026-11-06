extends GutTest

const Fixtures := preload("res://tests/unit/item_fixtures.gd")

var inventory: Inventory
var screen: BackpackScreen


func before_each() -> void:
	inventory = Inventory.new(Fixtures.catalog())
	for id in [&"sword", &"sword", &"rod", &"belt"]:
		inventory.add(inventory.catalog.find(id))
	screen = BackpackScreen.new()
	add_child_autofree(screen)
	screen.setup(inventory)
	screen.open()
	await wait_physics_frames(3)


func center(index: int) -> Vector2:
	return screen._cells[index].get_global_rect().get_center()


func send(cell_index: int, event: InputEventMouse, at: Vector2) -> void:
	event.global_position = at
	screen.on_cell_input(screen._cells[cell_index], event)


func press(index: int) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	send(index, event, center(index))


## Motion and release always reach the pressed cell, wherever the mouse is.
func move(pressed_index: int, at: Vector2) -> void:
	send(pressed_index, InputEventMouseMotion.new(), at)
	screen._process(0.0)


func release(pressed_index: int, at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	send(pressed_index, event, at)


func drag(from: int, to: int, hold: float) -> void:
	press(from)
	move(from, center(to))
	screen._process(hold)
	release(from, center(to))


func id_at(index: int) -> StringName:
	var item := inventory.item_at(index)
	return item.id if item else &""


func test_quick_click_does_nothing() -> void:
	press(0)
	screen._process(0.05)
	assert_false(screen.is_dragging())
	release(0, center(0))
	assert_eq(id_at(0), &"sword")


func test_holding_still_picks_the_item_up() -> void:
	press(0)
	screen._process(0.25)
	assert_eq(screen.dragged_index(), 0)


func test_moving_while_held_picks_the_item_up() -> void:
	press(0)
	move(0, center(0) + Vector2(10, 0))
	assert_eq(screen.dragged_index(), 0)


func test_drop_on_empty_cell_moves() -> void:
	drag(3, 10, 0.1)
	assert_eq(id_at(3), &"")
	assert_eq(id_at(10), &"belt")
	assert_false(screen.is_dragging())


func test_holding_on_a_recipe_partner_still_only_swaps() -> void:
	drag(1, 2, 5.0)
	assert_eq(id_at(1), &"rod", "crafting is at the merchant, never in the backpack")
	assert_eq(id_at(2), &"sword")


func test_drop_outside_returns_the_item() -> void:
	press(3)
	move(3, Vector2(-500, -500))
	release(3, Vector2(-500, -500))
	assert_eq(id_at(3), &"belt")


func test_drop_into_equip_slot_equips() -> void:
	drag(0, Inventory.EQUIP_START, 0.1)
	assert_eq(id_at(Inventory.EQUIP_START), &"sword")
	assert_almost_eq(inventory.equipped_bonus()[&"ad"], 35.0, 0.001)


func test_drop_on_locked_slot_returns() -> void:
	inventory.unlocked_equip = 2
	drag(0, Inventory.EQUIP_START + 3, 0.1)
	assert_eq(id_at(0), &"sword")


func test_closing_mid_drag_returns_the_item() -> void:
	press(3)
	move(3, center(10))
	screen.close()
	release(3, center(10))
	assert_eq(id_at(3), &"belt")
	assert_false(screen.is_dragging())


func test_empty_and_locked_cells_cannot_be_picked_up() -> void:
	press(20)
	screen._process(0.3)
	assert_false(screen.is_dragging())


func right_click(index: int) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	send(index, event, center(index))


func test_a_right_click_on_a_potion_does_nothing() -> void:
	inventory.put(6, inventory.catalog.find(&"red"))
	right_click(6)
	assert_eq(inventory.count_at(6), 1, "no Use button: potions are drunk with keys 7 and 8")
	assert_false(screen.has_signal(&"potion_used"))
	assert_false(screen.is_dragging())


func test_a_drop_on_a_locked_backpack_cell_returns() -> void:
	inventory.unlocked_backpack = 10
	drag(0, 20, 0.1)
	assert_eq(id_at(0), &"sword")
	assert_eq(id_at(20), &"")


func test_the_grid_has_9_columns_and_54_cells() -> void:
	assert_eq(BackpackScreen.COLUMNS, 9)
	var grid := screen._cells[0].get_parent() as GridContainer
	assert_eq(grid.columns, 9)
	assert_eq(grid.get_child_count(), 54)


## The text of the first Label under `node`.
func _label_text(node: Node) -> String:
	if node is Label:
		return node.text
	for child in node.get_children():
		var text := _label_text(child)
		if text != "":
			return text
	return ""


func test_a_locked_backpack_cell_points_to_the_evolution_tree() -> void:
	inventory.unlocked_backpack = 10
	var card: Control = screen._cells[20].tooltip_content()
	assert_eq(_label_text(card), "Buy Backpack Slots in the Evolution Tree")
	card.free()
	assert_null(screen._cells[5].tooltip_content())
