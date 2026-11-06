extends GutTest
## Player input around dashes and Flash: a move from before them is dropped,
## a right-click during the dash or after it is kept.

const Slot := ChampionProgress.Slot

var lucian: Lucian
var controller: LucianController


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	# Trails and sparks go here, so they are freed with the test.
	var effects := Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	add_child_autofree(lucian)
	controller = lucian.get_node("Controller")
	lucian.progress.set_level(3)
	lucian.try_rank_up(Slot.E)


func after_each() -> void:
	Input.action_release(&"move")
	get_viewport().canvas_transform = Transform2D.IDENTITY


func right_click() -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	Input.action_press(&"move")
	controller._unhandled_input(press)


## The camera scrolling (follow mode, or the cursor moving to aim) changes
## the world spot under a held right-click.
func scroll_camera() -> void:
	get_viewport().canvas_transform = Transform2D(0.0, Vector2(-150, -150))


func test_a_move_held_from_before_the_dash_is_dropped() -> void:
	right_click()
	assert_true(lucian.try_cast(Slot.E, Vector2(1000, 0)))
	scroll_camera()
	# The dash takes 280 / 1350 = 0.21 s.
	await wait_seconds(0.3)
	var landed := lucian.global_position
	await wait_seconds(0.3)
	assert_almost_eq(lucian.global_position, landed, Vector2(0.5, 0.5), "stands where the dash ended")


func test_a_right_click_during_the_dash_walks_on_after_it() -> void:
	assert_true(lucian.try_cast(Slot.E, Vector2(1000, 0)))
	await wait_physics_frames(2)
	right_click()
	Input.action_release(&"move")
	assert_true(lucian.is_dashing())
	await wait_seconds(0.3)
	var landed := lucian.global_position
	await wait_seconds(0.3)
	assert_gt(lucian.global_position.distance_to(landed), 20.0, "walking to the new click")


func test_a_dash_drops_a_merchant_visit() -> void:
	var merchant := Merchant.new()
	merchant.position = Vector2(-2000, 0)
	add_child_autofree(merchant)
	lucian.command_visit(merchant)
	assert_true(lucian.try_cast(Slot.E, Vector2(1000, 0)))
	await wait_seconds(0.3)
	var landed := lucian.global_position
	await wait_seconds(0.3)
	assert_almost_eq(lucian.global_position, landed, Vector2(0.5, 0.5), "no longer walking to the merchant")


func test_flash_drops_a_move_held_from_before_it() -> void:
	right_click()
	assert_true(lucian.use_summoner(0, Vector2(300, 0)))
	scroll_camera()
	await wait_physics_frames(2)
	var landed := lucian.global_position
	await wait_seconds(0.3)
	assert_almost_eq(lucian.global_position, landed, Vector2(0.5, 0.5), "stands where Flash landed")


func test_a_right_click_after_flash_walks_on() -> void:
	assert_true(lucian.use_summoner(0, Vector2(300, 0)))
	right_click()
	Input.action_release(&"move")
	var landed := lucian.global_position
	await wait_seconds(0.3)
	assert_gt(lucian.global_position.distance_to(landed), 20.0, "walking to the new click")


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	controller._unhandled_input(event)


func test_keys_7_and_8_drink_from_the_potion_cells() -> void:
	var catalog := lucian.item_catalog
	lucian.inventory.add(catalog.find(&"hp_potion"), 2)
	lucian.inventory.add(catalog.find(&"mp_potion"), 1)
	_press(&"potion_hp")
	assert_eq(lucian.inventory.count_at(Inventory.HP_POTION_CELL), 1)
	_press(&"potion_mp")
	assert_null(lucian.inventory.item_at(Inventory.MP_POTION_CELL))
	assert_eq(lucian.restores.count(&"mp_potion"), 1)


func test_an_empty_potion_cell_key_does_nothing() -> void:
	lucian.inventory.add(lucian.item_catalog.find(&"hp_potion"), 3)
	_press(&"potion_mp")
	assert_eq(lucian.restores.count(&"hp_potion"), 0)
	assert_eq(lucian.inventory.count_at(Inventory.HP_POTION_CELL), 3, "7's cell is left alone")
	assert_false(GameSettings.CASTABLE.has(&"potion_hp"), "no cast mode")
	assert_true(GameSettings.REBINDABLE.has(&"potion_mp"))
