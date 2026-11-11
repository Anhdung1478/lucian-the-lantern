extends GutTest

const Fixtures := preload("res://tests/unit/item_fixtures.gd")
const Result := Shop.Result
const EQUIP := Inventory.EQUIP_START

var catalog: ItemCatalog
var inventory: Inventory
var wallet: Wallet
var stock: MerchantStock
var shop: Shop


func before_each() -> void:
	catalog = Fixtures.catalog()
	for item in catalog.items:
		item.cost = 1000 if not item.is_potion() else 50
	inventory = Inventory.new(catalog)
	wallet = Wallet.new()
	stock = MerchantStock.new(catalog, 7)
	shop = Shop.new(stock, inventory, wallet)


func test_buying_a_slot_pays_and_fills_the_first_empty_cell() -> void:
	wallet.add(1500)
	var item := stock.item_at(0)
	assert_eq(shop.buy_slot(0), Result.OK)
	assert_eq(wallet.gold, 500)
	assert_eq(inventory.item_at(0), item)
	assert_true(stock.is_sold(0))


func test_not_enough_gold_is_refused() -> void:
	wallet.add(999)
	assert_eq(shop.buy_slot(0), Result.NO_GOLD)
	assert_eq(wallet.gold, 999)
	assert_null(inventory.item_at(0))
	assert_false(stock.is_sold(0))


func test_a_sold_or_locked_slot_cannot_be_bought() -> void:
	wallet.add(5000)
	shop.buy_slot(0)
	assert_eq(shop.buy_slot(0), Result.SOLD_OUT)
	assert_eq(shop.buy_slot(3), Result.SLOT_LOCKED, "a chained slot is locked, not sold")
	assert_false(stock.is_sold(3))
	assert_eq(wallet.gold, 4000)


func test_a_full_backpack_is_refused_without_paying_though_equip_slots_are_free() -> void:
	wallet.add(5000)
	for i in Inventory.BACKPACK_SIZE:
		inventory.add(catalog.find(&"sword"))
	assert_eq(shop.buy_slot(0), Result.NO_ROOM)
	assert_eq(wallet.gold, 5000)
	assert_false(stock.is_sold(0))
	for i in range(EQUIP, Inventory.EQUIP_END):
		assert_null(inventory.item_at(i))


func test_a_full_backpack_still_buys_onto_a_chosen_free_equip_slot() -> void:
	wallet.add(5000)
	for i in Inventory.BACKPACK_SIZE:
		inventory.add(catalog.find(&"sword"))
	assert_eq(shop.buy_slot(0, EQUIP + 2), Result.OK)
	assert_eq(inventory.item_at(EQUIP + 2), stock.items[0])
	assert_eq(wallet.gold, 4000)
	inventory.put(EQUIP + 3, catalog.find(&"belt"))
	assert_eq(shop.buy_slot(1, EQUIP + 3), Result.NO_ROOM, "a taken slot: the backpack, which is full")
	assert_eq(wallet.gold, 4000)


func test_a_purchase_dropped_on_a_taken_equip_slot_goes_to_the_backpack() -> void:
	wallet.add(5000)
	inventory.put(EQUIP, catalog.find(&"belt"))
	assert_eq(shop.buy_slot(0, EQUIP), Result.OK)
	assert_eq(inventory.item_at(EQUIP), catalog.find(&"belt"))
	assert_eq(inventory.item_at(0), stock.items[0])
	assert_null(inventory.item_at(EQUIP + 1), "never another equip slot")


func test_potions_keep_their_own_cell_with_the_backpack_full() -> void:
	wallet.add(5000)
	for i in Inventory.BACKPACK_SIZE:
		inventory.add(catalog.find(&"sword"))
	var red := catalog.find(&"red")
	for i in 9:
		assert_eq(shop.buy_potion(red), Result.OK)
	assert_eq(inventory.count_at(Inventory.HP_POTION_CELL), 9)
	assert_eq(shop.buy_potion(red), Result.NO_ROOM)
	assert_eq(wallet.gold, 5000 - 9 * 50)


func test_buying_into_a_chosen_cell() -> void:
	wallet.add(5000)
	inventory.add(catalog.find(&"belt"))
	assert_eq(shop.buy_slot(0, 0), Result.OK, "occupied: bought into a free cell instead")
	assert_eq(inventory.item_at(1), stock.items[0])
	assert_eq(shop.buy_slot(1, EQUIP), Result.OK)
	assert_eq(inventory.item_at(EQUIP), stock.items[1])


