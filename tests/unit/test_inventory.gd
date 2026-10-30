extends GutTest

const Fixtures := preload("res://tests/unit/item_fixtures.gd")
const Drop := Inventory.Drop
const EQUIP := Inventory.EQUIP_START

var catalog: ItemCatalog
var inventory: Inventory


func before_each() -> void:
	catalog = Fixtures.catalog()
	inventory = Inventory.new(catalog)


func item(id: StringName) -> ItemData:
	return catalog.find(id)


func test_starts_empty_with_all_equip_slots_unlocked() -> void:
	assert_eq(inventory.items.size(), 60)
	assert_eq(Inventory.BACKPACK_SIZE, 54)
	assert_eq(Inventory.EQUIP_START, 54)
	assert_eq(inventory.unlocked_backpack, 54)
	for i in Inventory.SIZE:
		assert_null(inventory.item_at(i))
	assert_eq(inventory.unlocked_equip, 6)


func test_add_fills_first_empty_backpack_cell() -> void:
	assert_true(inventory.add(item(&"sword")))
	assert_true(inventory.add(item(&"rod")))
	assert_eq(inventory.item_at(0), item(&"sword"))
	assert_eq(inventory.item_at(1), item(&"rod"))
	inventory.remove(0)
	inventory.add(item(&"belt"))
	assert_eq(inventory.item_at(0), item(&"belt"))


func test_add_never_fills_equip_slots() -> void:
	for i in Inventory.BACKPACK_SIZE:
		inventory.add(item(&"sword"))
	assert_false(inventory.add(item(&"rod")), "backpack is full")
	assert_null(inventory.item_at(EQUIP))


func test_drop_on_empty_cell_moves() -> void:
	inventory.add(item(&"sword"))
	assert_eq(inventory.drop_outcome(0, 10, false), Drop.MOVE)
	assert_eq(inventory.apply_drop(0, 10, false), Drop.MOVE)
	assert_null(inventory.item_at(0))
	assert_eq(inventory.item_at(10), item(&"sword"))


func test_drop_on_item_swaps() -> void:
	inventory.add(item(&"sword"))
	inventory.add(item(&"belt"))
	assert_eq(inventory.apply_drop(0, 1, false), Drop.SWAP)
	assert_eq(inventory.item_at(0), item(&"belt"))
	assert_eq(inventory.item_at(1), item(&"sword"))


func test_recipe_without_full_hold_swaps() -> void:
	inventory.add(item(&"sword"))
	inventory.add(item(&"rod"))
	assert_eq(inventory.drop_outcome(0, 1, false), Drop.SWAP)


func test_recipe_with_full_hold_crafts_into_target() -> void:
	inventory.add(item(&"sword"))
	inventory.add(item(&"rod"))
	assert_eq(inventory.apply_drop(0, 1, true), Drop.CRAFT)
	assert_null(inventory.item_at(0))
	assert_eq(inventory.item_at(1), item(&"gunblade"))


func test_full_hold_on_non_recipe_still_swaps() -> void:
	inventory.add(item(&"rod"))
	inventory.add(item(&"belt"))
	assert_eq(inventory.drop_outcome(0, 1, true), Drop.SWAP)


func test_craft_result() -> void:
	inventory.add(item(&"sword"))
	inventory.add(item(&"sword"))
	inventory.add(item(&"belt"))
	assert_eq(inventory.craft_result(0, 1), item(&"edge"))
	assert_null(inventory.craft_result(0, 2))
	assert_null(inventory.craft_result(0, 5), "empty target")


func test_an_item_cannot_craft_with_itself() -> void:
	inventory.add(item(&"sword"))
	assert_null(inventory.craft_result(0, 0), "sword + sword is a recipe, but it is one sword")


func test_drop_returns_for_same_cell_outside_or_empty_source() -> void:
	inventory.add(item(&"sword"))
	assert_eq(inventory.drop_outcome(0, 0, true), Drop.RETURN)
	assert_eq(inventory.drop_outcome(0, -1, true), Drop.RETURN)
	assert_eq(inventory.drop_outcome(0, Inventory.SIZE, true), Drop.RETURN)
	assert_eq(inventory.drop_outcome(3, 4, true), Drop.RETURN)


func test_drop_on_locked_equip_slot_returns() -> void:
	inventory.unlocked_equip = 2
	inventory.add(item(&"sword"))
	assert_true(inventory.is_locked(EQUIP + 2))
	assert_false(inventory.is_locked(EQUIP + 1))
	assert_eq(inventory.apply_drop(0, EQUIP + 2, false), Drop.RETURN)
	assert_eq(inventory.item_at(0), item(&"sword"))


func test_return_does_not_emit_changed() -> void:
	inventory.add(item(&"sword"))
	watch_signals(inventory)
	inventory.apply_drop(0, 0, false)
	assert_signal_not_emitted(inventory, "changed")


