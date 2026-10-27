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


func test_drop_on_partner_before_the_line_closes_swaps() -> void:
	drag(1, 2, 0.6)
	assert_eq(id_at(1), &"rod")
	assert_eq(id_at(2), &"sword")


func test_holding_on_partner_for_the_full_line_crafts() -> void:
	drag(1, 2, 1.0)
	assert_eq(id_at(1), &"")
	assert_eq(id_at(2), &"gunblade")


func test_craft_popup_follows_the_hold() -> void:
	press(0)
	move(0, center(1))
	assert_true(screen._craft_popup.visible)
	screen._process(0.5)
	assert_almost_eq(screen._craft_popup.progress, 0.5, 0.001)


func test_no_popup_without_a_recipe() -> void:
	press(2)
	move(2, center(3))
	assert_false(screen._craft_popup.visible)


func test_changing_target_restarts_the_line() -> void:
	press(1)
	move(1, center(0))
	screen._process(0.8)
	move(1, center(2))
	screen._process(0.3)
	release(1, center(2))
	assert_eq(id_at(1), &"rod", "swapped, not crafted")
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