func test_potions_stack_and_never_sell_out() -> void:
	wallet.add(1000)
	var red := catalog.find(&"red")
	for i in 10:
		assert_eq(shop.buy_potion(red), Result.OK)
	assert_eq(inventory.count_at(Inventory.HP_POTION_CELL), 9, "its potion cell first")
	assert_eq(inventory.count_at(0), 1, "then the backpack")
	assert_eq(wallet.gold, 500)


func test_potion_dragged_onto_its_stack() -> void:
	wallet.add(1000)
	var red := catalog.find(&"red")
	shop.buy_potion(red, 5)
	assert_eq(shop.buy_potion(red, 5), Result.OK)
	assert_eq(inventory.count_at(5), 2)


func test_undoing_two_sales_goes_last_first() -> void:
	inventory.add(catalog.find(&"sword"))
	inventory.add(catalog.find(&"rod"))
	shop.sell(0)
	shop.sell(1)
	assert_eq(wallet.gold, 1400)
	assert_eq(shop.last_sale().item.id, &"rod")
	assert_eq(shop.undo_sale(), Result.OK)
	assert_eq(inventory.item_at(1).id, &"rod")
	assert_null(inventory.item_at(0))
	assert_eq(wallet.gold, 700, "paid back what the sale gave")
	assert_eq(shop.undo_sale(), Result.OK)
	assert_eq(inventory.item_at(0).id, &"sword")
	assert_eq(wallet.gold, 0)
	assert_eq(shop.undo_sale(), Result.NOTHING_TO_UNDO)


func test_undo_restores_a_whole_stack_to_its_cell() -> void:
	var red := catalog.find(&"red")
	inventory.add(red, 3)
	var cell := Inventory.HP_POTION_CELL
	assert_eq(inventory.count_at(cell), 3)
	shop.sell(cell)
	wallet.add(1000)
	assert_eq(shop.undo_sale(), Result.OK)
	assert_eq(inventory.count_at(cell), 3)


func test_undo_goes_to_a_free_cell_when_the_old_one_is_taken() -> void:
	inventory.add(catalog.find(&"sword"))
	shop.sell(0)
	inventory.add(catalog.find(&"rod"))
	assert_eq(shop.undo_sale(), Result.OK)
	assert_eq(inventory.item_at(0).id, &"rod")
	assert_eq(inventory.item_at(1).id, &"sword")


func test_undo_without_gold_is_refused_and_kept() -> void:
	inventory.add(catalog.find(&"sword"))
	shop.sell(0)
	wallet.reset()
	assert_eq(shop.undo_sale(), Result.NO_GOLD)
	assert_null(inventory.item_at(0))
	wallet.add(700)
	assert_eq(shop.undo_sale(), Result.OK)
	assert_eq(wallet.gold, 0)


func test_undo_with_no_room_is_refused_and_kept() -> void:
	inventory.add(catalog.find(&"sword"))
	shop.sell(0)
	inventory.unlocked_backpack = 1
	inventory.add(catalog.find(&"rod"))
	assert_eq(shop.undo_sale(), Result.NO_ROOM, "the empty equip slots are no room")
	assert_eq(wallet.gold, 700)
	assert_null(inventory.item_at(EQUIP))
	inventory.remove(0)
	assert_eq(shop.undo_sale(), Result.OK)


func test_a_new_shop_has_nothing_to_undo() -> void:
	inventory.add(catalog.find(&"sword"))
	shop.sell(0)
	var next := Shop.new(stock, inventory, wallet)
	assert_true(next.last_sale().is_empty())
	assert_eq(next.undo_sale(), Result.NOTHING_TO_UNDO)


func test_selling_pays_the_sell_price() -> void:
	inventory.add(catalog.find(&"sword"))
	assert_eq(shop.sell_value(0), 700)
	assert_eq(shop.sell(0), 700)
	assert_eq(wallet.gold, 700)
	assert_null(inventory.item_at(0))


func test_selling_a_stack_pays_for_each() -> void:
	inventory.add(catalog.find(&"red"), 4)
	assert_eq(shop.sell(Inventory.HP_POTION_CELL), 4 * 35, "from a potion cell too")


func test_selling_an_empty_cell_does_nothing() -> void:
	assert_eq(shop.sell(3), 0)
	assert_eq(wallet.gold, 0)


