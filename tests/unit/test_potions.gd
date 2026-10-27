extends GutTest

const EQUIP := Inventory.EQUIP_START

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func potion(id: StringName) -> ItemData:
	return lucian.item_catalog.find(id)


func test_drinking_takes_one_from_the_stack() -> void:
	lucian.inventory.add(potion(&"hp_potion"), 3)
	assert_true(lucian.use_item(0))
	assert_eq(lucian.inventory.count_at(0), 2)


func test_non_potions_and_empty_cells_cannot_be_drunk() -> void:
	lucian.inventory.add(potion(&"bf_sword"))
	assert_false(lucian.use_item(0))
	assert_false(lucian.use_item(1))
	assert_eq(lucian.inventory.item_at(0).id, &"bf_sword")


func test_health_potion_heals_over_time() -> void:
	lucian.inventory.add(potion(&"hp_potion"))
	lucian.hp = 100.0
	lucian.use_item(0)
	# Item changes rebuild the stats, so regen is turned off after the drink.
	lucian.stats.hp_regen = 0.0
	await wait_seconds(1.0)
	assert_between(lucian.hp, 130.0, 150.0, "about 40 HP after 1 s")
	await wait_seconds(4.5)
	assert_almost_eq(lucian.hp, 300.0, 1.0)


func test_mana_potion_restores_mana() -> void:
	lucian.inventory.add(potion(&"mp_potion"))
	lucian.mana = 0.0
	lucian.use_item(0)
	lucian.stats.mana_regen = 0.0
	await wait_seconds(5.5)
	assert_almost_eq(lucian.mana, 150.0, 1.0)


func test_heal_uses_heal_and_shield_power() -> void:
	lucian.hp = 100.0
	lucian.stats.heal_shield_power = 0.25
	lucian.heal(40.0)
	assert_almost_eq(lucian.hp, 150.0, 0.001)


func test_equip_slot_key_drinks_the_potion_there() -> void:
	lucian.inventory.put(EQUIP + 2, potion(&"hp_potion"))
	lucian.inventory.put(EQUIP + 2, potion(&"hp_potion"))
	assert_true(lucian.use_equip_slot(2, Vector2.ZERO))
	assert_eq(lucian.inventory.count_at(EQUIP + 2), 1)
	assert_false(lucian.use_equip_slot(3, Vector2.ZERO), "empty slot")


func test_locked_equip_slot_does_nothing() -> void:
	lucian.inventory.put(EQUIP + 5, potion(&"hp_potion"))
	lucian.inventory.unlocked_equip = 5
	assert_false(lucian.use_equip_slot(5, Vector2.ZERO))
