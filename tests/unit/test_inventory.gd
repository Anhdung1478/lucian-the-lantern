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
	assert_eq(inventory.items.size(), 55)
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
	assert_false(Inventory.is_equip(48))
	assert_true(Inventory.is_equip(49))
	assert_true(Inventory.is_equip(54))