func test_refresh_costs_gold() -> void:
	assert_eq(shop.refresh(), Result.NO_GOLD)
	wallet.add(MerchantStock.REFRESH_COST)
	assert_eq(shop.refresh(), Result.OK)
	assert_eq(wallet.gold, 0)


func test_a_refresh_with_every_open_slot_sold_is_refused_for_free() -> void:
	wallet.add(MerchantStock.REFRESH_COST)
	assert_true(shop.can_refresh())
	for i in stock.unlocked:
		stock.mark_sold(i)
	var before := stock.items.duplicate()
	assert_false(shop.can_refresh())
	assert_eq(shop.refresh(), Result.NOTHING_TO_REFRESH)
	assert_eq(wallet.gold, MerchantStock.REFRESH_COST, "no gold taken")
	assert_eq(stock.items, before, "nothing re-rolled")


func test_a_refresh_costs_what_the_shop_says() -> void:
	shop.refresh_cost = 50
	wallet.add(120)
	assert_eq(shop.refresh(), Result.OK)
	assert_eq(wallet.gold, 70)


func test_a_locked_cell_is_refused_without_paying() -> void:
	wallet.add(5000)
	inventory.unlocked_backpack = 5
	assert_eq(shop.buy_slot(0, 5), Result.CELL_LOCKED)
	assert_eq(wallet.gold, 5000)
	assert_null(inventory.item_at(5))


func test_no_room_counts_only_the_open_cells() -> void:
	wallet.add(5000)
	inventory.unlocked_backpack = 2
	inventory.add(catalog.find(&"sword"), 1)
	inventory.add(catalog.find(&"belt"), 1)
	assert_eq(shop.buy_slot(0), Result.NO_ROOM)
	assert_eq(wallet.gold, 5000)


# --- One penetration item --------------------------------------------------------


## A penetration legendary for 1000 gold.
func _pen(id: StringName, key := &"armor_pen") -> ItemData:
	var made := Fixtures.legendary(id, &"sword", &"belt", {key: 0.3})
	made.cost = 1000
	return made


func test_a_second_penetration_item_cannot_be_bought_onto_an_equip_slot() -> void:
	wallet.add(5000)
	var ldr := _pen(&"ldr")
	inventory.put(EQUIP, ldr)
	stock.items[0] = _pen(&"void", &"magic_pen")
	assert_eq(shop.buy_slot(0, EQUIP + 1), Result.PEN_LIMIT)
	assert_eq(wallet.gold, 5000)
	assert_false(stock.is_sold(0))
	assert_null(inventory.item_at(EQUIP + 1))
	assert_eq(shop.buy_slot(0, EQUIP), Result.OK, "onto the one equipped: taken, so into the backpack")
	assert_eq(inventory.item_at(0).id, &"void")
	assert_eq(inventory.item_at(EQUIP), ldr)


func test_undo_puts_an_equipped_item_back_in_its_slot_when_the_rule_allows() -> void:
	var void_staff := _pen(&"void", &"magic_pen")
	inventory.put(EQUIP + 1, void_staff)
	shop.sell(EQUIP + 1)
	assert_eq(shop.undo_sale(), Result.OK)
	assert_eq(inventory.item_at(EQUIP + 1), void_staff, "back in its equip slot")
	shop.sell(EQUIP + 1)
	inventory.put(EQUIP, _pen(&"ldr"))
	assert_eq(shop.undo_sale(), Result.OK)
	assert_null(inventory.item_at(EQUIP + 1), "another one is equipped now")
	assert_eq(inventory.item_at(0), void_staff, "so it comes back to the backpack")


# --- The Craft tab ---------------------------------------------------------------


func _real_shop() -> Shop:
	var real := load("res://data/items/catalog.tres") as ItemCatalog
	return Shop.new(MerchantStock.new(real, 1), Inventory.new(real), Wallet.new())


func test_crafting_two_fragments_pays_the_fee_and_puts_the_legendary_in_the_first_cell() -> void:
	var real_shop := _real_shop()
	var bag := real_shop.inventory
	var tear := bag.catalog.find(&"tear_of_the_goddess")
	bag.add(tear)
	bag.put(EQUIP, tear)
	real_shop.wallet.add(2500)
	assert_eq(real_shop.craft_result(EQUIP, 0), bag.catalog.find(&"muramana"))
	assert_eq(real_shop.craft_fee(EQUIP, 0), 1600, "2900 minus two 650-gold Tears")
	assert_eq(real_shop.craft(EQUIP, 0), Result.OK)
	assert_eq(real_shop.wallet.gold, 900)
	assert_eq(bag.item_at(EQUIP), bag.catalog.find(&"muramana"), "it stays equipped where the first input was")
	assert_null(bag.item_at(0), "the second fragment is used up")


