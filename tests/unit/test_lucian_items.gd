extends GutTest

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func test_make_damage_carries_penetration() -> void:
	lucian.stats.armor_pen = 0.3
	lucian.stats.magic_pen = 0.4
	var info := lucian.make_damage(100.0, DamageInfo.Type.PHYSICAL, &"q")
	assert_eq(info.attacker, lucian)
	assert_almost_eq(info.armor_pen, 0.3, 0.0001)
	assert_almost_eq(info.magic_pen, 0.4, 0.0001)


func test_penetration_raises_damage_on_the_dummy() -> void:
	var dummy: TrainingDummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	add_child_autofree(dummy)
	var plain := dummy.take_damage(lucian.make_damage(100.0, DamageInfo.Type.PHYSICAL, &"q"))
	lucian.stats.armor_pen = 0.5
	var pierced := dummy.take_damage(lucian.make_damage(100.0, DamageInfo.Type.PHYSICAL, &"q"))
	assert_gt(pierced, plain)


func give_equipped(id: StringName, slot := 0) -> void:
	var inventory := lucian.inventory
	inventory.add(lucian.item_catalog.find(id))
	var from := -1
	for i in Inventory.BACKPACK_SIZE:
		if inventory.item_at(i) and inventory.item_at(i).id == id:
			from = i
	inventory.apply_drop(from, Inventory.EQUIP_START + slot, false)


func test_inventory_uses_the_item_catalog() -> void:
	assert_not_null(lucian.inventory.catalog)
	assert_not_null(lucian.item_catalog.find(&"bf_sword"))


func test_equipped_item_adds_its_stats() -> void:
	var base_ad := lucian.stats.ad
	give_equipped(&"bf_sword")
	assert_almost_eq(lucian.stats.ad, base_ad + 35.0, 0.001)


func test_backpack_items_give_no_stats() -> void:
	var base_ad := lucian.stats.ad
	lucian.inventory.add(lucian.item_catalog.find(&"bf_sword"))
	assert_almost_eq(lucian.stats.ad, base_ad, 0.001)


func test_item_bonus_survives_level_up() -> void:
	give_equipped(&"bf_sword")
	lucian.progress.set_level(5)
	assert_almost_eq(lucian.stats.ad, lucian.base_stats.at_level(5).ad + 35.0, 0.001)


func test_equipping_health_keeps_the_health_share() -> void:
	lucian.hp = lucian.stats.max_hp * 0.5
	give_equipped(&"giants_belt")
	assert_almost_eq(lucian.hp, lucian.stats.max_hp * 0.5, 0.01)


func test_swapping_mana_items_gives_no_free_mana() -> void:
	give_equipped(&"tear_of_the_goddess")
	lucian.mana = 0.0
	lucian.inventory.apply_drop(Inventory.EQUIP_START, 10, false)
	lucian.inventory.apply_drop(10, Inventory.EQUIP_START, false)
	assert_almost_eq(lucian.mana, 0.0, 0.001)


func test_level_up_still_grants_the_gained_max_hp() -> void:
	give_equipped(&"giants_belt")
	lucian.hp = 300.0
	var old_max := lucian.stats.max_hp
	lucian.progress.set_level(2)
	assert_almost_eq(lucian.hp, 300.0 + lucian.stats.max_hp - old_max, 0.001)


func test_lifesteal_heals_on_basic_attacks_only() -> void:
	var dummy: TrainingDummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	add_child_autofree(dummy)
	lucian.stats.lifesteal = 0.2
	lucian.hp = 100.0
	lucian.on_damage_dealt(dummy, lucian.make_damage(100.0, DamageInfo.Type.PHYSICAL, &"basic"), 100.0)
	assert_almost_eq(lucian.hp, 120.0, 0.001)
	lucian.on_damage_dealt(dummy, lucian.make_damage(100.0, DamageInfo.Type.PHYSICAL, &"lightslinger"), 50.0)
	assert_almost_eq(lucian.hp, 130.0, 0.001)
	lucian.on_damage_dealt(dummy, lucian.make_damage(100.0, DamageInfo.Type.PHYSICAL, &"q"), 100.0)
	assert_almost_eq(lucian.hp, 130.0, 0.001)


func test_omnivamp_heals_on_every_hit() -> void:
	var dummy: TrainingDummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	add_child_autofree(dummy)
	lucian.stats.omnivamp = 0.1
	lucian.hp = 100.0
	lucian.on_damage_dealt(dummy, lucian.make_damage(100.0, DamageInfo.Type.MAGIC, &"w"), 100.0)
	assert_almost_eq(lucian.hp, 110.0, 0.001)


func test_healing_stops_at_max_hp() -> void:
	var dummy: TrainingDummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	add_child_autofree(dummy)
	lucian.stats.omnivamp = 1.0
	lucian.hp = lucian.stats.max_hp - 5.0
	lucian.on_damage_dealt(dummy, lucian.make_damage(100.0, DamageInfo.Type.MAGIC, &"w"), 100.0)
	assert_almost_eq(lucian.hp, lucian.stats.max_hp, 0.001)
