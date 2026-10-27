extends GutTest

const Fixtures := preload("res://tests/unit/item_fixtures.gd")

var inventory: Inventory
var wallet: Wallet
var stock: MerchantStock
var screen: BackpackScreen


func before_each() -> void:
	var catalog := Fixtures.catalog()
	for item in catalog.items:
		item.cost = 1000 if not item.is_potion() else 50
	inventory = Inventory.new(catalog)
	inventory.add(catalog.find(&"sword"))
	wallet = Wallet.new()
	wallet.add(5000)
	stock = MerchantStock.new(catalog, 3)
	screen = BackpackScreen.new()
	add_child_autofree(screen)
	screen.setup(inventory)
	screen.open_shop(Shop.new(stock, inventory, wallet))
	await wait_physics_frames(3)


func slot(tab: int, index: int) -> ShopSlot:
	return screen.shop_panel().slots(tab)[index]


func center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


func cell(index: int) -> ItemCell:
	return screen._cells[index]


func sell_cell() -> ItemCell:
	return screen._cells[screen._cells.size() - 1]


func mouse(target: Control, event: InputEventMouse, at: Vector2) -> void:
	event.global_position = at
	if target is ShopSlot:
		screen.on_shop_slot_input(target, event)
	else:
		screen.on_cell_input(target, event)


func button(target: Control, index: MouseButton, pressed: bool, at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	mouse(target, event, at)


## Press on `from`, move over `to`, release there. Every event goes to the
## pressed control, as in Godot.
func drag(from: Control, to: Control) -> void:
	button(from, MOUSE_BUTTON_LEFT, true, center(from))
	mouse(from, InputEventMouseMotion.new(), center(to))
	screen._process(0.0)
	button(from, MOUSE_BUTTON_LEFT, false, center(to))


func test_shop_mode_hides_the_recipe_table() -> void:
	assert_true(screen.is_shopping())
	assert_false(screen._recipes.visible)


func test_right_click_buys_into_the_first_empty_cell() -> void:
	var item := stock.item_at(0)
	button(slot(0, 0), MOUSE_BUTTON_RIGHT, true, center(slot(0, 0)))
	assert_eq(inventory.item_at(1), item)
	assert_eq(wallet.gold, 4000)


func test_dragging_a_shop_item_onto_a_cell_buys_it_there() -> void:
	var item := stock.item_at(1)
	drag(slot(0, 1), cell(20))
	assert_eq(inventory.item_at(20), item)
	assert_true(stock.is_sold(1))


func test_dragging_onto_an_occupied_cell_buys_nothing() -> void:
	drag(slot(0, 1), cell(0))
	assert_eq(wallet.gold, 5000)
	assert_false(stock.is_sold(1))


func test_dropping_a_shop_item_outside_buys_nothing() -> void:
	button(slot(0, 0), MOUSE_BUTTON_LEFT, true, center(slot(0, 0)))
	mouse(slot(0, 0), InputEventMouseMotion.new(), Vector2(5, 5))
	screen._process(0.0)
	button(slot(0, 0), MOUSE_BUTTON_LEFT, false, Vector2(5, 5))
	assert_eq(wallet.gold, 5000)


func test_potions_tab_buys_potions() -> void:
	screen.shop_panel().show_tab(1)
	await wait_physics_frames(2)
	button(slot(1, 0), MOUSE_BUTTON_RIGHT, true, center(slot(1, 0)))
	button(slot(1, 0), MOUSE_BUTTON_RIGHT, true, center(slot(1, 0)))
	assert_eq(inventory.item_at(1).id, &"red")
	assert_eq(inventory.count_at(1), 2)


func test_dropping_on_the_sell_slot_sells() -> void:
	drag(cell(0), sell_cell())
	assert_null(inventory.item_at(0))
	assert_eq(wallet.gold, 5700)


func test_sell_preview_while_over_the_sell_slot() -> void:
	button(cell(0), MOUSE_BUTTON_LEFT, true, center(cell(0)))
	mouse(cell(0), InputEventMouseMotion.new(), center(sell_cell()))
	screen._process(0.0)
	assert_eq(screen.sell_preview(), 700)
	button(cell(0), MOUSE_BUTTON_LEFT, false, Vector2(5, 5))


func test_refused_purchase_shows_a_message() -> void:
	wallet.reset()
	button(slot(0, 0), MOUSE_BUTTON_RIGHT, true, center(slot(0, 0)))
	assert_eq(screen.shop_panel()._message.text, "Not enough gold")


func test_closing_ends_shop_mode() -> void:
	screen.close()
	assert_false(screen.is_shopping())
	assert_true(screen._recipes.visible)
