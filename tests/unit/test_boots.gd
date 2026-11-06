extends GutTest
## V1.4 boots: the boots cell, the merchant's upgrade, the Evolution Tree's
## Boots node reaching every map, and Slightly Quicker.

const CATALOG := "res://data/items/catalog.tres"
const Drop := Inventory.Drop
const Result := Shop.Result
const BOOTS := Inventory.BOOTS_CELL
const EQUIP := Inventory.EQUIP_START
const LINES := {
	&"recurve_bow": [&"berserkers_greaves", &"gunmetal_greaves"],
	&"cloak_of_agility": [&"boots_of_swiftness", &"swiftmarch"],
	&"bf_sword": [&"gluttonous_greaves", &"immortal_path"],
	&"tear_of_the_goddess": [&"ionian_boots_of_lucidity", &"crimson_lucidity"],
	&"negatron_cloak": [&"mercurys_treads", &"chainlaced_crushers"],
	&"chain_vest": [&"plated_steelcaps", &"armored_advance"],
	&"needlessly_large_rod": [&"sorcerers_shoes", &"spellslingers_shoes"],
}

var catalog: ItemCatalog
var inventory: Inventory
var wallet: Wallet
var shop: Shop


func before_each() -> void:
	catalog = load(CATALOG)
	inventory = Inventory.new(catalog)
	wallet = Wallet.new()
	shop = Shop.new(MerchantStock.new(catalog, 3), inventory, wallet)


func item(id: StringName) -> ItemData:
	return catalog.find(id)


# --- The boots cell ------------------------------------------------------------


func test_boots_never_leave_their_cell() -> void:
	inventory.set_boots(item(&"boots_of_speed"))
	inventory.add(item(&"bf_sword"))
	assert_eq(inventory.drop_outcome(BOOTS, 5, true), Drop.RETURN, "onto an empty backpack cell")
	assert_eq(inventory.drop_outcome(BOOTS, EQUIP, true), Drop.RETURN, "onto an equip slot")
	assert_eq(inventory.drop_outcome(BOOTS, 0, true), Drop.RETURN, "onto an item")
	assert_eq(inventory.drop_outcome(0, BOOTS, true), Drop.RETURN, "nothing is dropped onto them")
	assert_eq(inventory.apply_drop(0, BOOTS, true), Drop.RETURN)
	assert_eq(inventory.boots(), item(&"boots_of_speed"))
	assert_eq(inventory.item_at(0), item(&"bf_sword"))


func test_boots_fit_nowhere_else() -> void:
	var boots := item(&"berserkers_greaves")
	assert_eq(inventory.space_for(boots), 0)
	assert_false(inventory.add(boots))
	assert_false(inventory.can_put(0, boots))
	assert_false(inventory.can_put(EQUIP, boots))
	assert_false(inventory.can_put(BOOTS, boots), "only set_boots puts them there")
	for i in Inventory.SIZE:
		assert_null(inventory.item_at(i))


func test_the_boots_count_as_equipped_and_give_stats() -> void:
	inventory.set_boots(item(&"mercurys_treads"))
	inventory.put(EQUIP, item(&"bf_sword"))
	assert_eq(inventory.equipped(), [item(&"bf_sword"), item(&"mercurys_treads")] as Array[ItemData])
	var bonus := inventory.equipped_bonus()
	assert_almost_eq(bonus[&"move_speed"], 45.0, 0.001)
	assert_almost_eq(bonus[&"tenacity"], 0.3, 0.001)
	inventory.unlocked_equip = 1
	assert_true(inventory.equipped().has(item(&"mercurys_treads")), "never locked")


func test_clearing_the_items_keeps_the_boots() -> void:
	inventory.set_boots(item(&"boots_of_speed"))
	inventory.add(item(&"bf_sword"))
	inventory.clear()
	assert_null(inventory.item_at(0))
	assert_eq(inventory.boots(), item(&"boots_of_speed"))
	assert_eq(inventory.count_at(BOOTS), 1)