func test_a_craft_without_the_fee_changes_nothing() -> void:
	var real_shop := _real_shop()
	var bag := real_shop.inventory
	bag.add(bag.catalog.find(&"bf_sword"))
	bag.add(bag.catalog.find(&"cloak_of_agility"))
	var fee := real_shop.craft_fee(0, 1)
	assert_gt(fee, 0)
	real_shop.wallet.add(fee - 1)
	assert_eq(real_shop.craft(0, 1), Result.NO_GOLD)
	assert_eq(real_shop.wallet.gold, fee - 1)
	assert_eq(bag.item_at(0), bag.catalog.find(&"bf_sword"))
	assert_eq(bag.item_at(1), bag.catalog.find(&"cloak_of_agility"))


func test_a_crafted_penetration_item_goes_to_the_second_cell_when_the_first_is_closed_to_it() -> void:
	var real_shop := _real_shop()
	var bag := real_shop.inventory
	var ldr := bag.catalog.find(&"lord_dominiks_regards")
	bag.put(EQUIP, ldr)
	bag.put(EQUIP + 1, bag.catalog.find(&"recurve_bow"))
	bag.put(0, bag.catalog.find(&"tear_of_the_goddess"))
	real_shop.wallet.add(5000)
	var fee := real_shop.craft_fee(EQUIP + 1, 0)
	assert_eq(real_shop.craft_cell(EQUIP + 1, 0), 0, "Void Staff can't join Lord Dominik's in the equip row")
	assert_eq(real_shop.craft(EQUIP + 1, 0), Result.OK)
	assert_eq(bag.item_at(0), bag.catalog.find(&"void_staff"))
	assert_null(bag.item_at(EQUIP + 1), "the first input's fragment is used up")
	assert_eq(bag.item_at(EQUIP), ldr)
	assert_eq(real_shop.wallet.gold, 5000 - fee)


func test_a_craft_with_both_cells_closed_to_its_penetration_item_is_refused() -> void:
	var real_shop := _real_shop()
	var bag := real_shop.inventory
	bag.put(EQUIP, bag.catalog.find(&"void_staff"))
	bag.put(EQUIP + 1, bag.catalog.find(&"bf_sword"))
	bag.put(EQUIP + 2, bag.catalog.find(&"chain_vest"))
	real_shop.wallet.add(5000)
	assert_eq(real_shop.craft_result(EQUIP + 1, EQUIP + 2), bag.catalog.find(&"mortal_reminder"))
	assert_eq(real_shop.craft_cell(EQUIP + 1, EQUIP + 2), -1)
	assert_eq(real_shop.craft(EQUIP + 1, EQUIP + 2), Result.PEN_LIMIT)
	assert_eq(real_shop.wallet.gold, 5000)
	assert_eq(bag.item_at(EQUIP + 1).id, &"bf_sword")
	assert_eq(bag.item_at(EQUIP + 2).id, &"chain_vest")


func test_a_craft_needs_two_different_open_cells_that_make_something() -> void:
	var real_shop := _real_shop()
	var bag := real_shop.inventory
	var tear := bag.catalog.find(&"tear_of_the_goddess")
	bag.add(tear)
	bag.add(tear)
	bag.add(bag.catalog.find(&"giants_belt"))
	bag.add(bag.catalog.find(&"giants_belt"))
	real_shop.wallet.add(9999)
	assert_eq(real_shop.craft(0, 0), Result.NO_RECIPE, "one tear is not two")
	assert_eq(real_shop.craft(0, 5), Result.NO_RECIPE, "an empty cell")
	assert_eq(real_shop.craft(0, -1), Result.NO_RECIPE)
	assert_eq(real_shop.craft(2, 3), Result.NO_RECIPE, "two Giant's Belts make nothing")
	bag.unlocked_backpack = 1
	assert_eq(real_shop.craft(0, 1), Result.NO_RECIPE, "a locked cell")
	assert_eq(real_shop.wallet.gold, 9999)