func test_changes_emit_changed() -> void:
	watch_signals(inventory)
	inventory.add(item(&"sword"))
	inventory.apply_drop(0, 5, false)
	inventory.remove(5)
	inventory.add(item(&"sword"))
	inventory.clear()
	assert_signal_emit_count(inventory, "changed", 5)


func test_equipped_bonus_counts_only_equip_slots() -> void:
	inventory.add(item(&"sword"))
	inventory.add(item(&"rod"))
	inventory.apply_drop(0, EQUIP, false)
	var bonus := inventory.equipped_bonus()
	assert_almost_eq(bonus.get(&"ad", 0.0), 35.0, 0.001)
	assert_false(bonus.has(&"ap"), "the rod is still in the backpack")


func test_equipped_duplicates_stack() -> void:
	inventory.add(item(&"sword"))
	inventory.add(item(&"sword"))
	inventory.apply_drop(0, EQUIP, false)
	inventory.apply_drop(1, EQUIP + 3, false)
	assert_almost_eq(inventory.equipped_bonus()[&"ad"], 70.0, 0.001)


func test_lowering_unlocked_slots_returns_items_to_backpack() -> void:
	inventory.add(item(&"sword"))
	inventory.add(item(&"rod"))
	inventory.apply_drop(0, EQUIP, false)
	inventory.apply_drop(1, EQUIP + 4, false)
	inventory.unlocked_equip = 2
	assert_eq(inventory.item_at(EQUIP), item(&"sword"))
	assert_null(inventory.item_at(EQUIP + 4))
	assert_eq(inventory.item_at(0), item(&"rod"))
	assert_false(inventory.equipped_bonus().has(&"ap"))


func test_unlocked_slots_stay_between_1_and_6() -> void:
	inventory.unlocked_equip = 0
	assert_eq(inventory.unlocked_equip, 1)
	inventory.unlocked_equip = 9
	assert_eq(inventory.unlocked_equip, 6)


func test_is_equip() -> void:
	assert_false(Inventory.is_equip(53))
	assert_true(Inventory.is_equip(54))
	assert_true(Inventory.is_equip(59))


func test_items_count_one_and_empty_cells_zero() -> void:
	inventory.add(item(&"sword"))
	assert_eq(inventory.count_at(0), 1)
	assert_eq(inventory.count_at(1), 0)


func test_potions_stack_into_the_first_cell_with_room() -> void:
	inventory.add(item(&"sword"))
	inventory.add(item(&"red"))
	inventory.add(item(&"red"), 3)
	assert_eq(inventory.item_at(1), item(&"red"))
	assert_eq(inventory.count_at(1), 4)
	assert_null(inventory.item_at(2))


func test_a_full_stack_spills_into_a_new_cell() -> void:
	inventory.add(item(&"red"), 8)
	inventory.add(item(&"red"), 3)
	assert_eq(inventory.count_at(0), 9)
	assert_eq(inventory.count_at(1), 2)


func test_space_for_counts_room_in_stacks_and_empty_cells() -> void:
	for i in Inventory.BACKPACK_SIZE - 1:
		inventory.add(item(&"sword"))
	inventory.add(item(&"red"), 5)
	assert_eq(inventory.space_for(item(&"red")), 4)
	assert_eq(inventory.space_for(item(&"blue")), 0)
	assert_eq(inventory.space_for(item(&"sword")), 0)


func test_add_is_all_or_nothing() -> void:
	for i in Inventory.BACKPACK_SIZE - 1:
		inventory.add(item(&"sword"))
	inventory.add(item(&"red"), 7)
	assert_false(inventory.add(item(&"red"), 3))
	assert_eq(inventory.count_at(Inventory.BACKPACK_SIZE - 1), 7)


func test_take_one_lowers_the_stack_and_empties_the_last() -> void:
	inventory.add(item(&"red"), 2)
	assert_eq(inventory.take_one(0), item(&"red"))
	assert_eq(inventory.count_at(0), 1)
	inventory.take_one(0)
	assert_null(inventory.item_at(0))
	assert_eq(inventory.count_at(0), 0)


func test_drop_on_same_potion_stacks() -> void:
	for i in 6:
		inventory.put(5, item(&"red"))
	for i in 5:
		inventory.put(0, item(&"red"))
	assert_eq(inventory.count_at(0), 5)
	assert_eq(inventory.drop_outcome(0, 5, false), Drop.STACK)
	assert_eq(inventory.apply_drop(0, 5, false), Drop.STACK)
	assert_eq(inventory.count_at(5), 9)
	assert_eq(inventory.count_at(0), 2, "the rest stays in the original cell")


func test_drop_on_a_full_stack_swaps() -> void:
	inventory.add(item(&"red"), 9)
	inventory.add(item(&"red"), 2)
	assert_eq(inventory.drop_outcome(1, 0, false), Drop.SWAP)


func test_drop_on_other_potion_swaps_counts_too() -> void:
	inventory.add(item(&"red"), 3)
	inventory.add(item(&"blue"), 7)
	inventory.apply_drop(0, 1, false)
	assert_eq(inventory.item_at(0), item(&"blue"))
	assert_eq(inventory.count_at(0), 7)
	assert_eq(inventory.count_at(1), 3)