func test_the_potion_and_boots_cells_are_never_locked() -> void:
	inventory.unlocked_backpack = 1
	inventory.unlocked_equip = 1
	for cell in [Inventory.HP_POTION_CELL, Inventory.MP_POTION_CELL, BOOTS]:
		assert_false(inventory.is_locked(cell), str(cell))


func test_potions_are_refused_by_the_equip_slots_both_ways() -> void:
	var potion := item(&"hp_potion")
	inventory.add(potion, 9 + 2)
	assert_eq(inventory.item_at(0), potion)
	assert_false(inventory.can_put(EQUIP, potion))
	assert_eq(inventory.drop_outcome(0, EQUIP, false), Drop.RETURN, "a potion into an equip slot")
	inventory.put(EQUIP, item(&"bf_sword"))
	assert_eq(inventory.drop_outcome(EQUIP, 0, false), Drop.RETURN, "a swap would send the potion back into the slot")
	assert_eq(inventory.drop_outcome(0, EQUIP, false), Drop.RETURN)
	assert_eq(inventory.drop_outcome(0, 3, false), Drop.MOVE, "the backpack still takes it")


func test_each_potion_cell_takes_only_its_potion() -> void:
	var red := item(&"hp_potion")
	var blue := item(&"mp_potion")
	assert_true(Inventory.accepts(Inventory.HP_POTION_CELL, red))
	assert_false(Inventory.accepts(Inventory.HP_POTION_CELL, blue))
	assert_true(Inventory.accepts(Inventory.MP_POTION_CELL, blue))
	assert_false(Inventory.accepts(Inventory.MP_POTION_CELL, red))
	assert_false(Inventory.accepts(Inventory.HP_POTION_CELL, item(&"bf_sword")))
	inventory.put(0, blue)
	assert_eq(inventory.drop_outcome(0, Inventory.HP_POTION_CELL, false), Drop.RETURN)
	assert_eq(inventory.drop_outcome(0, Inventory.MP_POTION_CELL, false), Drop.MOVE)


func test_key_actions() -> void:
	assert_eq(Inventory.key_action(EQUIP), &"item_1")
	assert_eq(Inventory.key_action(EQUIP + 5), &"item_6")
	assert_eq(Inventory.key_action(Inventory.HP_POTION_CELL), &"potion_hp")
	assert_eq(Inventory.key_action(Inventory.MP_POTION_CELL), &"potion_mp")
	assert_eq(Inventory.key_action(BOOTS), &"", "boots have no key")
	assert_eq(Inventory.key_action(0), &"")


# --- Upgrades ------------------------------------------------------------------


func test_every_legal_upgrade() -> void:
	for fragment: StringName in LINES:
		var tier_2 := item(LINES[fragment][0])
		var tier_3 := item(LINES[fragment][1])
		for tier_1 in [&"boots_of_speed", &"slightly_magical_boots"]:
			assert_eq(catalog.boots_upgrade(item(tier_1), item(fragment)), tier_2, "%s + %s" % [tier_1, fragment])
		assert_eq(catalog.boots_upgrade(tier_2, item(fragment)), tier_3, "%s + %s" % [tier_2.id, fragment])
		assert_null(catalog.boots_upgrade(tier_3, item(fragment)), "%s is the top" % tier_3.id)


func test_wrong_upgrades_give_nothing() -> void:
	assert_null(catalog.boots_upgrade(item(&"berserkers_greaves"), item(&"bf_sword")), "another line's fragment")
	assert_null(catalog.boots_upgrade(item(&"boots_of_speed"), item(&"giants_belt")), "Giant's Belt has no line")
	assert_null(catalog.boots_upgrade(item(&"berserkers_greaves"), item(&"giants_belt")))
	assert_null(catalog.boots_upgrade(item(&"boots_of_speed"), item(&"infinity_edge")), "a legendary")
	assert_null(catalog.boots_upgrade(item(&"bf_sword"), item(&"recurve_bow")), "no boots")
	assert_null(catalog.boots_upgrade(null, item(&"recurve_bow")))
	assert_null(catalog.combine(item(&"boots_of_speed"), item(&"recurve_bow")), "crafting never makes boots")


