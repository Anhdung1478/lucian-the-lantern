extends GutTest

const EQUIP := Inventory.EQUIP_START
const HP_CELL := Inventory.HP_POTION_CELL
const MP_CELL := Inventory.MP_POTION_CELL

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func potion(id: StringName) -> ItemData:
	return lucian.item_catalog.find(id)


func test_drinking_takes_one_from_the_stack() -> void:
	lucian.inventory.add(potion(&"hp_potion"), 3)
	assert_true(lucian.use_item(HP_CELL))
	assert_eq(lucian.inventory.count_at(HP_CELL), 2)
	for i in 3:
		lucian.inventory.put(4, potion(&"hp_potion"))
	assert_true(lucian.use_item(4), "the backpack's Use button drinks from any cell")
	assert_eq(lucian.inventory.count_at(4), 2)


func test_non_potions_and_empty_cells_cannot_be_drunk() -> void:
	lucian.inventory.add(potion(&"bf_sword"))
	assert_false(lucian.use_item(0))
	assert_false(lucian.use_item(1))
	assert_eq(lucian.inventory.item_at(0).id, &"bf_sword")


func test_health_potion_heals_over_time() -> void:
	lucian.inventory.add(potion(&"hp_potion"))
	lucian.hp = 100.0
	lucian.use_item(HP_CELL)
	# Item changes rebuild the stats, so regen is turned off after the drink.
	lucian.stats.hp_regen = 0.0
	await wait_seconds(1.0)
	assert_between(lucian.hp, 130.0, 150.0, "about 40 HP after 1 s")
	await wait_seconds(4.5)
	assert_almost_eq(lucian.hp, 300.0, 1.0)


func test_mana_potion_restores_mana() -> void:
	lucian.inventory.add(potion(&"mp_potion"))
	lucian.mana = 0.0
	lucian.use_item(MP_CELL)
	lucian.stats.mana_regen = 0.0
	await wait_seconds(5.5)
	assert_almost_eq(lucian.mana, 150.0, 1.0)


func test_heal_uses_heal_and_shield_power() -> void:
	lucian.hp = 100.0
	lucian.stats.heal_shield_power = 0.25
	lucian.heal(40.0)
	assert_almost_eq(lucian.hp, 150.0, 0.001)


func test_the_potion_cells_drink_on_7_and_8() -> void:
	lucian.inventory.add(potion(&"hp_potion"), 2)
	lucian.inventory.add(potion(&"mp_potion"))
	assert_true(lucian.use_potion_cell(HP_CELL))
	assert_eq(lucian.inventory.count_at(HP_CELL), 1)
	assert_true(lucian.use_potion_cell(MP_CELL))
	assert_null(lucian.inventory.item_at(MP_CELL))
	assert_false(lucian.use_potion_cell(MP_CELL), "an empty cell does nothing")


func test_an_empty_potion_cell_is_not_refilled() -> void:
	lucian.inventory.add(potion(&"hp_potion"), 10)
	assert_eq(lucian.inventory.count_at(0), 1, "the tenth goes to the backpack")
	for i in 9:
		assert_true(lucian.use_potion_cell(HP_CELL))
	assert_false(lucian.use_potion_cell(HP_CELL))
	assert_eq(lucian.inventory.count_at(0), 1, "no auto-refill from the backpack")


func test_potions_never_sit_in_equip_slots() -> void:
	assert_false(lucian.inventory.put(EQUIP + 2, potion(&"hp_potion")))
	assert_false(lucian.use_equip_slot(2, Vector2.ZERO), "an empty slot")