func test_moving_a_stack_keeps_its_count() -> void:
	inventory.add(item(&"red"), 4)
	inventory.apply_drop(0, EQUIP, false)
	assert_eq(inventory.count_at(EQUIP), 4)
	assert_eq(inventory.count_at(0), 0)


func test_put_into_a_chosen_cell() -> void:
	inventory.add(item(&"sword"))
	assert_false(inventory.put(0, item(&"rod")), "occupied by another item")
	assert_true(inventory.put(3, item(&"rod")))
	assert_eq(inventory.item_at(3), item(&"rod"))
	assert_true(inventory.put(EQUIP, item(&"red")))
	assert_true(inventory.put(EQUIP, item(&"red")))
	assert_eq(inventory.count_at(EQUIP), 2)
	inventory.unlocked_equip = 1
	assert_false(inventory.put(EQUIP + 1, item(&"red")), "locked slot")


func test_clear_resets_counts() -> void:
	inventory.add(item(&"red"), 4)
	inventory.clear()
	assert_eq(inventory.count_at(0), 0)


func test_locking_a_slot_moves_its_stack() -> void:
	inventory.add(item(&"red"), 4)
	inventory.apply_drop(0, EQUIP + 5, false)
	inventory.unlocked_equip = 5
	assert_eq(inventory.item_at(0), item(&"red"))
	assert_eq(inventory.count_at(0), 4)


func test_sell_price_uses_the_ratio() -> void:
	var sword := item(&"sword")
	sword.cost = 1300
	assert_eq(sword.sell_price(), 910)
	sword.sell_ratio = 0.4
	assert_eq(sword.sell_price(), 520)


func test_everything_is_open_by_default() -> void:
	for i in Inventory.SIZE:
		assert_false(inventory.is_locked(i), str(i))


func test_the_lock_edges_with_5_open() -> void:
	inventory.unlocked_backpack = 5
	assert_false(inventory.is_locked(4))
	assert_true(inventory.is_locked(5))
	assert_true(inventory.is_locked(Inventory.BACKPACK_SIZE - 1))
	assert_false(inventory.is_locked(EQUIP), "equip slots follow their own count")


func test_unlocked_backpack_stays_between_1_and_54() -> void:
	inventory.unlocked_backpack = 0
	assert_eq(inventory.unlocked_backpack, 1)
	inventory.unlocked_backpack = 99
	assert_eq(inventory.unlocked_backpack, 54)


func test_add_and_space_for_use_only_open_cells() -> void:
	inventory.unlocked_backpack = 5
	assert_eq(inventory.space_for(item(&"sword")), 5)
	for i in 5:
		assert_true(inventory.add(item(&"sword")))
	assert_false(inventory.add(item(&"sword")))
	assert_eq(inventory.space_for(item(&"sword")), 0)
	assert_null(inventory.item_at(5))
	inventory.remove(2)
	inventory.add(item(&"red"), 3)
	assert_eq(inventory.space_for(item(&"red")), 6, "the open stack's room")


func test_put_is_refused_on_a_locked_cell() -> void:
	inventory.unlocked_backpack = 5
	assert_true(inventory.put(4, item(&"sword")))
	assert_false(inventory.put(5, item(&"sword")))
	assert_null(inventory.item_at(5))


func test_a_drop_to_or_from_a_locked_cell_returns() -> void:
	inventory.add(item(&"sword"))
	inventory.unlocked_backpack = 5
	assert_eq(inventory.apply_drop(0, 5, false), Drop.RETURN)
	assert_eq(inventory.item_at(0), item(&"sword"))


func test_lowering_the_backpack_moves_items_to_open_cells() -> void:
	inventory.put(10, item(&"sword"))
	inventory.put(11, item(&"red"))
	inventory.put(11, item(&"red"))
	inventory.unlocked_backpack = 5
	assert_null(inventory.item_at(10))
	assert_null(inventory.item_at(11))
	assert_eq(inventory.item_at(0), item(&"sword"))
	assert_eq(inventory.item_at(1), item(&"red"))
	assert_eq(inventory.count_at(1), 2)


func test_lowering_the_backpack_with_no_room_leaves_items_in_place() -> void:
	for i in 6:
		inventory.put(i, item(&"sword"))
	inventory.unlocked_backpack = 5
	assert_eq(inventory.item_at(5), item(&"sword"))
	assert_true(inventory.is_locked(5))


func test_lowering_the_equip_slots_skips_locked_backpack_cells() -> void:
	inventory.put(EQUIP + 5, item(&"sword"))
	inventory.unlocked_backpack = 5
	inventory.put(0, item(&"rod"))
	inventory.unlocked_equip = 5
	assert_eq(inventory.item_at(1), item(&"sword"), "the first empty open cell")
	assert_null(inventory.item_at(EQUIP + 5))