func test_the_merchant_upgrades_for_the_fee_and_takes_the_fragment() -> void:
	inventory.set_boots(item(&"boots_of_speed"))
	inventory.add(item(&"recurve_bow"))
	wallet.add(1000)
	assert_eq(shop.upgrade_result(BOOTS, 0), item(&"berserkers_greaves"))
	assert_eq(shop.upgrade_boots(BOOTS, 0), Result.OK)
	assert_eq(wallet.gold, 700)
	assert_null(inventory.item_at(0), "the fragment is used up")
	assert_eq(inventory.boots(), item(&"berserkers_greaves"))
	inventory.add(item(&"recurve_bow"))
	assert_eq(shop.upgrade_boots(BOOTS, 0), Result.OK)
	assert_eq(wallet.gold, 200)
	assert_eq(inventory.boots(), item(&"gunmetal_greaves"))


func test_an_upgrade_without_gold_changes_nothing() -> void:
	inventory.set_boots(item(&"boots_of_speed"))
	inventory.add(item(&"cloak_of_agility"))
	wallet.add(699)
	assert_eq(shop.upgrade_boots(BOOTS, 0), Result.NO_GOLD)
	assert_eq(wallet.gold, 699)
	assert_eq(inventory.item_at(0), item(&"cloak_of_agility"))
	assert_eq(inventory.boots(), item(&"boots_of_speed"))


func test_an_upgrade_that_doesnt_fit_is_refused() -> void:
	wallet.add(5000)
	inventory.add(item(&"giants_belt"))
	assert_eq(shop.upgrade_boots(BOOTS, 0), Result.NO_BOOTS, "no boots bought")
	inventory.set_boots(item(&"gunmetal_greaves"))
	assert_eq(shop.upgrade_boots(BOOTS, 0), Result.NOT_UPGRADABLE)
	inventory.add(item(&"recurve_bow"))
	assert_eq(shop.upgrade_boots(BOOTS, 1), Result.NOT_UPGRADABLE, "tier 3 is the top")
	assert_eq(shop.upgrade_boots(BOOTS, -1), Result.NOT_UPGRADABLE, "no fragment")
	assert_eq(wallet.gold, 5000)
	assert_eq(inventory.boots(), item(&"gunmetal_greaves"))


func test_boots_cannot_be_sold() -> void:
	inventory.set_boots(item(&"berserkers_greaves"))
	assert_false(shop.can_sell(BOOTS))
	assert_eq(shop.sell_value(BOOTS), 0)
	assert_eq(shop.sell(BOOTS), 0)
	assert_eq(inventory.boots(), item(&"berserkers_greaves"))
	assert_eq(wallet.gold, 0)


func test_a_potion_bought_into_an_equip_slot_is_refused() -> void:
	wallet.add(500)
	assert_eq(shop.buy_potion(item(&"hp_potion"), EQUIP), Result.WRONG_CELL)
	assert_eq(shop.buy_potion(item(&"hp_potion"), Inventory.MP_POTION_CELL), Result.WRONG_CELL)
	assert_eq(wallet.gold, 500)
	assert_eq(shop.buy_potion(item(&"hp_potion"), Inventory.HP_POTION_CELL), Result.OK)
	assert_eq(shop.buy_potion(item(&"mp_potion")), Result.OK)
	assert_eq(inventory.count_at(Inventory.MP_POTION_CELL), 1, "bought potions fill their cell first")


func test_the_merchant_and_kills_never_give_boots() -> void:
	var stock := MerchantStock.new(catalog, 4)
	stock.unlocked = MerchantStock.SLOTS
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for attempt in 300:
		stock.refresh()
		for sold in stock.items:
			assert_true(sold == null or not sold.is_boots())
	for kind in [&"normal", &"elite", &"mini_boss", &"boss"]:
		for attempt in 500:
			for dropped in LootTable.roll(kind, catalog, rng):
				assert_false(dropped.is_boots(), str(kind))


# --- The Evolution Tree and every map --------------------------------------------


func _save(boots_levels: int) -> SaveGame:
	var save := SaveGame.new("user://test_boots_")
	save.essences.from_dict({"blue": 99999, "orange": 999, "purple": 0})
	for i in boots_levels:
		assert_true(save.tree.buy(&"boots", save.essences))
	return save


func test_no_boots_before_the_tree_node_is_bought() -> void:
	var save := _save(0)
	assert_eq(StageSetup.from_save(save).boots_level, 0)
	assert_eq(StageSetup.for_stage(save, 2, 1).boots_level, 0)


func test_the_boots_reach_every_map() -> void:
	for level in [1, 2]:
		var save := _save(level)
		var rng := RandomNumberGenerator.new()
		assert_eq(StageSetup.from_save(save).boots_level, level, "Training")
		assert_eq(StageSetup.for_stage(save, 3, 2).boots_level, level, "a story stage")
		assert_eq(StageSetup.for_endless(save, 0, rng).boots_level, level, "Endless")
		var tutorial := StageSetup.for_stage(save, 1, 1)
		assert_true(tutorial.tutorial)
		assert_eq(tutorial.boots_level, level, "the tutorial keeps them")
		save.cleared.append("1-1")
		assert_eq(StageSetup.for_stage(save, 1, 1).boots_level, level, "a replay of 1-1")


func test_the_sandbox_wears_slightly_magical_boots() -> void:
	assert_eq(StageSetup.new().boots_level, 2)


# --- Lucian --------------------------------------------------------------------


func _lucian(boots_level: int) -> Lucian:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	var setup := StageSetup.new()
	setup.boots_level = boots_level
	lucian.apply_setup(setup)
	return lucian


func test_lucian_starts_in_the_boots_bought() -> void:
	var base := _lucian(0)
	assert_null(base.inventory.boots())
	var speed := base.stats.move_speed
	var lucian := _lucian(1)
	assert_eq(lucian.inventory.boots().id, &"boots_of_speed")
	assert_almost_eq(lucian.stats.move_speed, speed + 25.0, 0.001)
	assert_false(lucian.has_slightly_quicker())
	lucian = _lucian(2)
	assert_eq(lucian.inventory.boots().id, &"slightly_magical_boots")
	assert_almost_eq(lucian.stats.move_speed, speed + 25.0 + Lucian.SLIGHTLY_QUICKER, 0.001)
	assert_almost_eq(lucian.stats.move_speed, 345.0 + 25.0 + 10.0, 0.001, "the plan's check: 345 + 25 + 10")


func test_slightly_quicker_survives_an_upgrade() -> void:
	var lucian := _lucian(2)
	var plain := _lucian(1)
	for boots in [&"berserkers_greaves", &"gunmetal_greaves"]:
		lucian.inventory.set_boots(item(boots))
		plain.inventory.set_boots(item(boots))
		assert_almost_eq(lucian.stats.move_speed - plain.stats.move_speed, Lucian.SLIGHTLY_QUICKER, 0.001, str(boots))
	assert_true(lucian.buffs().any(func(buff: Dictionary) -> bool: return buff.id == &"slightly_quicker"))
	assert_false(plain.buffs().any(func(buff: Dictionary) -> bool: return buff.id == &"slightly_quicker"))


func test_slightly_quicker_needs_boots_on() -> void:
	var lucian := _lucian(2)
	var speed := lucian.stats.move_speed
	lucian.inventory.set_boots(null)
	assert_almost_eq(lucian.stats.move_speed, speed - 35.0, 0.001)
	assert_false(lucian.has_slightly_quicker())
